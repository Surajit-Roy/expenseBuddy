import XCTest
@testable import ExpenseBuddy

final class GroupTests: XCTestCase {

    func testGroupInitialization() {
        let date = Date()
        let group = ExpenseGroup(
            id: "g_1",
            name: "Roommates",
            memberIds: ["u1", "u2", "u3"],
            createdByUserId: "u1",
            createdAt: date,
            updatedAt: date,
            groupIcon: GroupType.home.icon,
            groupType: .home
        )
        
        XCTAssertEqual(group.id, "g_1")
        XCTAssertEqual(group.name, "Roommates")
        XCTAssertEqual(group.memberIds, ["u1", "u2", "u3"])
        XCTAssertEqual(group.createdByUserId, "u1")
        XCTAssertEqual(group.createdAt, date)
        XCTAssertEqual(group.updatedAt, date)
        XCTAssertEqual(group.groupIcon, "house.fill")
        XCTAssertEqual(group.groupType, .home)
    }
    
    func testGroupEquatableAndHashable() {
        let date = Date()
        let group1 = ExpenseGroup(id: "1", name: "G1", memberIds: [], createdByUserId: "u1", createdAt: date, groupIcon: "", groupType: .other)
        let group1Duplicate = ExpenseGroup(id: "1", name: "G1_changed", memberIds: ["u1"], createdByUserId: "u2", createdAt: date, groupIcon: "icon", groupType: .home)
        let group2 = ExpenseGroup(id: "2", name: "G1", memberIds: [], createdByUserId: "u1", createdAt: date, groupIcon: "", groupType: .other)
        
        XCTAssertEqual(group1, group1Duplicate)
        XCTAssertNotEqual(group1, group2)
        
        var set = Set<ExpenseGroup>()
        set.insert(group1)
        XCTAssertTrue(set.contains(group1Duplicate))
        XCTAssertFalse(set.contains(group2))
    }

    func testGroupTypeProperties() {
        XCTAssertEqual(GroupType.home.icon, "house.fill")
        XCTAssertEqual(GroupType.home.color, "blue")
        
        XCTAssertEqual(GroupType.trip.icon, "airplane")
        XCTAssertEqual(GroupType.trip.color, "orange")
        
        XCTAssertEqual(GroupType.office.icon, "building.2.fill")
        XCTAssertEqual(GroupType.office.color, "purple")
        
        XCTAssertEqual(GroupType.couple.icon, "heart.fill")
        XCTAssertEqual(GroupType.couple.color, "pink")
        
        XCTAssertEqual(GroupType.other.icon, "folder.fill")
        XCTAssertEqual(GroupType.other.color, "gray")
    }
}
