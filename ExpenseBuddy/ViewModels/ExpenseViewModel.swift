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
    var availableMembers: [User] = []
    
    init(groupId: String? = nil) {
        self.groupId = groupId
    }
    
    func setDataService(_ dataService: DataService) {
        self.dataService = dataService
        self.paidByUserId = dataService.currentUser.id
        
        if let groupId, let group = dataService.groups.first(where: { $0.id == groupId }) {
            availableMembers = group.members
            selectedParticipantIds = Set(group.members.map { $0.id })
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
        let participants = selectedParticipants
        
        switch splitType {
        case .equal:
            return ExpenseCalculator.calculateEqualSplit(amount: amount, participants: participants)
        case .unequal, .exact:
            return participants.map { user in
                let amt = Double(unequalAmounts[user.id] ?? "0") ?? 0
                return ExpenseSplit(userId: user.id, userName: user.name, amountOwed: ((amt * 100).rounded() / 100.0))
            }
        case .percentage:
            let percentageValues = participants.reduce(into: [String: Double]()) { result, user in
                result[user.id] = Double(percentages[user.id] ?? "0") ?? 0
            }
            return ExpenseCalculator.calculatePercentageSplit(amount: amount, participants: participants, percentages: percentageValues)
        }
    }
    
    func validateSplits() -> Bool {
        switch splitType {
        case .equal:
            return true
        case .unequal, .exact:
            let total = selectedParticipants.reduce(0.0) { sum, user in
                sum + (Double(unequalAmounts[user.id] ?? "0") ?? 0)
            }
            return abs(total - amount) < 0.01
        case .percentage:
            let total = selectedParticipants.reduce(0.0) { sum, user in
                sum + (Double(percentages[user.id] ?? "0") ?? 0)
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
        
        // The `amount` property contains the user's input in their selected currency.
        // We MUST convert it and all calculated splits back to INR (base currency) before saving.
        let inrAmount = CurrencyManager.shared.convertToINR(amount)
        
        let inrSplits = splits.map { split in
            ExpenseSplit(
                userId: split.userId,
                userName: split.userName,
                amountOwed: CurrencyManager.shared.convertToINR(split.amountOwed)
            )
        }
        
        // Final safety: verify splits sum matches total *after* conversion
        let inrSplitsTotal = inrSplits.reduce(0.0) { $0 + $1.amountOwed }
        if abs(inrSplitsTotal - inrAmount) > 0.05 {
            // Recalculate or log due to minor rounding differences after conversion
        }
        
        let expense = Expense(
            id: UUID().uuidString,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: inrAmount,
            paidBy: paidByUser,
            participants: selectedParticipants,
            participantIds: selectedParticipants.map { $0.id },
            participantEmails: selectedParticipants.map { $0.email },
            splitType: splitType,
            splits: inrSplits,
            groupId: groupId,
            category: selectedCategory,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: Date()
        )
        
        dataService.addExpense(expense)
        errorMessage = nil
        return true
    }
}
