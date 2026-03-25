import XCTest
@testable import ExpenseBuddy

@MainActor
final class AuthViewModelTests: XCTestCase {

    var authService: AuthService!
    var viewModel: AuthViewModel!
    
    override func setUp() {
        super.setUp()
        authService = AuthService()
        viewModel = AuthViewModel(authService: authService)
    }
    
    override func tearDown() {
        viewModel = nil
        authService = nil
        super.tearDown()
    }
    
    // MARK: - Sign Up Validation Tests
    func testIsSignUpValid() {
        // Initially invalid
        XCTAssertFalse(viewModel.isSignUpValid)
        
        // Fill out valid data
        viewModel.name = "John Doe"
        viewModel.email = "test@example.com"
        viewModel.mobileNumber = "1234567890"
        viewModel.password = "Password123!"
        viewModel.confirmPassword = "Password123!"
        viewModel.hasAcceptedTerms = true
        
        XCTAssertTrue(viewModel.isSignUpValid)
    }
    
    func testSignUpInvalidEmail() {
        viewModel.name = "John Doe"
        viewModel.email = "invalidemail"
        viewModel.mobileNumber = "1234567890"
        viewModel.password = "Password123!"
        viewModel.confirmPassword = "Password123!"
        viewModel.hasAcceptedTerms = true
        
        XCTAssertFalse(viewModel.isSignUpValid)
    }
    
    func testSignUpPasswordMismatch() {
        viewModel.name = "John Doe"
        viewModel.email = "test@example.com"
        viewModel.mobileNumber = "1234567890"
        viewModel.password = "Password123!"
        viewModel.confirmPassword = "DifferentPassword123!"
        viewModel.hasAcceptedTerms = true
        
        XCTAssertFalse(viewModel.isSignUpValid)
    }
    
    func testSignUpTermsNotAccepted() {
        viewModel.name = "John Doe"
        viewModel.email = "test@example.com"
        viewModel.mobileNumber = "1234567890"
        viewModel.password = "Password123!"
        viewModel.confirmPassword = "Password123!"
        viewModel.hasAcceptedTerms = false
        
        XCTAssertFalse(viewModel.isSignUpValid)
    }
    
    // MARK: - Login Validation Tests
    func testIsLoginValid() {
        // Initially invalid
        XCTAssertFalse(viewModel.isLoginValid)
        
        viewModel.email = "test@example.com"
        viewModel.password = "Password123!"
        
        XCTAssertTrue(viewModel.isLoginValid)
    }
    
    func testLoginMissingFields() {
        viewModel.email = ""
        viewModel.password = "Password123!"
        XCTAssertFalse(viewModel.isLoginValid)
        
        viewModel.email = "test@example.com"
        viewModel.password = ""
        XCTAssertFalse(viewModel.isLoginValid)
    }
    
    // MARK: - Clear Fields
    func testClearFields() {
        viewModel.email = "test@example.com"
        viewModel.password = "pass"
        viewModel.confirmPassword = "pass"
        viewModel.name = "John"
        viewModel.errorMessage = "Some error"
        
        viewModel.clearFields()
        
        XCTAssertTrue(viewModel.email.isEmpty)
        XCTAssertTrue(viewModel.password.isEmpty)
        XCTAssertTrue(viewModel.confirmPassword.isEmpty)
        XCTAssertTrue(viewModel.name.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
    }
}
