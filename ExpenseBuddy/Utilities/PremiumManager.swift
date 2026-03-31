//
//  PremiumManager.swift
//  ExpenseBuddy
//

import Foundation

/// Controls access to premium features.
///
/// Premium features: AI Receipt Scanner, Recurring Expenses,
/// Spending Budgets, Export to PDF.
///
/// Set `isPremiumEnabled = true` to unlock all premium features.
/// When you add real in-app purchases later, this flag can be
/// driven by StoreKit / Firebase Custom Claims instead.
final class PremiumManager {
    static let shared = PremiumManager()
    
    /// Master switch for premium features.
    /// - `true`  → AI Receipt Scanner, Recurring Expenses, Spending Budgets, Export to PDF are visible.
    /// - `false` → These features are hidden from the UI; the app works as a normal expense tracker.
    var isPremiumEnabled: Bool = true
    
    private init() {}
}
