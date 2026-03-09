//
//  ExpenseCalculator.swift
//  ExpenseBuddy
//

import Foundation

// MARK: - Balance Models

struct BalanceEntry: Identifiable {
    var id: String { "\(fromUserId)-\(toUserId)" }
    let fromUserId: String
    let fromUserName: String
    let toUserId: String
    let toUserName: String
    var amount: Double
}

struct UserBalance: Identifiable {
    var id: String { userId }
    let userId: String
    let userName: String
    var totalBalance: Double // positive = owed to them, negative = they owe
}

struct SimplifiedDebt: Identifiable {
    var id: String { "\(fromUserId)-\(toUserId)" }
    let fromUserId: String
    let fromUserName: String
    let toUserId: String
    let toUserName: String
    let amount: Double
}

// MARK: - ExpenseCalculator

struct ExpenseCalculator {
    
    // MARK: - Equal Split WITH Remainder Handling
    
    /// Splits amount equally. The last participant absorbs any rounding remainder.
    /// e.g. ₹100 ÷ 3 → ₹33.33, ₹33.33, ₹33.34
    static func calculateEqualSplit(amount: Double, participantIds: [String]) -> [ExpenseSplit] {
        guard !participantIds.isEmpty else { return [] }
        
        let count = participantIds.count
        // Round each share DOWN to 2 decimal places
        let baseShare = (amount / Double(count) * 100).rounded(.down) / 100.0
        let totalDistributed = baseShare * Double(count)
        let remainder = ((amount - totalDistributed) * 100).rounded() / 100.0
        
        return participantIds.enumerated().map { index, userId in
            let share = (index == count - 1) ? baseShare + remainder : baseShare
            return ExpenseSplit(userId: userId, amountOwed: share)
        }
    }
    
    // MARK: - Percentage Split
    
    static func calculatePercentageSplit(amount: Double, participantIds: [String], percentages: [String: Double]) -> [ExpenseSplit] {
        return participantIds.map { userId in
            let percentage = percentages[userId] ?? 0
            let share = ((amount * percentage / 100.0) * 100).rounded() / 100.0
            return ExpenseSplit(userId: userId, amountOwed: share)
        }
    }
    
    // MARK: - Pairwise Balance Calculation
    
    /// Compute net balance from A→B across all expenses and settlements.
    /// Returns the net amount that each pair owes (positive = fromUser owes toUser).
    static func calculateBalances(expenses: [Expense], settlements: [Settlement], currentUserId: String, userNames: [String: String] = [:]) -> [BalanceEntry] {
        // Track net: netOwed[A][B] > 0 means B owes A
        var netOwed: [String: [String: Double]] = [:]
        
        // Process expenses: payer paid on behalf of participants
        for expense in expenses {
            let payerId = expense.paidByUserId
            
            for split in expense.splits {
                if split.userId != payerId {
                    // split.userId owes payerId the split amount
                    netOwed[payerId, default: [:]][split.userId, default: 0] += split.amountOwed
                    netOwed[split.userId, default: [:]][payerId, default: 0] -= split.amountOwed
                }
            }
        }
        
        // Process settlements: fromUser paid toUser (reduces debt)
        for settlement in settlements {
            let fromId = settlement.fromUserId
            let toId = settlement.toUserId
            
            netOwed[toId, default: [:]][fromId, default: 0] -= settlement.amount
            netOwed[fromId, default: [:]][toId, default: 0] += settlement.amount
        }
        
        // Build simplified pairwise balances (one entry per pair)
        var balances: [BalanceEntry] = []
        var processed = Set<String>()
        
        for (userA, debts) in netOwed {
            for (userB, amount) in debts {
                let pairKey = [userA, userB].sorted().joined(separator: "-")
                guard !processed.contains(pairKey) else { continue }
                processed.insert(pairKey)
                
                // Round to 2 decimal places to avoid floating point noise
                let roundedAmount = (amount * 100).rounded() / 100.0
                
                if abs(roundedAmount) > 0.01 {
                    if roundedAmount > 0 {
                        // userB owes userA
                        balances.append(BalanceEntry(
                            fromUserId: userB,
                            fromUserName: userNames[userB] ?? "",
                            toUserId: userA,
                            toUserName: userNames[userA] ?? "",
                            amount: roundedAmount
                        ))
                    } else {
                        // userA owes userB
                        balances.append(BalanceEntry(
                            fromUserId: userA,
                            fromUserName: userNames[userA] ?? "",
                            toUserId: userB,
                            toUserName: userNames[userB] ?? "",
                            amount: abs(roundedAmount)
                        ))
                    }
                }
            }
        }
        
        return balances
    }
    
    // MARK: - Net Balance for a User
    
    /// Total balance: positive = others owe them, negative = they owe others
    static func totalBalance(for userId: String, balances: [BalanceEntry]) -> Double {
        var total: Double = 0
        for balance in balances {
            if balance.toUserId == userId {
                total += balance.amount // someone owes them
            } else if balance.fromUserId == userId {
                total -= balance.amount // they owe someone
            }
        }
        return (total * 100).rounded() / 100.0
    }
    
