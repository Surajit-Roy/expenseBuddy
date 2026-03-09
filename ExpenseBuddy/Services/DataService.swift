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
    
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    
    init() {
        Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            guard let self = self else { return }
            if let user = user {
                // Remove old listeners
                self.stopListeners()
                
                // We'll set a temporary current user ID, but we expect AuthService to manage the main profile details
                self.currentUser.id = user.uid
                
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
    }
    
    // MARK: - Firestore Sync (Listeners)
    
    private func setupListeners(userId: String) {
        let userEmail = currentUser.email
        
        // 1. Listen to Groups where user is a member (uses flat memberEmails array)
        let groupsListener = db.collection("groups")
            .whereField("memberEmails", arrayContains: userEmail)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else {
                    if let error = error { print("Groups listener error: \(error)") }
                    return
                }
                self.groups = documents.compactMap { try? $0.data(as: ExpenseGroup.self) }
                self.rebuildActivityFeed()
            }
            
        // 2. Listen to Expenses where user is a participant (uses flat participantEmails array)
        let expensesListener = db.collection("expenses")
            .whereField("participantEmails", arrayContains: userEmail)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else {
                    if let error = error { print("Expenses listener error: \(error)") }
                    return
                }
                self.expenses = documents.compactMap { try? $0.data(as: Expense.self) }
                self.rebuildActivityFeed()
            }
            
        // 3. Listen to Settlements where user is a participant (uses flat participantEmails array)
        let settlementsListener = db.collection("settlements")
            .whereField("participantEmails", arrayContains: userEmail)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else {
                    if let error = error { print("Settlements listener error: \(error)") }
                    return
                }
                self.settlements = documents.compactMap { try? $0.data(as: Settlement.self) }
                self.rebuildActivityFeed()
            }
            
        // 4. Friends list — private subcollection for the current user
        let usersListener = db.collection("users").document(userId).collection("friends")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else {
                    if let error = error { print("Users listener error: \(error)") }
                    return
                }
                self.friends = documents.compactMap { try? $0.data(as: User.self) }
            }
            
        listeners.append(contentsOf: [groupsListener, expensesListener, settlementsListener, usersListener])
    }
    
    // MARK: - Activity Feed
    
    func rebuildActivityFeed() {
        var items: [ActivityItem] = []
        
        for expense in expenses {
            items.append(ActivityItem(
                id: "act_\(expense.id)", type: .expenseAdded, title: expense.title,
                subtitle: "\(expense.paidBy.name) paid \(CurrencyManager.shared.format(expense.amount))",
                amount: expense.amount, date: expense.createdAt,
                involvedUsers: expense.participants,
                groupName: groupName(for: expense.groupId),
                relatedExpenseId: expense.id
            ))
        }
        
        for settlement in settlements {
            items.append(ActivityItem(
                id: "act_\(settlement.id)", type: .settlement, title: "Settlement",
                subtitle: "\(settlement.fromUser.name) paid \(settlement.toUser.name) \(CurrencyManager.shared.format(settlement.amount))",
                amount: settlement.amount, date: settlement.date,
                involvedUsers: [settlement.fromUser, settlement.toUser],
                groupName: groupName(for: settlement.groupId),
                relatedExpenseId: nil
            ))
        }
        
        for group in groups {
            items.append(ActivityItem(
                id: "act_group_\(group.id)", type: .groupCreated, title: "Group Created",
                subtitle: "\(group.createdBy.name) created \"\(group.name)\"",
                amount: nil, date: group.createdAt,
                involvedUsers: group.members, groupName: group.name,
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
    func recordSettlement(from fromUser: User, to toUser: User, amount: Double, groupId: String?, note: String?) {
        if let groupId = groupId {
            // Explicit group settlement
            let settlement = Settlement(
                id: UUID().uuidString,
                fromUser: fromUser,
                toUser: toUser,
                amount: amount,
                date: Date(),
                participantEmails: [fromUser.email, toUser.email],
                groupId: groupId,
                note: note
            )
            addSettlement(settlement)
            return
        }
        
        // Global settlement (groupId == nil), distribute across shared groups
        var remainingAmount = amount
        let shared = sharedGroups(with: toUser.id).filter { $0.members.contains(where: { $0.id == fromUser.id }) }
        
        for group in shared {
            if remainingAmount <= 0.01 { break }
            
            let groupExpenses = expensesForGroup(group.id)
            let groupSettlements = settlementsForGroup(group.id)
            
            // balanceBetween returns positive if friend owes current user.
            // Here, we want to know if fromUser owes toUser.
            // If we check from fromUser's perspective, towards toUser:
            let balance = ExpenseCalculator.balanceBetween(
                currentUserId: fromUser.id,
                friendId: toUser.id,
                expenses: groupExpenses,
                settlements: groupSettlements
            )
            
            // If balance < 0, fromUser owes toUser exactly `abs(balance)` in this group.
            if balance < -0.01 {
                let groupDebt = abs(balance)
                let settlementAmount = min(remainingAmount, groupDebt)
                
                let settlement = Settlement(
                    id: UUID().uuidString,
                    fromUser: fromUser,
                    toUser: toUser,
                    amount: settlementAmount,
                    date: Date(),
                    participantEmails: [fromUser.email, toUser.email],
                    groupId: group.id,
                    note: note
                )
                addSettlement(settlement)
                remainingAmount -= settlementAmount
            }
        }
        
        // If there's any amount left over, apply it globally (non-group expense settlement, or overpayment)
        if remainingAmount > 0.01 {
            let leftover = Settlement(
                id: UUID().uuidString,
                fromUser: fromUser,
                toUser: toUser,
                amount: remainingAmount,
                date: Date(),
                participantEmails: [fromUser.email, toUser.email],
                groupId: nil,
                note: note
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
        for set in settlements where set.groupId == groupId {
            db.collection("settlements").document(set.id).delete()
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
    
    func addFriend(_ friend: User) {
        // Write friend to the private subcollection so only the current user sees them
        do {
            try db.collection("users").document(currentUser.id).collection("friends").document(friend.id).setData(from: friend)
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
    
    // MARK: - Queries
    
    func expensesForGroup(_ groupId: String) -> [Expense] {
        expenses.filter { $0.groupId == groupId }.sorted { $0.createdAt > $1.createdAt }
    }
    
    func settlementsForGroup(_ groupId: String) -> [Settlement] {
        settlements.filter { $0.groupId == groupId }
    }
    
    func expensesWithFriend(_ friendId: String) -> [Expense] {
        expenses.filter { expense in
            expense.participants.contains { $0.id == friendId }
        }.sorted { $0.createdAt > $1.createdAt }
    }
    
    func settlementsWithFriend(_ friendId: String) -> [Settlement] {
        settlements.filter { $0.fromUser.id == friendId || $0.toUser.id == friendId }
    }
    
    func sharedGroups(with friendId: String) -> [ExpenseGroup] {
        groups.filter { group in
            group.members.contains { $0.id == friendId }
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
        // Compute net balance across ALL users (not just friends list)
        var net: Double = 0
        let uid = currentUser.id
        
        for expense in expenses {
            let payerId = expense.paidBy.id
            for split in expense.splits {
                if payerId == uid && split.userId != uid {
                    // I paid, someone else owes their share → they owe me
                    net += split.amountOwed
                } else if payerId != uid && split.userId == uid {
                    // Someone else paid, I owe my share → I owe them
                    net -= split.amountOwed
                }
            }
        }
        
        for settlement in settlements {
            if settlement.fromUser.id == uid {
                // I paid someone → reduces what I owe (increases my net)
                net += settlement.amount
            } else if settlement.toUser.id == uid {
                // Someone paid me → reduces what they owe (decreases my net)
                net -= settlement.amount
            }
        }
        
        return (net * 100).rounded() / 100.0
    }
    
    func groupBalance(_ group: ExpenseGroup) -> Double {
        let groupExpenses = expensesForGroup(group.id)
        let groupSettlements = settlementsForGroup(group.id)
        let balances = ExpenseCalculator.calculateBalances(
            expenses: groupExpenses, settlements: groupSettlements,
            currentUserId: currentUser.id
        )
        return ExpenseCalculator.totalBalance(for: currentUser.id, balances: balances)
    }
    
    func groupBalanceEntries(_ group: ExpenseGroup) -> [BalanceEntry] {
        let groupExpenses = expensesForGroup(group.id)
        let groupSettlements = settlementsForGroup(group.id)
        return ExpenseCalculator.calculateBalances(
            expenses: groupExpenses, settlements: groupSettlements,
            currentUserId: currentUser.id
        )
    }
    
    /// Simplified debts for a group — minimum number of transactions
    func simplifiedGroupDebts(_ group: ExpenseGroup) -> [SimplifiedDebt] {
        let balances = groupBalanceEntries(group)
        let userNames = Dictionary(group.members.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
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
