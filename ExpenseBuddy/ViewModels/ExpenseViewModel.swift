//
//  ExpenseViewModel.swift
//  ExpenseBuddy
//

import SwiftUI
import Combine

@MainActor
class ExpenseViewModel: ObservableObject {
    @Published var title = ""
    @Published var amountText = "" {
        didSet {
            // Sanitize: only digits and max one decimal with 2 places
            let sanitized = Validator.sanitizeAmountInput(amountText)
            if sanitized != amountText {
                amountText = sanitized
            }
        }
    }
    @Published var selectedCategory: ExpenseCategory = .food
    @Published var splitType: SplitType = .equal
    @Published var paidByUserId: String = ""
    @Published var selectedParticipantIds: Set<String> = []
    @Published var unequalAmounts: [String: String] = [:]
    @Published var percentages: [String: String] = [:]
    @Published var note = ""
    @Published var errorMessage: String?
    @Published var groupId: String?
    
    var dataService: DataService?
    /// Available members as User objects (for display). Resolved from UserCache.
    var availableMembers: [User] = []
    
    init(groupId: String? = nil) {
        self.groupId = groupId
    }
    
    func setDataService(_ dataService: DataService) {
        self.dataService = dataService
        self.paidByUserId = dataService.currentUser.id
        
        if let groupId, let group = dataService.groups.first(where: { $0.id == groupId }) {
            // Resolve member IDs to User objects for display
            availableMembers = group.memberIds.compactMap { dataService.userCache.user(for: $0) }
            // If some members aren't cached yet, include placeholders
            if availableMembers.count < group.memberIds.count {
                let cachedIds = Set(availableMembers.map { $0.id })
                for id in group.memberIds where !cachedIds.contains(id) {
                    availableMembers.append(dataService.userCache.userOrPlaceholder(for: id))
                }
            }
            selectedParticipantIds = Set(group.memberIds)
        } else {
            var members = [dataService.currentUser]
            members.append(contentsOf: dataService.friends)
            availableMembers = members
            selectedParticipantIds = [dataService.currentUser.id]
        }
    }
    
    var amount: Double {
        Double(amountText) ?? 0
    }
    
    var selectedParticipants: [User] {
        availableMembers.filter { selectedParticipantIds.contains($0.id) }
    }
    
    var paidByUser: User {
        guard let ds = dataService else {
            return availableMembers.first ?? User(id: "", name: "", email: "", profileImage: "", createdAt: Date())
        }
        return availableMembers.first { $0.id == paidByUserId } ?? ds.currentUser
    }
    
    // MARK: - Validation
    
    var isValid: Bool {
        titleError == nil && amountError == nil && participantsError == nil && payerError == nil && groupId != nil
    }
    
    var titleError: String? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Title is required" }
        if trimmed.count > 100 { return "Title too long (max 100 characters)" }
        return nil
    }
    
    var amountError: String? {
        if amountText.isEmpty { return "Amount is required" }
        guard let val = Double(amountText) else { return "Invalid amount" }
        if val <= 0 { return "Amount must be greater than zero" }
        if val > 9_999_999.99 { return "Amount too large (max \(CurrencyManager.shared.symbol)99,99,999.99)" }
        return nil
    }
    
    var participantsError: String? {
        if selectedParticipantIds.count < 2 { return "Select at least 2 participants" }
        return nil
    }
    
    var payerError: String? {
        if !selectedParticipantIds.contains(paidByUserId) {
            return "The payer must be a participant"
        }
        return nil
    }
    
    var equalSplitAmount: Double {
        guard !selectedParticipantIds.isEmpty else { return 0 }
        return ((amount / Double(selectedParticipantIds.count)) * 100).rounded() / 100.0
    }
    
    // MARK: - Split Calculation
    
    func calculateSplits() -> [ExpenseSplit] {
        let participantIdsList = Array(selectedParticipantIds)
        
        switch splitType {
        case .equal:
            return ExpenseCalculator.calculateEqualSplit(amount: amount, participantIds: participantIdsList)
        case .unequal, .exact:
            return participantIdsList.map { userId in
                let amt = Double(unequalAmounts[userId] ?? "0") ?? 0
                return ExpenseSplit(userId: userId, amountOwed: ((amt * 100).rounded() / 100.0))
            }
        case .percentage:
            let percentageValues = participantIdsList.reduce(into: [String: Double]()) { result, userId in
                result[userId] = Double(percentages[userId] ?? "0") ?? 0
            }
            return ExpenseCalculator.calculatePercentageSplit(amount: amount, participantIds: participantIdsList, percentages: percentageValues)
        }
    }
    
    func validateSplits() -> Bool {
        switch splitType {
        case .equal:
            return true
        case .unequal, .exact:
            let total = selectedParticipantIds.reduce(0.0) { sum, userId in
                sum + (Double(unequalAmounts[userId] ?? "0") ?? 0)
            }
            return abs(total - amount) < 0.01
        case .percentage:
            let total = selectedParticipantIds.reduce(0.0) { sum, userId in
                sum + (Double(percentages[userId] ?? "0") ?? 0)
            }
            return abs(total - 100) < 0.01
        }
    }
    
    // MARK: - Save
    
    func addExpense() -> Bool {
        guard let dataService else {
            errorMessage = "Service not available."
            return false
        }
        
        // Group validation
        guard groupId != nil else {
            errorMessage = "Please select a group."
            return false
        }
        
        // Title validation
        if let err = titleError {
            errorMessage = err
            return false
        }
        
        // Amount validation
        if let err = amountError {
            errorMessage = err
            return false
        }
        
        // Participants validation
        if let err = participantsError {
            errorMessage = err
            return false
        }
        
        // Payer validation
        if let err = payerError {
            errorMessage = err
            return false
        }
        
        // Split validation
        if !validateSplits() {
            switch splitType {
            case .equal: break
            case .unequal, .exact:
                errorMessage = "Split amounts must add up to \(CurrencyManager.shared.format(amount))."
                return false
            case .percentage:
                errorMessage = "Percentages must add up to 100%."
                return false
            }
        }
        
        let splits = calculateSplits()
        
        // Convert amount and splits to INR (base currency) before saving
        let inrAmount = CurrencyManager.shared.convertToINR(amount)
        
        let inrSplits = splits.map { split in
            ExpenseSplit(
                userId: split.userId,
                amountOwed: CurrencyManager.shared.convertToINR(split.amountOwed)
            )
        }
        
        let expense = Expense(
            id: UUID().uuidString,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: inrAmount,
            paidByUserId: paidByUserId,
            participantIds: Array(selectedParticipantIds),
            splitType: splitType,
            splits: inrSplits,
            groupId: groupId,
            category: selectedCategory,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note.trimmingCharacters(in: .whitespacesAndNewlines),
            createdByUserId: dataService.currentUser.id,
            createdAt: Date(),
            updatedAt: nil
        )
        
        dataService.addExpense(expense)
        errorMessage = nil
        return true
    }
}
