import XCTest
@testable import ExpenseBuddy

final class SettlementTests: XCTestCase {

    func testSettlementInitialization() {
        let date = Date()
        let settlement = Settlement(
            id: "s_1",
            fromUserId: "u1",
            toUserId: "u2",
            amount: 100.0,
            date: date,
            participantIds: ["u1", "u2"],
            groupId: "g_1",
            note: "August Rent",
            createdByUserId: "u1"
        )
        
        XCTAssertEqual(settlement.id, "s_1")
        XCTAssertEqual(settlement.fromUserId, "u1")
        XCTAssertEqual(settlement.toUserId, "u2")
        XCTAssertEqual(settlement.amount, 100.0)
        XCTAssertEqual(settlement.date, date)
        XCTAssertEqual(settlement.participantIds, ["u1", "u2"])
        XCTAssertEqual(settlement.groupId, "g_1")
        XCTAssertEqual(settlement.note, "August Rent")
        XCTAssertEqual(settlement.createdByUserId, "u1")
    }
}
