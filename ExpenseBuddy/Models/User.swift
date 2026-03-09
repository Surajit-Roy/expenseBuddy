//
//  User.swift
//  ExpenseBuddy
//

import Foundation

struct User: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var email: String
    var mobileNumber: String = ""
    var profileImage: String // SF Symbol name or URL
    var createdAt: Date
    
    var initials: String {
        let components = name.split(separator: " ")
        let first = components.first?.prefix(1) ?? ""
        let last = components.count > 1 ? components.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
