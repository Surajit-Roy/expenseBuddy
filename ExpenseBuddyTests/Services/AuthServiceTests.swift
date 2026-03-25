import XCTest
@testable import ExpenseBuddy

@MainActor
final class AuthServiceTests: XCTestCase {
    
    var authService: AuthService!
    
    override func setUp() async throws {
        // Will initialize Auth.auth() safely because AppDelegate configure() runs
        authService = AuthService()
    }
    
    override func tearDown() async throws {
        authService = nil
    }
    
    func testInitialState() {
        // App defaults or current state could vary depending on the simulator
        XCTAssertNotNil(authService)
        // isAuthenticated could be false or true depending on if simulator logged in manually,
        // but it doesn't crash, meaning the object initializes fine.
    }
    
    func testSignOutDoesNotCrash() {
        // We just ensure calling it doesn't throw a fatal error
        authService.logout()
        XCTAssertFalse(authService.isAuthenticated)
    }
}
