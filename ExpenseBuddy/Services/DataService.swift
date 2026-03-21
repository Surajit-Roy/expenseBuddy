//
//  DataService.swift
//  ExpenseBuddy
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

@MainActor
class DataService: ObservableObject {
    @Published var friends: [User] = []
    @Published var groups: [ExpenseGroup] = []
    @Published var expenses: [Expense] = []
    @Published var settlements: [Settlement] = []
    @Published var activities: [ActivityItem] = []
    @Published var currentUser: User = User(id: "", name: "", email: "", profileImage: "", createdAt: Date())
    
    let userCache = UserCache()
    
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    private var cancellables = Set<AnyCancellable>()
    private let rebuildSubject = PassthroughSubject<Void, Never>()
    
    /// Tracks expense IDs already seen so we only notify on truly new ones.
    private var knownExpenseIds = Set<String>()
    /// Set to true after the initial snapshot load completes (to suppress notifications on app launch).
    private var initialExpenseLoadComplete = false
    
    /// Notification service for triggering local/in-app notifications.
    var notificationService: NotificationService?
    
    init() {
        // Re-render activity feed whenever UserCache updates (names arrive)
        userCache.$cache
            .dropFirst()
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                self?.rebuildSubject.send()
            }
            .store(in: &cancellables)
            
