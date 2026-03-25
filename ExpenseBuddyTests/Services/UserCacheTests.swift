import XCTest
@testable import ExpenseBuddy

@MainActor
final class UserCacheTests: XCTestCase {
    
    var userCache: UserCache!
    
    override func setUp() {
        super.setUp()
        userCache = UserCache()
    }
    
    override func tearDown() {
        userCache.clearCache()
        userCache = nil
        super.tearDown()
    }
    
    func testSeedAndRetrieveUser() {
        let u1 = User(id: "u1", name: "Alice", email: "alice@test.com", profileImage: "", createdAt: Date())
        
        XCTAssertNil(userCache.user(for: "u1"))
        
        userCache.seed(u1)
        
        XCTAssertNotNil(userCache.user(for: "u1"))
        XCTAssertEqual(userCache.name(for: "u1"), "Alice")
    }
    
    func testSeedMultipleUsers() {
        let u1 = User(id: "u1", name: "Alice", email: "alice@test.com", profileImage: "", createdAt: Date())
        let u2 = User(id: "u2", name: "Bob", email: "bob@test.com", profileImage: "", createdAt: Date())
        
        userCache.seed([u1, u2])
        
        XCTAssertEqual(userCache.name(for: "u2"), "Bob")
        
        let users = userCache.users(for: ["u1", "u2", "u3"])
        XCTAssertEqual(users.count, 2)
    }
    
    func testUserOrPlaceholder() {
        let placeholder = userCache.userOrPlaceholder(for: "unknown")
        XCTAssertEqual(placeholder.name, "User")
        XCTAssertEqual(placeholder.id, "unknown")
    }
    
    func testClearCache() {
        let u1 = User(id: "u1", name: "Alice", email: "alice@test.com", profileImage: "", createdAt: Date())
        userCache.seed(u1)
        XCTAssertNotNil(userCache.user(for: "u1"))
        
        userCache.clearCache()
        XCTAssertNil(userCache.user(for: "u1"))
    }
}
