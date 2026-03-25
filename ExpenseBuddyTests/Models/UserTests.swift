import XCTest
@testable import ExpenseBuddy

final class UserTests: XCTestCase {

    func testUserInitialization() {
        let date = Date()
        let user = User(
            id: "u_1",
            name: "John Doe",
            email: "john@example.com",
            mobileNumber: "1234567890",
            profileImage: "john_pic.jpg",
            fcmToken: "token_123",
            hasAcceptedTerms: true,
            createdAt: date
        )
        
        XCTAssertEqual(user.id, "u_1")
        XCTAssertEqual(user.name, "John Doe")
        XCTAssertEqual(user.email, "john@example.com")
        XCTAssertEqual(user.mobileNumber, "1234567890")
        XCTAssertEqual(user.profileImage, "john_pic.jpg")
        XCTAssertEqual(user.fcmToken, "token_123")
        XCTAssertTrue(user.hasAcceptedTerms)
        XCTAssertEqual(user.createdAt, date)
    }
    
    func testUserInitials() {
        let user1 = User(id: "1", name: "John Doe", email: "j@j.com", profileImage: "")
        XCTAssertEqual(user1.initials, "JD")
        
        let user2 = User(id: "2", name: "SingleName", email: "s@s.com", profileImage: "")
        XCTAssertEqual(user2.initials, "S")
        
        let user3 = User(id: "3", name: "Mary Jane Watson", email: "m@m.com", profileImage: "")
        XCTAssertEqual(user3.initials, "MW") // split by space, first and last
        
        let user4 = User(id: "4", name: "", email: "e@e.com", profileImage: "")
        XCTAssertEqual(user4.initials, "")
    }

    func testUserDecodingAllFields() throws {
        let json = """
        {
            "id": "1",
            "name": "Alice",
            "email": "alice@a.com",
            "mobileNumber": "5551234",
            "profileImage": "alice.png",
            "fcmToken": "fcm_token",
            "hasAcceptedTerms": true,
            "createdAt": 1700000000
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let user = try decoder.decode(User.self, from: data)
        
        XCTAssertEqual(user.id, "1")
        XCTAssertEqual(user.name, "Alice")
        XCTAssertEqual(user.email, "alice@a.com")
        XCTAssertEqual(user.mobileNumber, "5551234")
        XCTAssertEqual(user.profileImage, "alice.png")
        XCTAssertEqual(user.fcmToken, "fcm_token")
        XCTAssertTrue(user.hasAcceptedTerms)
        XCTAssertEqual(user.createdAt, Date(timeIntervalSince1970: 1700000000))
    }
    
    func testUserDecodingMissingOptionalFields() throws {
        let json = """
        {
            "id": "2",
            "name": "Bob",
            "email": "bob@b.com"
        }
        """
        // Omitting mobileNumber, profileImage, fcmToken, hasAcceptedTerms, createdAt
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let user = try decoder.decode(User.self, from: data)
        
        XCTAssertEqual(user.id, "2")
        XCTAssertEqual(user.name, "Bob")
        XCTAssertEqual(user.email, "bob@b.com")
        XCTAssertNil(user.mobileNumber)
        XCTAssertEqual(user.profileImage, "person.circle.fill") // default
        XCTAssertNil(user.fcmToken)
        XCTAssertFalse(user.hasAcceptedTerms) // default
    }

    func testUserEquatableAndHashable() {
        let date = Date()
        let user1 = User(id: "1", name: "Alice", email: "a@a.com", mobileNumber: "1", profileImage: "a.jpg", fcmToken: "token", hasAcceptedTerms: true, createdAt: date)
        let user1Exact = User(id: "1", name: "Alice", email: "a@a.com", mobileNumber: "1", profileImage: "a.jpg", fcmToken: "token", hasAcceptedTerms: true, createdAt: date)
        let user2 = User(id: "2", name: "Alice", email: "a@a.com", mobileNumber: "1", profileImage: "a.jpg", fcmToken: "token", hasAcceptedTerms: true, createdAt: date)
        
        XCTAssertEqual(user1, user1Exact)
        XCTAssertNotEqual(user1, user2) // Different ID
        
        var set = Set<User>()
        set.insert(user1)
        XCTAssertTrue(set.contains(user1Exact))
        XCTAssertFalse(set.contains(user2))
    }
}