        // Debounced activity feed rebuild
        rebuildSubject
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] in
                self?.rebuildActivityFeedNow()
            }
            .store(in: &cancellables)
        
        Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            guard let self = self else { return }
            if let user = user {
                // Remove old listeners
                self.stopListeners()
                
                // Set current user identity
                self.currentUser.id = user.uid
                self.currentUser.email = user.email ?? ""
                
                // Seed cache with current user
                self.userCache.seed(self.currentUser)
                
                // Start tracking data
                self.setupListeners(userId: user.uid)
            } else {
                self.stopListeners()
                self.clearLocalStore()
            }
        }
    }
    
    deinit {
        let currentListeners = listeners
        Task {
            currentListeners.forEach { $0.remove() }
        }
    }
    
    private func stopListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    private func clearLocalStore() {
        friends = []
        groups = []
        expenses = []
        settlements = []
        activities = []
        knownExpenseIds.removeAll()
        initialExpenseLoadComplete = false
    }
    
    // MARK: - Firestore Sync (Listeners)
    
    private func setupListeners(userId: String) {
        // 1. Listen to Groups where user is a member (uses flat memberIds array)
        let groupsListener = db.collection("groups")
            .whereField("memberIds", arrayContains: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else {
                    if let error = error { print("Groups listener error: \(error)") }
                    return
                }
                
                Task {
                    let decodedGroups = await Task.detached(priority: .userInitiated) {
                        documents.compactMap { try? $0.data(as: ExpenseGroup.self) }
                    }.value
                    
                    await MainActor.run {
                        self.groups = decodedGroups
                        self.resolveUserIds()
                        self.rebuildActivityFeed()
                    }
                }
            }
            
        // 2. Listen to Expenses where user is a participant (uses flat participantIds array)
        //    Enhanced with change detection for real-time notifications.
        let expensesListener = db.collection("expenses")
            .whereField("participantIds", arrayContains: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let snapshot = snapshot else {
                    if let error = error { print("Expenses listener error: \(error)") }
                    return
                }
                
                Task {
                    // Decode all documents
                    let decodedExpenses = await Task.detached(priority: .userInitiated) {
                        snapshot.documents.compactMap { try? $0.data(as: Expense.self) }
                    }.value
                    
                    // Detect newly added expenses for notifications
                    let newlyAdded: [Expense] = snapshot.documentChanges
                        .filter { $0.type == .added }
                        .compactMap { try? $0.document.data(as: Expense.self) }
                    
                    await MainActor.run {
                        self.expenses = decodedExpenses
                        self.resolveUserIds()
                        self.rebuildActivityFeed()
                        
                        // Notify only for genuinely new expenses (not the initial load)
                        if self.initialExpenseLoadComplete {
                            for expense in newlyAdded {
                                // Skip if already known (dedup) or created by self
                                guard !self.knownExpenseIds.contains(expense.id),
                                      expense.createdByUserId != userId else { continue }
                                
                                let payerName = self.userCache.name(for: expense.paidByUserId)
                                self.notificationService?.scheduleExpenseNotification(
                                    expense: expense,
                                    payerName: payerName
                                )
                            }
                        }
                        
                        // Update known set and mark initial load complete
                        self.knownExpenseIds = Set(decodedExpenses.map { $0.id })
                        self.initialExpenseLoadComplete = true
                    }
                }
            }
            
        // 3. Listen to Settlements where user is a participant (uses flat participantIds array)
        let settlementsListener = db.collection("settlements")
            .whereField("participantIds", arrayContains: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else {
                    if let error = error { print("Settlements listener error: \(error)") }
                    return
                }
                
                Task {
                    let decodedSettlements = await Task.detached(priority: .userInitiated) {
                        documents.compactMap { try? $0.data(as: Settlement.self) }
                    }.value
                    
                    await MainActor.run {
                        self.settlements = decodedSettlements
                        self.resolveUserIds()
                        self.rebuildActivityFeed()
                    }
                }
            }
            
        // 4. Friends list — private subcollection for the current user
        let friendsListener = db.collection("users").document(userId).collection("friends")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else {
                    if let error = error { print("Friends listener error: \(error)") }
                    return
                }
                
                Task {
                    let decodedFriends = await Task.detached(priority: .userInitiated) {
                        documents.compactMap { try? $0.data(as: User.self) }
                    }.value
                    
                    await MainActor.run {
                        self.friends = decodedFriends
                        // Seed cache with all friends
                        self.userCache.seed(self.friends)
                        self.rebuildActivityFeed()
                    }
                }
            }
            
        // 5. Listen to Current User document for real-time profile updates
        let currentUserListener = db.collection("users").document(userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let document = snapshot else {
                    if let error = error { print("Current user listener error: \(error)") }
                    return
                }
                
                Task {
                    let updatedUser = await Task.detached(priority: .userInitiated) {
                        try? document.data(as: User.self)
                    }.value
                    
                    if let updatedUser {
                        await MainActor.run {
                            self.currentUser = updatedUser
                            self.userCache.seed(updatedUser)
                            self.rebuildActivityFeed()
                        }
                    }
                }
            }
            
        // 6. Listen to Reminders for real-time foreground notifications
        let remindersListener = db.collection("users").document(userId).collection("reminders")
            .whereField("read", isEqualTo: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let snapshot = snapshot else { return }
                
                // Only trigger notifications for newly added reminders, and ignore initial snapshot dump
                if self.initialExpenseLoadComplete {
                    let newlyAdded = snapshot.documentChanges.filter { $0.type == .added }
                    for change in newlyAdded {
                        let data = change.document.data()
                        if let message = data["message"] as? String,
                           let fromUserId = data["fromUserId"] as? String,
                           fromUserId != userId {
                            
                            Task { @MainActor in
                                self.notificationService?.publishInAppNotification(
                                    title: "⏰ Reminder",
                                    body: message,
                                    expenseId: nil
                                )
                            }
                        }
                    }
                }
            }
            
        listeners.append(contentsOf: [groupsListener, expensesListener, settlementsListener, friendsListener, currentUserListener, remindersListener])
    }
    
    // MARK: - User ID Resolution
    
    /// Collects all user IDs referenced in groups, expenses, and settlements,
    /// and asks UserCache to fetch any that aren't already cached.
    private func resolveUserIds() {
        var allIds = Set<String>()
        
        for group in groups {
            allIds.formUnion(group.memberIds)
            allIds.insert(group.createdByUserId)
        }
        
        for expense in expenses {
            allIds.insert(expense.paidByUserId)
            allIds.formUnion(expense.participantIds)
            allIds.insert(expense.createdByUserId)
            for split in expense.splits {
                allIds.insert(split.userId)
            }
        }
        
        for settlement in settlements {
            allIds.insert(settlement.fromUserId)
            allIds.insert(settlement.toUserId)
        }
        
        userCache.fetchIfNeeded(ids: Array(allIds))
    }
    
    // MARK: - Activity Feed
    
    func rebuildActivityFeed() {
        rebuildSubject.send()
    }
    
    private func rebuildActivityFeedNow() {
        var items: [ActivityItem] = []
        
        for expense in expenses {
            let payerName = userCache.name(for: expense.paidByUserId)
            items.append(ActivityItem(
                id: "act_\(expense.id)", type: .expenseAdded, title: expense.title,
                subtitle: "\(payerName) paid \(CurrencyManager.shared.format(expense.amount))",
                amount: expense.amount, date: expense.createdAt,
                involvedUserIds: expense.participantIds,
                groupName: groupName(for: expense.groupId),
                relatedExpenseId: expense.id
            ))
        }
        
        for settlement in settlements {
            let fromName = userCache.name(for: settlement.fromUserId)
            let toName = userCache.name(for: settlement.toUserId)
            items.append(ActivityItem(
                id: "act_\(settlement.id)", type: .settlement, title: "Settlement",
                subtitle: "\(fromName) paid \(toName) \(CurrencyManager.shared.format(settlement.amount))",
                amount: settlement.amount, date: settlement.date,
                involvedUserIds: settlement.participantIds,
                groupName: groupName(for: settlement.groupId),
                relatedExpenseId: nil
            ))
        }
        
        for group in groups {
            let creatorName = userCache.name(for: group.createdByUserId)
            items.append(ActivityItem(
                id: "act_group_\(group.id)", type: .groupCreated, title: "Group Created",
                subtitle: "\(creatorName) created \"\(group.name)\"",
                amount: nil, date: group.createdAt,
                involvedUserIds: group.memberIds, groupName: group.name,
                relatedExpenseId: nil
            ))
        }
        
        activities = items.sorted { $0.date > $1.date }
    }
    
    private func groupName(for groupId: String?) -> String? {
        guard let groupId else { return nil }
        return groups.first { $0.id == groupId }?.name
    }
    
    // MARK: - Expense CRUD
    
    func addExpense(_ expense: Expense) {
        do {
            try db.collection("expenses").document(expense.id).setData(from: expense)
        } catch {
            print("Failed to add expense: \(error)")
        }
    }
    
    func deleteExpense(_ expenseId: String) {
        db.collection("expenses").document(expenseId).delete()
    }
    
    // MARK: - Settlement CRUD
    
    func addSettlement(_ settlement: Settlement) {
        do {
            try db.collection("settlements").document(settlement.id).setData(from: settlement)
        } catch {
            print("Failed to add settlement: \(error)")
        }
    }
    
    /// Records a settlement. If `groupId` is nil (global settlement), it automatically distributes the payment
    /// across shared groups where the `fromUser` owes the `toUser`.
    func recordSettlement(fromUserId: String, toUserId: String, amount: Double, groupId: String?, note: String?) {
        if let groupId = groupId {
            // Explicit group settlement
            let settlement = Settlement(
                id: UUID().uuidString,
                fromUserId: fromUserId,
                toUserId: toUserId,
                amount: amount,
                date: Date(),
                participantIds: [fromUserId, toUserId],
                groupId: groupId,
                note: note,
                createdByUserId: currentUser.id
            )
            addSettlement(settlement)
            return
        }
        
        // Global settlement (groupId == nil), distribute across shared groups
        var remainingAmount = amount
        let shared = sharedGroups(with: toUserId).filter { $0.memberIds.contains(fromUserId) }
        
        for group in shared {
            if remainingAmount <= 0.01 { break }
            
            let groupExpenses = expensesForGroup(group.id)
            let groupSettlements = settlementsForGroup(group.id)
            
            let balance = ExpenseCalculator.balanceBetween(
                currentUserId: fromUserId,
                friendId: toUserId,
                expenses: groupExpenses,
                settlements: groupSettlements
            )
            
            // If balance < 0, fromUser owes toUser exactly `abs(balance)` in this group.
            if balance < -0.01 {
                let groupDebt = abs(balance)
                let settlementAmount = min(remainingAmount, groupDebt)
                
                let settlement = Settlement(
                    id: UUID().uuidString,
                    fromUserId: fromUserId,
                    toUserId: toUserId,
                    amount: settlementAmount,
                    date: Date(),
                    participantIds: [fromUserId, toUserId],
                    groupId: group.id,
                    note: note,
                    createdByUserId: currentUser.id
                )
                addSettlement(settlement)
                remainingAmount -= settlementAmount
            }
        }
        
        // If there's any amount left over, apply it globally
        if remainingAmount > 0.01 {
            let leftover = Settlement(
                id: UUID().uuidString,
                fromUserId: fromUserId,
                toUserId: toUserId,
                amount: remainingAmount,
                date: Date(),
                participantIds: [fromUserId, toUserId],
                groupId: nil,
                note: note,
                createdByUserId: currentUser.id
            )
            addSettlement(leftover)
        }
    }
    
    // MARK: - Group CRUD
    
    func addGroup(_ group: ExpenseGroup) {
        do {
            try db.collection("groups").document(group.id).setData(from: group)
        } catch {
            print("Failed to add group: \(error)")
        }
    }
    
    func deleteGroup(_ groupId: String) {
        db.collection("groups").document(groupId).delete()
        
        // Also delete related expenses and settlements
        for exp in expenses where exp.groupId == groupId {
            deleteExpense(exp.id)
        }
        for sett in settlements where sett.groupId == groupId {
            db.collection("settlements").document(sett.id).delete()
        }
    }
    
    func updateGroup(_ group: ExpenseGroup) {
        do {
            try db.collection("groups").document(group.id).setData(from: group)
        } catch {
            print("Failed to update group: \(error)")
        }
    }
    
    /// Validation: A group can only be deleted if all members are fully settled (no outstanding balances).
    func canDeleteGroup(_ group: ExpenseGroup) -> Bool {
        return simplifiedGroupDebts(group).isEmpty
    }
    
    // MARK: - Friend CRUD
    
    /// Searches for an existing user by their email address.
    func findUserByEmail(_ email: String) async -> User? {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        do {
            let snapshot = try await db.collection("users")
                .whereField("email", isEqualTo: trimmedEmail)
                .limit(to: 1)
                .getDocuments()
            
            if let doc = snapshot.documents.first {
                return try doc.data(as: User.self)
            }
        } catch {
            print("Error finding user by email: \(error)")
        }
        return nil
    }
    
    /// Adds a friend. If the user exists in ExpenseBuddy, it performs a bidirectional add.
    func addFriend(name: String, email: String) async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // 1. Try to find existing user
        let existingUser = await findUserByEmail(trimmedEmail)
        
        let friendId = existingUser?.id ?? UUID().uuidString
        let friend = User(
            id: friendId,
            name: existingUser?.name ?? trimmedName,
            email: trimmedEmail,
            profileImage: existingUser?.profileImage ?? "person.circle.fill",
            createdAt: existingUser?.createdAt ?? Date()
        )
        
        do {
            // 2. Add to current user's friends list
            try db.collection("users").document(currentUser.id)
                .collection("friends").document(friend.id)
                .setData(from: friend)
            
            // 3. If user exists, add current user to THEIR friends list (Bidirectional)
            if let _ = existingUser {
                // We need the current user's full profile to add to the friend's list
                // Fetch current user from main collection to be safe
                let meSnapshot = try await db.collection("users").document(currentUser.id).getDocument()
                if let me = try? meSnapshot.data(as: User.self) {
                    try await db.collection("users").document(friend.id)
                        .collection("friends").document(me.id)
                        .setData(from: me)
                }
            }
            
            // Seed cache immediately
            userCache.seed(friend)
        } catch {
            print("Failed to add friend: \(error)")
        }
    }
    
    func removeFriend(_ friend: User) {
        db.collection("users").document(currentUser.id).collection("friends").document(friend.id).delete()
    }
    
    /// Validation: A friend can only be removed if you have no outstanding balance with them.
    func canDeleteFriend(_ friendId: String) -> Bool {
        return abs(balanceWithFriend(friendId)) < 0.01
    }
    
    // MARK: - Update User Profile
    
    func updateUserProfileImage(base64String: String) async {
        let userId = currentUser.id
        
        do {
            // 1. Update Firestore
            try await db.collection("users").document(userId).updateData([
                "profileImage": base64String
            ])
            
            // 2. Local state will be updated by the listener, but we can update it immediately for snappiness
            // This also ensures currentUser is updated by re-assignment to trigger @Published
            var updatedUser = currentUser
            updatedUser.profileImage = base64String
            currentUser = updatedUser
            userCache.seed(currentUser)
            rebuildActivityFeed()
            
        } catch {
            print("Error updating profile image: \(error)")
        }
    }
    
    // MARK: - Queries
    
    func expensesForGroup(_ groupId: String) -> [Expense] {
        expenses.filter { $0.groupId == groupId }.sorted { $0.createdAt > $1.createdAt }
    }
    
    func settlementsForGroup(_ groupId: String) -> [Settlement] {
        settlements.filter { $0.groupId == groupId }
    }
    
    func expensesWithFriend(_ friendId: String) -> [Expense] {
        expenses.filter { expense in
            expense.participantIds.contains(friendId)
        }.sorted { $0.createdAt > $1.createdAt }
    }
    
    func settlementsWithFriend(_ friendId: String) -> [Settlement] {
        settlements.filter { $0.fromUserId == friendId || $0.toUserId == friendId }
    }
    
    func sharedGroups(with friendId: String) -> [ExpenseGroup] {
        groups.filter { group in
            group.memberIds.contains(friendId)
        }
    }
    
    func balanceWithFriend(_ friendId: String) -> Double {
        ExpenseCalculator.balanceBetween(
            currentUserId: currentUser.id,
            friendId: friendId,
            expenses: expenses,
            settlements: settlements
        )
    }
    
    func overallBalance() -> Double {
        var net: Double = 0
        let uid = currentUser.id
        
        for expense in expenses {
            let payerId = expense.paidByUserId
            for split in expense.splits {
                if payerId == uid && split.userId != uid {
                    net += split.amountOwed
                } else if payerId != uid && split.userId == uid {
                    net -= split.amountOwed
                }
            }
        }
        
        for settlement in settlements {
            if settlement.fromUserId == uid {
                net += settlement.amount
            } else if settlement.toUserId == uid {
                net -= settlement.amount
            }
        }
        
        return (net * 100).rounded() / 100.0
    }
    
    func groupBalance(_ group: ExpenseGroup) -> Double {
        let groupExpenses = expensesForGroup(group.id)
        let groupSettlements = settlementsForGroup(group.id)
        let userNames = buildUserNames(for: group.memberIds)
        let balances = ExpenseCalculator.calculateBalances(
            expenses: groupExpenses, settlements: groupSettlements,
            currentUserId: currentUser.id, userNames: userNames
        )
        return ExpenseCalculator.totalBalance(for: currentUser.id, balances: balances)
    }
    
    func groupBalanceEntries(_ group: ExpenseGroup) -> [BalanceEntry] {
        let groupExpenses = expensesForGroup(group.id)
        let groupSettlements = settlementsForGroup(group.id)
        let userNames = buildUserNames(for: group.memberIds)
        return ExpenseCalculator.calculateBalances(
            expenses: groupExpenses, settlements: groupSettlements,
            currentUserId: currentUser.id, userNames: userNames
        )
    }
    
    /// Simplified debts for a group — minimum number of transactions
    func simplifiedGroupDebts(_ group: ExpenseGroup) -> [SimplifiedDebt] {
        let balances = groupBalanceEntries(group)
        let userNames = buildUserNames(for: group.memberIds)
        return ExpenseCalculator.simplifyDebts(balances: balances, userNames: userNames)
    }
    
    /// Suggested settlement amount from current user to a friend
    func suggestedSettlement(friendId: String) -> Double {
        return ExpenseCalculator.suggestedSettlement(
            currentUserId: currentUser.id,
            friendId: friendId,
            expenses: expenses,
            settlements: settlements
        )
    }
    
    // MARK: - User Name Resolution Helper
    
    /// Builds a [userId: displayName] dictionary from the UserCache for a set of IDs.
    func buildUserNames(for ids: [String]) -> [String: String] {
        var names: [String: String] = [:]
        for id in ids {
            names[id] = userCache.name(for: id)
        }
        return names
    }
    
    // MARK: - Activity Grouping
    
    var groupedActivities: [(String, [ActivityItem])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: activities) { item -> String in
            if calendar.isDateInToday(item.date) { return "Today" }
            else if calendar.isDateInYesterday(item.date) { return "Yesterday" }
            else if let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()), item.date > weekAgo { return "This Week" }
            else if let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date()), item.date > monthAgo { return "This Month" }
            else { return "Earlier" }
        }
        let order = ["Today", "Yesterday", "This Week", "This Month", "Earlier"]
        return order.compactMap { key in
            guard let items = grouped[key] else { return nil }
            return (key, items.sorted { $0.date > $1.date })
        }
    }
}
