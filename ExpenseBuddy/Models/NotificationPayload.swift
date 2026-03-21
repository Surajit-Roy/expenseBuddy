//
//  NotificationPayload.swift
//  ExpenseBuddy
//

import Foundation

/// Lightweight payload for in-app notification banners.
struct NotificationPayload: Identifiable, Equatable {
    let id: String
    let title: String
    let body: String
    let expenseId: String?
    let timestamp: Date
    
    init(id: String = UUID().uuidString, title: String, body: String, expenseId: String? = nil, timestamp: Date = Date()) {
        self.id = id
        self.title = title
        self.body = body
        self.expenseId = expenseId
        self.timestamp = timestamp
    }
}
