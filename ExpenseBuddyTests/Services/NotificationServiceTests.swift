import XCTest
@testable import ExpenseBuddy

@MainActor
final class NotificationServiceTests: XCTestCase {
    
    var notificationService: NotificationService!
    
    override func setUp() async throws {
        notificationService = NotificationService()
    }
    
    override func tearDown() async throws {
        notificationService = nil
    }
    
    func testInitialState() {
        XCTAssertNotNil(notificationService)
        XCTAssertNil(notificationService.latestNotification)
        XCTAssertNil(notificationService.pendingExpenseId)
        // Permissions are async evaluated, won't be true by default in tests
        XCTAssertFalse(notificationService.isPermissionGranted)
    }
    
    func testNavigateToExpense() {
        notificationService.navigateToExpense("exp123")
        XCTAssertEqual(notificationService.pendingExpenseId, "exp123")
        
        notificationService.clearPendingNavigation()
        XCTAssertNil(notificationService.pendingExpenseId)
    }
    
    func testInAppBannerPublish() {
        notificationService.publishInAppNotification(title: "Alert", body: "Test body", expenseId: "e999")
        
        XCTAssertNotNil(notificationService.latestNotification)
        XCTAssertEqual(notificationService.latestNotification?.title, "Alert")
        XCTAssertEqual(notificationService.latestNotification?.body, "Test body")
        XCTAssertEqual(notificationService.latestNotification?.expenseId, "e999")
        
        notificationService.dismissBanner()
        XCTAssertNil(notificationService.latestNotification)
    }
}
