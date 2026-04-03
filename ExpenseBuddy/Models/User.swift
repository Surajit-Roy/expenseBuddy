//
//  User.swift
//  ExpenseBuddy
//

import Foundation

struct User: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var email: String
    var mobileNumber: String? = nil
    var profileImage: String
    var fcmToken: String? = nil
    var hasAcceptedTerms: Bool = false
    var notificationsEnabled: Bool = true
    var createdAt: Date
    
    var initials: String {
        let components = name.split(separator: " ")
        let first = components.first?.prefix(1) ?? ""
        let last = components.count > 1 ? components.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, email, mobileNumber, profileImage, fcmToken, hasAcceptedTerms, notificationsEnabled, createdAt
    }
    
    init(id: String, name: String, email: String, mobileNumber: String? = nil, profileImage: String, fcmToken: String? = nil, hasAcceptedTerms: Bool = false, notificationsEnabled: Bool = true, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.email = email
        self.mobileNumber = mobileNumber
        self.profileImage = profileImage
        self.fcmToken = fcmToken
        self.hasAcceptedTerms = hasAcceptedTerms
        self.notificationsEnabled = notificationsEnabled
        self.createdAt = createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        mobileNumber = try container.decodeIfPresent(String.self, forKey: .mobileNumber)
        profileImage = try container.decodeIfPresent(String.self, forKey: .profileImage) ?? "person.circle.fill"
        fcmToken = try container.decodeIfPresent(String.self, forKey: .fcmToken)
        hasAcceptedTerms = try container.decodeIfPresent(Bool.self, forKey: .hasAcceptedTerms) ?? false
        notificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? true
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }
    
    // Custom Equatable for performance with large profile images
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.email == rhs.email &&
               lhs.mobileNumber == rhs.mobileNumber &&
               lhs.profileImage.count == rhs.profileImage.count &&
               lhs.profileImage.prefix(100) == rhs.profileImage.prefix(100)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
