//
//  Group.swift
//  ExpenseBuddy
//

import Foundation

struct ExpenseGroup: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var members: [User]
    var memberIds: [String] // Flat array for Firestore arrayContains queries
    var memberEmails: [String] // Flat array for actual identity/privacy matching
    var createdBy: User
    var createdAt: Date
    var groupIcon: String // SF Symbol name
    var groupType: GroupType
    
    static func == (lhs: ExpenseGroup, rhs: ExpenseGroup) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum GroupType: String, Codable, CaseIterable {
    case home = "Home"
    case trip = "Trip"
    case office = "Office"
    case couple = "Couple"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .trip: return "airplane"
        case .office: return "building.2.fill"
        case .couple: return "heart.fill"
        case .other: return "folder.fill"
        }
    }
    
    var color: String {
        switch self {
        case .home: return "blue"
        case .trip: return "orange"
        case .office: return "purple"
        case .couple: return "pink"
        case .other: return "gray"
        }
    }
}
