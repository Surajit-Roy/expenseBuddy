//
//  Expense.swift
//  ExpenseBuddy
//

import Foundation

struct Expense: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var amount: Double
    var paidByUserId: String
    var participantIds: [String] // All participant user IDs (including payer)
    var splitType: SplitType
    var splits: [ExpenseSplit]
    var groupId: String?
    var category: ExpenseCategory
    var note: String?
    var createdByUserId: String
    var createdAt: Date
    var updatedAt: Date?
}

struct ExpenseSplit: Identifiable, Codable, Hashable {
    var id: String { userId }
    var userId: String
    var amountOwed: Double
}

enum SplitType: String, Codable, CaseIterable, Hashable {
    case equal = "Equal"
    case unequal = "Unequal"
    case percentage = "Percentage"
    case exact = "Exact Amount"
    
    var icon: String {
        switch self {
        case .equal: return "equal.circle.fill"
        case .unequal: return "slider.horizontal.3"
        case .percentage: return "percent"
        case .exact: return "number.circle.fill"
        }
    }
}

enum ExpenseCategory: String, Codable, CaseIterable, Hashable {
    case food = "Food & Drink"
    case transport = "Transport"
    case shopping = "Shopping"
    case entertainment = "Entertainment"
    case utilities = "Utilities"
    case rent = "Rent"
    case travel = "Travel"
    case health = "Health"
    case education = "Education"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "gamecontroller.fill"
        case .utilities: return "bolt.fill"
        case .rent: return "house.fill"
        case .travel: return "airplane"
        case .health: return "heart.fill"
        case .education: return "book.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    var colorHex: String {
        switch self {
        case .food: return "#FF6B6B"
        case .transport: return "#4ECDC4"
        case .shopping: return "#FFE66D"
        case .entertainment: return "#A855F7"
        case .utilities: return "#F59E0B"
        case .rent: return "#3B82F6"
        case .travel: return "#EC4899"
        case .health: return "#EF4444"
        case .education: return "#8B5CF6"
        case .other: return "#6B7280"
        }
    }
}
