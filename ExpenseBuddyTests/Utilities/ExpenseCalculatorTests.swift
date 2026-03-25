import XCTest
@testable import ExpenseBuddy

final class ExpenseCalculatorTests: XCTestCase {

    // MARK: - Equal Split tests
    func testCalculateEqualSplit() {
        // 100 / 3 = 33.33, 33.33, 33.34
        let splits = ExpenseCalculator.calculateEqualSplit(amount: 100, participantIds: ["u1", "u2", "u3"])
        
        XCTAssertEqual(splits.count, 3)
        XCTAssertEqual(splits[0].amountOwed, 33.33)
        XCTAssertEqual(splits[1].amountOwed, 33.33)
        XCTAssertEqual(splits[2].amountOwed, 33.34)
    }
    
    func testCalculateEqualSplitEmpty() {
        let splits = ExpenseCalculator.calculateEqualSplit(amount: 100, participantIds: [])
        XCTAssertTrue(splits.isEmpty)
    }

    // MARK: - Percentage Split tests
    func testCalculatePercentageSplit() {
        let percentages = ["u1": 50.0, "u2": 25.0, "u3": 25.0]
        let splits = ExpenseCalculator.calculatePercentageSplit(amount: 200, participantIds: ["u1", "u2", "u3"], percentages: percentages)
        
        XCTAssertEqual(splits.count, 3)
        XCTAssertEqual(splits.first(where: { $0.userId == "u1" })?.amountOwed, 100.0)
        XCTAssertEqual(splits.first(where: { $0.userId == "u2" })?.amountOwed, 50.0)
        XCTAssertEqual(splits.first(where: { $0.userId == "u3" })?.amountOwed, 50.0)
    }

    // MARK: - Balance Tests
    func testCalculateBalances() {
        let date = Date()
        let expense1 = Expense(
            id: "e1", title: "Lunch", amount: 60, paidByUserId: "u1",
            participantIds: ["u1", "u2", "u3"], splitType: .equal,
            splits: [
                ExpenseSplit(userId: "u1", amountOwed: 20),
                ExpenseSplit(userId: "u2", amountOwed: 20),
                ExpenseSplit(userId: "u3", amountOwed: 20)
            ],
            category: .food, createdByUserId: "u1", createdAt: date
        )
        
        let expense2 = Expense(
            id: "e2", title: "Cab", amount: 30, paidByUserId: "u2",
            participantIds: ["u1", "u2"], splitType: .equal,
            splits: [
                ExpenseSplit(userId: "u1", amountOwed: 15),
                ExpenseSplit(userId: "u2", amountOwed: 15)
            ],
            category: .transport, createdByUserId: "u2", createdAt: date
        )
        
        let settlement = Settlement(id: "s1", fromUserId: "u3", toUserId: "u1", amount: 10, date: date, participantIds: ["u3", "u1"], createdByUserId: "u3")
        
        let balances = ExpenseCalculator.calculateBalances(expenses: [expense1, expense2], settlements: [settlement], currentUserId: "u1")
        
        // e1: u2 owes u1 20, u3 owes u1 20
        // e2: u1 owes u2 15  -> net between u1 and u2: u2 owes u1 5
        // s1: u3 pays u1 10 -> net between u1 and u3: u3 owes u1 10
        
        XCTAssertEqual(balances.count, 2)
        
        let u2vsu1 = balances.first(where: { $0.fromUserId == "u2" || $0.toUserId == "u2" })!
        XCTAssertEqual(u2vsu1.fromUserId, "u2")
        XCTAssertEqual(u2vsu1.toUserId, "u1")
        XCTAssertEqual(u2vsu1.amount, 5.0)
        
        let u3vsu1 = balances.first(where: { $0.fromUserId == "u3" || $0.toUserId == "u3" })!
        XCTAssertEqual(u3vsu1.fromUserId, "u3")
        XCTAssertEqual(u3vsu1.toUserId, "u1")
        XCTAssertEqual(u3vsu1.amount, 10.0)
    }

    func testTotalBalance() {
        let balances = [
            BalanceEntry(fromUserId: "u2", fromUserName: "B", toUserId: "u1", toUserName: "A", amount: 15.0),
            BalanceEntry(fromUserId: "u1", fromUserName: "A", toUserId: "u3", toUserName: "C", amount: 5.0)
        ]
        
        // u1: u2 owes u1 15 (+15), u1 owes u3 5 (-5) => total +10
        let u1Total = ExpenseCalculator.totalBalance(for: "u1", balances: balances)
        XCTAssertEqual(u1Total, 10.0)
        
        // u2: u2 owes u1 15 => total -15
        let u2Total = ExpenseCalculator.totalBalance(for: "u2", balances: balances)
        XCTAssertEqual(u2Total, -15.0)
    }

    func testSimplifyDebts() {
        // A owes B 10
        // B owes C 10
        // Should simplify to A owes C 10
        let balances = [
            BalanceEntry(fromUserId: "A", fromUserName: "A", toUserId: "B", toUserName: "B", amount: 10.0),
            BalanceEntry(fromUserId: "B", fromUserName: "B", toUserId: "C", toUserName: "C", amount: 10.0)
        ]
        
        let simplified = ExpenseCalculator.simplifyDebts(balances: balances, userNames: ["A": "A", "B": "B", "C": "C"])
        
        XCTAssertEqual(simplified.count, 1)
        XCTAssertEqual(simplified[0].fromUserId, "A")
        XCTAssertEqual(simplified[0].toUserId, "C")
        XCTAssertEqual(simplified[0].amount, 10.0)
    }

    func testBalanceBetweenAndSuggestedSettlement() {
        // You (u1) and Friend (u2)
        let date = Date()
        let expense = Expense(
            id: "e1", title: "Dinner", amount: 100, paidByUserId: "u1",
            participantIds: ["u1", "u2"], splitType: .equal,
            splits: [
                ExpenseSplit(userId: "u1", amountOwed: 50),
                ExpenseSplit(userId: "u2", amountOwed: 50)
            ],
            category: .food, createdByUserId: "u1", createdAt: date
        )
        
        let net = ExpenseCalculator.balanceBetween(currentUserId: "u1", friendId: "u2", expenses: [expense], settlements: [])
        XCTAssertEqual(net, 50.0) // Friend owes you 50
        
        let settlementAmount = ExpenseCalculator.suggestedSettlement(currentUserId: "u1", friendId: "u2", expenses: [expense], settlements: [])
        XCTAssertEqual(settlementAmount, 0) // You owe nothing
        
        let settlementAmountReverse = ExpenseCalculator.suggestedSettlement(currentUserId: "u2", friendId: "u1", expenses: [expense], settlements: [])
        XCTAssertEqual(settlementAmountReverse, 50.0) // Friend owes you 50, so friend's suggested payment is 50
    }
}
