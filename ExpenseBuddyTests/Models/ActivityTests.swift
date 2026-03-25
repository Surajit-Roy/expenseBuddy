import XCTest
@testable import ExpenseBuddy

final class ActivityTests: XCTestCase {

    func testActivityItemInitialization() {
        let date = Date()
        let activity = ActivityItem(
            id: "act_1",
            type: .expenseAdded,
            title: "Lunch Added",
            subtitle: "You paid $50",
            amount: 50.0,
            date: date,
            involvedUserIds: ["u1", "u2"],
            groupName: "Trip",
            relatedExpenseId: "exp_1"
        )
        
        XCTAssertEqual(activity.id, "act_1")
        XCTAssertEqual(activity.type, .expenseAdded)
        XCTAssertEqual(activity.title, "Lunch Added")
        XCTAssertEqual(activity.subtitle, "You paid $50")
        XCTAssertEqual(activity.amount, 50.0)
        XCTAssertEqual(activity.date, date)
        XCTAssertEqual(activity.involvedUserIds, ["u1", "u2"])
        XCTAssertEqual(activity.groupName, "Trip")
        XCTAssertEqual(activity.relatedExpenseId, "exp_1")
    }
    
    func testActivityTypeProperties() {
        XCTAssertEqual(ActivityType.expenseAdded.icon, "receipt.fill")
        XCTAssertEqual(ActivityType.expenseAdded.colorHex, "#3B82F6")
        
        XCTAssertEqual(ActivityType.settlement.icon, "checkmark.circle.fill")
        XCTAssertEqual(ActivityType.settlement.colorHex, "#10B981")
        
        XCTAssertEqual(ActivityType.friendRequest.icon, "person.badge.plus")
        XCTAssertEqual(ActivityType.friendRequest.colorHex, "#8B5CF6")
        
        XCTAssertEqual(ActivityType.groupCreated.icon, "person.3.fill")
        XCTAssertEqual(ActivityType.groupCreated.colorHex, "#F59E0B")
        
        XCTAssertEqual(ActivityType.memberAdded.icon, "person.fill.badge.plus")
        XCTAssertEqual(ActivityType.memberAdded.colorHex, "#EC4899")
    }
}
