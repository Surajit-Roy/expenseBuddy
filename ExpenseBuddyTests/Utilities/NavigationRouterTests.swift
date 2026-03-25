import XCTest
import SwiftUI
@testable import ExpenseBuddy

final class NavigationRouterTests: XCTestCase {

    func testNavigationRouterInitialization() {
        let router = NavigationRouter()
        
        XCTAssertTrue(router.friendsPath.isEmpty)
        XCTAssertTrue(router.groupsPath.isEmpty)
        XCTAssertTrue(router.activityPath.isEmpty)
        XCTAssertTrue(router.profilePath.isEmpty)
    }
    
    func testNavigationRouterIsRoot() {
        let router = NavigationRouter()
        
        XCTAssertTrue(router.isRoot(for: 0))
        XCTAssertTrue(router.isRoot(for: 1))
        XCTAssertTrue(router.isRoot(for: 2))
        XCTAssertTrue(router.isRoot(for: 3))
        
        // Any unknown tab id returns true by default
        XCTAssertTrue(router.isRoot(for: 99))
        
        // Push something to friendsPath
        router.friendsPath.append("SomeView")
        XCTAssertFalse(router.isRoot(for: 0))
    }
}
