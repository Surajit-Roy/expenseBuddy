//
//  Settlement.swift
//  ExpenseBuddy
//

import Foundation

struct Settlement: Identifiable, Codable {
    let id: String
    var fromUserId: String
    var toUserId: String
    var amount: Double
    var date: Date
    var participantIds: [String] // [fromUserId, toUserId] for Firestore arrayContains queries
    var groupId: String?
    var note: String?
    var createdByUserId: String
}
