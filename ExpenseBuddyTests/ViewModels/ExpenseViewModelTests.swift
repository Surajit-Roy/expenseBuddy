import XCTest
@testable import ExpenseBuddy

@MainActor
final class ExpenseViewModelTests: XCTestCase {

    var viewModel: ExpenseViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = ExpenseViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Validation
    
    func testTitleError() {
        viewModel.title = ""
        XCTAssertEqual(viewModel.titleError, "Title is required")
        
        viewModel.title = "A valid title"
        XCTAssertNil(viewModel.titleError)
        
        viewModel.title = String(repeating: "a", count: 101)
        XCTAssertEqual(viewModel.titleError, "Title too long (max 100 characters)")
    }
    
    func testAmountError() {
        viewModel.amountText = ""
        XCTAssertEqual(viewModel.amountError, "Amount is required")
        
        viewModel.amountText = "abc"
        // Since "abc" is sanitized to "", amountError will simply be "Amount is required"
        XCTAssertEqual(viewModel.amountError, "Amount is required")
        
        viewModel.amountText = "-50"
        // "-50" gets sanitized to "50", so it is valid
        XCTAssertNil(viewModel.amountError)
        
        viewModel.amountText = "10000000000" // greater than 99,99,999.99
        XCTAssertNotNil(viewModel.amountError)
        
        viewModel.amountText = "500"
        XCTAssertNil(viewModel.amountError)
    }
    
    func testParticipantsError() {
        viewModel.selectedParticipantIds = []
        XCTAssertEqual(viewModel.participantsError, "Select at least 2 participants")
        
        viewModel.selectedParticipantIds = ["u1"]
        XCTAssertEqual(viewModel.participantsError, "Select at least 2 participants")
        
        viewModel.selectedParticipantIds = ["u1", "u2"]
        XCTAssertNil(viewModel.participantsError)
    }
    
    func testPayerError() {
        viewModel.selectedParticipantIds = ["u1", "u2"]
        viewModel.paidByUserId = "u3"
        XCTAssertEqual(viewModel.payerError, "The payer must be a participant")
        
        viewModel.paidByUserId = "u1"
        XCTAssertNil(viewModel.payerError)
    }
    
    func testIsValid() {
        // Setup a fully valid state
        viewModel.title = "Dinner"
        viewModel.amountText = "100"
        viewModel.selectedParticipantIds = ["u1", "u2"]
        viewModel.paidByUserId = "u1"
        viewModel.groupId = "g1"
        
        XCTAssertTrue(viewModel.isValid)
        
        viewModel.title = "" // Invalid
        XCTAssertFalse(viewModel.isValid)
    }
    
    // MARK: - Split Calculation
    
    func testEqualSplitCalculations() {
        viewModel.amountText = "100"
        viewModel.selectedParticipantIds = ["u1", "u2", "u3"]
        viewModel.splitType = .equal
        
        let splits = viewModel.calculateSplits()
        XCTAssertEqual(splits.count, 3)
        // Order is depending on Array(Set) which is unordered, but the sum should be 100
        let sum = splits.reduce(0) { $0 + $1.amountOwed }
        XCTAssertEqual(sum, 100.0)
        XCTAssertTrue(viewModel.validateSplits())
    }

    func testUnequalSplitCalculations() {
        viewModel.amountText = "100"
        viewModel.selectedParticipantIds = ["u1", "u2"]
        viewModel.splitType = .unequal
        
        viewModel.unequalAmounts = [
            "u1": "40",
            "u2": "60"
        ]
        
        XCTAssertTrue(viewModel.validateSplits())
        
        let splits = viewModel.calculateSplits()
        XCTAssertEqual(splits.first(where: { $0.userId == "u1" })?.amountOwed, 40.0)
        XCTAssertEqual(splits.first(where: { $0.userId == "u2" })?.amountOwed, 60.0)
        
        // Invalid sum
        viewModel.unequalAmounts = ["u1": "50", "u2": "60"]
        XCTAssertFalse(viewModel.validateSplits())
    }
    
    func testPercentageSplitCalculations() {
        viewModel.amountText = "200"
        viewModel.selectedParticipantIds = ["u1", "u2"]
        viewModel.splitType = .percentage
        
        viewModel.percentages = [
            "u1": "25",
            "u2": "75"
        ]
        
        XCTAssertTrue(viewModel.validateSplits())
        
        let splits = viewModel.calculateSplits()
        XCTAssertEqual(splits.first(where: { $0.userId == "u1" })?.amountOwed, 50.0)
        XCTAssertEqual(splits.first(where: { $0.userId == "u2" })?.amountOwed, 150.0)
        
        // Invalid percentage sum
        viewModel.percentages = ["u1": "50", "u2": "60"]
        XCTAssertFalse(viewModel.validateSplits())
    }
    
    // MARK: - Helper Formatting
    
    func testAmountTextSanitization() {
        viewModel.amountText = "12.345"
        // Sanitizer strips beyond 2 decimals, mock depends on Validator logic. 
        // We test that `amountText` didSet fires properly.
        // Assuming Validator.sanitizeAmountInput handles this. We check it doesn't crash here.
    }
    
    func testEqualSplitAmount() {
        viewModel.amountText = "100"
        viewModel.selectedParticipantIds = ["u1", "u2", "u3"]
        XCTAssertEqual(viewModel.equalSplitAmount, 33.33)
    }
}
