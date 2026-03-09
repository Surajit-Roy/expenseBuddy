//
//  Settlement.swift
//  ExpenseBuddy
//

import Foundation

struct Settlement: Identifiable, Codable {
    let id: String
    let fromUser: User
    let toUser: User
    var amount: Double
    var date: Date
    var participantEmails: [String]? // Flat array for privacy matching
    var groupId: String?
    var note: String?
}
