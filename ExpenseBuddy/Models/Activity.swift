//
//  Activity.swift
//  ExpenseBuddy
//

import Foundation

struct ActivityItem: Identifiable, Codable {
    let id: String
    let type: ActivityType
    let title: String
    let subtitle: String
    let amount: Double?
    let date: Date
    let involvedUserIds: [String]
    let groupName: String?
    let relatedExpenseId: String?
}

enum ActivityType: String, Codable {
    case expenseAdded = "expense_added"
    case settlement = "settlement"
    case friendRequest = "friend_request"
    case groupCreated = "group_created"
    case memberAdded = "member_added"
    
    var icon: String {
        switch self {
        case .expenseAdded: return "receipt.fill"
        case .settlement: return "checkmark.circle.fill"
        case .friendRequest: return "person.badge.plus"
        case .groupCreated: return "person.3.fill"
        case .memberAdded: return "person.fill.badge.plus"
        }
    }
    
    var colorHex: String {
        switch self {
        case .expenseAdded: return "#3B82F6"
        case .settlement: return "#10B981"
        case .friendRequest: return "#8B5CF6"
        case .groupCreated: return "#F59E0B"
        case .memberAdded: return "#EC4899"
        }
    }
}
