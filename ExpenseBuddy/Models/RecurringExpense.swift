//
//  RecurringExpense.swift
//  ExpenseBuddy
//

import Foundation

/// Represents an expense that automatically repeats on a schedule.
struct RecurringExpense: Identifiable, Codable {
    let id: String
    var title: String
    var amount: Double
    var paidByUserId: String
    var participantIds: [String]
    var splitType: SplitType
    var splits: [ExpenseSplit]
    var groupId: String
    var category: ExpenseCategory
    var note: String?
    var frequency: RecurrenceFrequency
    var nextDueDate: Date
    var isActive: Bool
    var createdByUserId: String
    var createdAt: Date
    var participantStatuses: [String: ApprovalStatus]?
    var seedExpenseId: String?
    
    /// Advances the `nextDueDate` by the frequency interval.
    mutating func advanceToNextDueDate() {
        switch frequency {
        case .weekly:
            nextDueDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: nextDueDate) ?? nextDueDate
        case .monthly:
            nextDueDate = Calendar.current.date(byAdding: .month, value: 1, to: nextDueDate) ?? nextDueDate
        case .yearly:
            nextDueDate = Calendar.current.date(byAdding: .year, value: 1, to: nextDueDate) ?? nextDueDate
        }
    }
}

/// Represents a participant's approval status for a recurring expense template.
enum ApprovalStatus: String, Codable {
    case pending = "Pending"
    case approved = "Approved"
    case declined = "Declined"
    
    var colorHex: String {
        switch self {
        case .pending: return "#F59E0B" // Orange/Amber
        case .approved: return "#10B981" // Green
        case .declined: return "#EF4444" // Red
        }
    }
}

/// How often a recurring expense repeats.
enum RecurrenceFrequency: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
    
    var icon: String {
        switch self {
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar"
        case .yearly: return "calendar.circle"
        }
    }
    
    var shortLabel: String {
        switch self {
        case .weekly: return "week"
        case .monthly: return "month"
        case .yearly: return "year"
        }
    }
}
