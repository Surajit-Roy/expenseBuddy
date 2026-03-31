//
//  Budget.swift
//  ExpenseBuddy
//

import Foundation

/// Represents a monthly spending limit for a group, category, or overall.
struct Budget: Identifiable, Codable {
    let id: String
    var userId: String
    var groupId: String?                // nil = overall budget
    var categoryRaw: String?            // nil = all categories
    var monthlyLimit: Double
    var createdAt: Date
    
    var category: ExpenseCategory? {
        guard let raw = categoryRaw else { return nil }
        return ExpenseCategory(rawValue: raw)
    }
}