    // MARK: - Debt Simplification (Minimize Transactions)
    
    /// Given a list of balance entries, compute the minimum number of transactions
    /// needed to settle all debts. Uses the greedy algorithm:
    /// 1. Compute net balance for each user
    /// 2. Match largest creditor with largest debtor
    /// 3. Repeat until settled
    static func simplifyDebts(balances: [BalanceEntry], userNames: [String: String]) -> [SimplifiedDebt] {
        // Step 1: Compute net balance per user
        var netBalance: [String: Double] = [:]
        for entry in balances {
            netBalance[entry.fromUserId, default: 0] -= entry.amount
            netBalance[entry.toUserId, default: 0] += entry.amount
        }
        
        // Step 2: Separate into creditors (+) and debtors (-)
        struct UserAmount: Comparable {
            let userId: String
            var amount: Double
            static func < (lhs: UserAmount, rhs: UserAmount) -> Bool {
                lhs.amount < rhs.amount
            }
        }
        
        var creditors: [UserAmount] = [] // positive net = owed money
        var debtors: [UserAmount] = []   // negative net = owes money
        
        for (userId, balance) in netBalance {
            let rounded = (balance * 100).rounded() / 100.0
            if rounded > 0.01 {
                creditors.append(UserAmount(userId: userId, amount: rounded))
            } else if rounded < -0.01 {
                debtors.append(UserAmount(userId: userId, amount: abs(rounded)))
            }
        }
        
        // Sort descending by amount
        creditors.sort { $0.amount > $1.amount }
        debtors.sort { $0.amount > $1.amount }
        
        // Step 3: Greedily match
        var result: [SimplifiedDebt] = []
        var ci = 0, di = 0
        
        while ci < creditors.count && di < debtors.count {
            let transferAmount = min(creditors[ci].amount, debtors[di].amount)
            let rounded = (transferAmount * 100).rounded() / 100.0
            
            if rounded > 0.01 {
                result.append(SimplifiedDebt(
                    fromUserId: debtors[di].userId,
                    fromUserName: userNames[debtors[di].userId] ?? "",
                    toUserId: creditors[ci].userId,
                    toUserName: userNames[creditors[ci].userId] ?? "",
                    amount: rounded
                ))
            }
            
            creditors[ci].amount -= transferAmount
            debtors[di].amount -= transferAmount
            
            if creditors[ci].amount < 0.01 { ci += 1 }
            if debtors[di].amount < 0.01 { di += 1 }
        }
        
        return result
    }
    
    // MARK: - Balance Between Two Users
    
    /// Get balance between current user and a specific friend.
    /// Positive = friend owes you, negative = you owe friend.
    static func balanceBetween(currentUserId: String, friendId: String, expenses: [Expense], settlements: [Settlement]) -> Double {
        var net: Double = 0
        
        // From expenses
        for expense in expenses {
            let payerId = expense.paidByUserId
            for split in expense.splits {
                if payerId == currentUserId && split.userId == friendId {
                    // Current user paid, friend owes their share → friend owes you
                    net += split.amountOwed
                } else if payerId == friendId && split.userId == currentUserId {
                    // Friend paid, you owe your share → you owe friend
                    net -= split.amountOwed
                }
            }
        }
        
        // From settlements
        for settlement in settlements {
            if settlement.fromUserId == friendId && settlement.toUserId == currentUserId {
                // Friend paid you → reduces what they owe
                net -= settlement.amount
            } else if settlement.fromUserId == currentUserId && settlement.toUserId == friendId {
                // You paid friend → reduces what you owe
                net += settlement.amount
            }
        }
        
        return (net * 100).rounded() / 100.0
    }
    
    // MARK: - Suggested Settlement Amount
    
    /// Returns the amount the current user should pay to settle with a friend.
    /// Positive = you should pay them this much. Negative = they should pay you.
    static func suggestedSettlement(currentUserId: String, friendId: String, expenses: [Expense], settlements: [Settlement]) -> Double {
        let balance = balanceBetween(currentUserId: currentUserId, friendId: friendId, expenses: expenses, settlements: settlements)
        // If balance is negative, you owe them → return the positive amount to pay
        // If balance is positive, they owe you → return 0 (you don't need to pay)
        return balance < 0 ? abs(balance) : 0
    }
    
    // MARK: - Per-User Balances
    
    static func userBalances(expenses: [Expense], settlements: [Settlement], userIds: [String], currentUserId: String, userNames: [String: String] = [:]) -> [UserBalance] {
        return userIds.compactMap { userId in
            guard userId != currentUserId else { return nil }
            let net = balanceBetween(currentUserId: currentUserId, friendId: userId, expenses: expenses, settlements: settlements)
            guard abs(net) > 0.01 else { return nil }
            return UserBalance(userId: userId, userName: userNames[userId] ?? "", totalBalance: net)
        }
    }
}
