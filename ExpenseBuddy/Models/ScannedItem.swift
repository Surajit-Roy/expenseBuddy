//
//  ScannedItem.swift
//  ExpenseBuddy
//

import Foundation

/// Represents a single line item extracted from a receipt via OCR.
struct ScannedItem: Identifiable {
    let id = UUID()
    var name: String
    var price: Double
    var assignedToUserIds: Set<String> = []
    
    /// Returns the per-person share for this item based on how many people are assigned.
    var perPersonShare: Double {
        guard !assignedToUserIds.isEmpty else { return 0 }
        return ((price / Double(assignedToUserIds.count)) * 100).rounded() / 100.0
    }
}
