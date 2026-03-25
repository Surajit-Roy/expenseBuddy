import XCTest
@testable import ExpenseBuddy

final class ExpenseTests: XCTestCase {

    func testExpenseInitialization() {
        let date = Date()
        let splits = [
            ExpenseSplit(userId: "u1", amountOwed: 25.0),
            ExpenseSplit(userId: "u2", amountOwed: 25.0)
        ]
        
        let expense = Expense(
            id: "exp_1",
            title: "Dinner",
            amount: 50.0,
            paidByUserId: "u1",
            participantIds: ["u1", "u2"],
            splitType: .equal,
            splits: splits,
            groupId: "g_1",
            category: .food,
            note: "Pizza night",
            createdByUserId: "u1",
            createdAt: date,
            updatedAt: date
        )
        
        XCTAssertEqual(expense.id, "exp_1")
        XCTAssertEqual(expense.title, "Dinner")
        XCTAssertEqual(expense.amount, 50.0)
        XCTAssertEqual(expense.paidByUserId, "u1")
        XCTAssertEqual(expense.participantIds, ["u1", "u2"])
        XCTAssertEqual(expense.splitType, .equal)
        XCTAssertEqual(expense.splits.count, 2)
        XCTAssertEqual(expense.splits[0].id, "u1") // id is identical to userId
        XCTAssertEqual(expense.groupId, "g_1")
        XCTAssertEqual(expense.category, .food)
        XCTAssertEqual(expense.note, "Pizza night")
        XCTAssertEqual(expense.createdByUserId, "u1")
        XCTAssertEqual(expense.createdAt, date)
        XCTAssertEqual(expense.updatedAt, date)
    }

    func testSplitTypeProperties() {
        XCTAssertEqual(SplitType.equal.icon, "equal.circle.fill")
        XCTAssertEqual(SplitType.unequal.icon, "slider.horizontal.3")
        XCTAssertEqual(SplitType.percentage.icon, "percent")
        XCTAssertEqual(SplitType.exact.icon, "number.circle.fill")
    }

    func testExpenseCategoryProperties() {
        XCTAssertEqual(ExpenseCategory.food.icon, "fork.knife")
        XCTAssertEqual(ExpenseCategory.food.colorHex, "#FF6B6B")
        
        XCTAssertEqual(ExpenseCategory.transport.icon, "car.fill")
        XCTAssertEqual(ExpenseCategory.transport.colorHex, "#4ECDC4")
        
        XCTAssertEqual(ExpenseCategory.shopping.icon, "bag.fill")
        XCTAssertEqual(ExpenseCategory.shopping.colorHex, "#FFE66D")
        
        XCTAssertEqual(ExpenseCategory.entertainment.icon, "gamecontroller.fill")
        XCTAssertEqual(ExpenseCategory.entertainment.colorHex, "#A855F7")
        
        XCTAssertEqual(ExpenseCategory.utilities.icon, "bolt.fill")
        XCTAssertEqual(ExpenseCategory.utilities.colorHex, "#F59E0B")
        
        XCTAssertEqual(ExpenseCategory.rent.icon, "house.fill")
        XCTAssertEqual(ExpenseCategory.rent.colorHex, "#3B82F6")
        
        XCTAssertEqual(ExpenseCategory.travel.icon, "airplane")
        XCTAssertEqual(ExpenseCategory.travel.colorHex, "#EC4899")
        
        XCTAssertEqual(ExpenseCategory.health.icon, "heart.fill")
        XCTAssertEqual(ExpenseCategory.health.colorHex, "#EF4444")
        
        XCTAssertEqual(ExpenseCategory.education.icon, "book.fill")
        XCTAssertEqual(ExpenseCategory.education.colorHex, "#8B5CF6")
        
        XCTAssertEqual(ExpenseCategory.other.icon, "ellipsis.circle.fill")
        XCTAssertEqual(ExpenseCategory.other.colorHex, "#6B7280")
    }
}
