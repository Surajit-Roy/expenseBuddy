//
//  User.swift
//  ExpenseBuddy
//

import Foundation

struct User: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var email: String
    var mobileNumber: String? = nil // Optional with default nil
    var profileImage: String // SF Symbol name or URL
    var fcmToken: String? = nil // FCM device token for push notifications
    var createdAt: Date
    
    var initials: String {
        let components = name.split(separator: " ")
        let first = components.first?.prefix(1) ?? ""
        let last = components.count > 1 ? components.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }
    
    // Custom Equatable for performance with large profile images
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.email == rhs.email &&
               lhs.mobileNumber == rhs.mobileNumber &&
               lhs.profileImage.count == rhs.profileImage.count && // Fast check
               lhs.profileImage.prefix(100) == rhs.profileImage.prefix(100) // Fast partial check
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
