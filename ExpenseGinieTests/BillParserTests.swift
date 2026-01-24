import XCTest
@testable import ExpenseGinie

/// Tests for Bill/Receipt Parser functionality
/// Test data is loaded from TestData/BillParserTestData.json
final class BillParserTests: XCTestCase {
    
    var testData: BillTestData!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        testData = try TestDataLoader.loadBillTestData()
    }
    
    // MARK: - Amount Extraction Tests
    
    /// Test that all bill samples have correct amount extracted
    func testAmountExtraction() throws {
        for testCase in testData.testCases {
            let result = parseBill(text: testCase.input)
            
            XCTAssertNotNil(result, "[\(testCase.id)] \(testCase.name): Failed to parse bill")
            
            if let result = result {
                XCTAssertEqual(
                    result.amount,
                    testCase.expected.amount,
                    accuracy: 0.01,
                    "[\(testCase.id)] \(testCase.name): Amount mismatch - expected \(testCase.expected.amount), got \(result.amount)"
                )
            }
        }
    }
    
    // MARK: - Biller Detection Tests
    
    /// Test that all bill samples have correct biller/merchant detected
    func testBillerDetection() throws {
        for testCase in testData.testCases {
            let result = parseBill(text: testCase.input)
            
            XCTAssertNotNil(result, "[\(testCase.id)] \(testCase.name): Failed to parse bill")
            
            if let result = result {
                // Check if expected biller is contained in detected biller (case-insensitive)
                let billerMatch = result.biller.uppercased().contains(testCase.expected.biller.uppercased()) ||
                                  testCase.expected.biller.uppercased().contains(result.biller.uppercased())
                
                XCTAssertTrue(
                    billerMatch,
                    "[\(testCase.id)] \(testCase.name): Biller mismatch - expected \(testCase.expected.biller), got \(result.biller)"
                )
            }
        }
    }
    
    // MARK: - Category Detection Tests
    
    /// Test that all bill samples have correct category assigned
    func testCategoryDetection() throws {
        for testCase in testData.testCases {
            let result = parseBill(text: testCase.input)
            
            XCTAssertNotNil(result, "[\(testCase.id)] \(testCase.name): Failed to parse bill")
            
            if let result = result {
                XCTAssertEqual(
                    result.category,
                    testCase.expected.category,
                    "[\(testCase.id)] \(testCase.name): Category mismatch - expected \(testCase.expected.category), got \(result.category)"
                )
            }
        }
    }
    
    // MARK: - Individual Test Cases (for debugging)
    
    /// Run specific test case by ID for debugging
    func testSpecificBillCase() throws {
        let targetID = "BILL-001" // Change this to debug specific case
        
        guard let testCase = testData.testCases.first(where: { $0.id == targetID }) else {
            XCTFail("Test case \(targetID) not found")
            return
        }
        
        let result = parseBill(text: testCase.input)
        
        print("=== Test Case: \(testCase.id) - \(testCase.name) ===")
        print("Input:\n\(testCase.input)")
        print("\nExpected: amount=\(testCase.expected.amount), biller=\(testCase.expected.biller), category=\(testCase.expected.category)")
        
        if let result = result {
            print("Got: amount=\(result.amount), biller=\(result.biller), category=\(result.category)")
        } else {
            print("Got: nil (failed to parse)")
        }
        
        XCTAssertNotNil(result)
    }
    
    // MARK: - Helper Methods
    
    /// Parse bill text and extract expense details
    private func parseBill(text: String) -> BillParsedResult? {
        // Extract amount
        guard let (amount, currency) = extractBillAmount(from: text) else {
            return nil
        }
        
        // Detect biller
        let biller = detectBillerFromBill(text: text)
        
        // Get category based on DETECTED BILLER (not whole text)
        // This is more accurate for payment screenshots where transaction IDs may contain other keywords
        let category = BillerMapping.categorize(biller)
        
        return BillParsedResult(
            amount: amount,
            biller: biller,
            category: category,
            currency: currency
        )
    }
    
    private func extractBillAmount(from text: String) -> (Double, String)? {
        // Strategy: Look for labeled amounts first, then fall back to largest amount
        
        // Priority 1: Explicitly labeled totals (Grand Total, Total, Amount, To Pay)
        let labeledPatterns: [(pattern: String, priority: Int)] = [
            // Grand Total - highest priority
            ("grand\\s*total\\s*:?\\s*(?:₹|rs\\.?)?\\s*([\\d,]+\\.\\d{2})", 100),
            
            // To Pay / Net Payable
            ("(?:to\\s*pay|net\\s*payable)\\s*:?\\s*(?:₹|rs\\.?)?\\s*([\\d,]+\\.\\d{2})", 90),
            
            // Total (but not Subtotal) - check context
            ("(?:^|\\n)\\s*total\\s*:?\\s*(?:₹|rs\\.?)?\\s*([\\d,]+\\.\\d{2})", 80),
            
            // "Amount:" on its own (common in fuel receipts)
            ("(?:^|\\n)\\s*amount\\s*:?\\s*(?:₹|rs\\.?)?\\s*([\\d,]+\\.\\d{2})", 70),
        ]
        
        var bestMatch: (amount: Double, priority: Int)? = nil
        
        for (pattern, priority) in labeledPatterns {
            if let match = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let matchedString = String(text[match])
                if let numberMatch = matchedString.range(of: "[\\d,]+\\.\\d{2}", options: .regularExpression) {
                    let numberStr = String(matchedString[numberMatch]).replacingOccurrences(of: ",", with: "")
                    if let amount = Double(numberStr), amount > 0 {
                        if bestMatch == nil || priority > bestMatch!.priority {
                            bestMatch = (amount, priority)
                        }
                    }
                }
            }
        }
        
        if let match = bestMatch {
            return (match.amount, "INR")
        }
        
        // Priority 2: Payment screenshot patterns (₹XXX standalone)
        let paymentPatterns = [
            "(?:paid|sent)\\s+(?:to)?[^\\d₹]*(?:₹)\\s*([\\d,]+\\.?\\d*)",
            "\\n\\s*₹\\s*([\\d,]+\\.\\d{2})\\s*\\n",
        ]
        
        for pattern in paymentPatterns {
            if let match = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let matchedString = String(text[match])
                if let numberMatch = matchedString.range(of: "[\\d,]+\\.?\\d*", options: .regularExpression) {
                    let numberStr = String(matchedString[numberMatch]).replacingOccurrences(of: ",", with: "")
                    if let amount = Double(numberStr), amount > 0 {
                        return (amount, "INR")
                    }
                }
            }
        }
        
        // Priority 3: Find the LARGEST amount in the text (totals are usually the biggest number)
        // This handles most receipts where the total is the largest value
        if let amount = findLargestAmount(in: text) {
            return (amount, "INR")
        }
        
        return nil
    }
    
    private func findLargestAmount(in text: String) -> Double? {
        let pattern = "([\\d,]+\\.\\d{2})"
        var amounts: [Double] = []
        
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(text.startIndex..., in: text)
        
        regex?.enumerateMatches(in: text, range: range) { match, _, _ in
            if let match = match, let matchRange = Range(match.range(at: 1), in: text) {
                let numberStr = String(text[matchRange]).replacingOccurrences(of: ",", with: "")
                if let amount = Double(numberStr), amount > 0 {
                    amounts.append(amount)
                }
            }
        }
        
        return amounts.filter { $0 > 1 }.max()
    }
    
    private func detectBillerFromBill(text: String) -> String {
        // Priority 1: Look for explicit "Sent to X" / "Paid to X" / "To: X" patterns
        // These explicitly indicate the recipient in payment screenshots
        let paymentPatterns = [
            "(?:sent|paid)\\s+to\\s+([A-Za-z0-9]+)",  // "Sent to UBER"
            "(?:^|\\n)\\s*to\\s*:\\s*([A-Za-z0-9\\s]+?)\\s*(?:\\n|$)",  // "To: Amazon Pay"
            "(?:^|\\n)\\s*from\\s*:\\s*([A-Za-z0-9\\s]+?)\\s*(?:\\n|$)",  // "From: Merchant"
        ]
        
        for pattern in paymentPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, range: range),
                   let captureRange = Range(match.range(at: 1), in: text) {
                    let captured = String(text[captureRange]).trimmingCharacters(in: .whitespaces)
                    if !captured.isEmpty && captured.count >= 2 {
                        // Check if this matches a known biller for proper casing
                        // Sort by length descending so "AMAZON PAY" matches before "AMAZON"
                        let billers = BillerMapping.defaults.map { $0.biller }.sorted { $0.count > $1.count }
                        for biller in billers {
                            if captured.uppercased().contains(biller) || biller.contains(captured.uppercased()) {
                                return biller
                            }
                        }
                        return captured.uppercased()
                    }
                }
            }
        }
        
        // Priority 2: Check known billers (sorted by length - longer first)
        let billers = BillerMapping.defaults.map { $0.biller }
        for biller in billers.sorted(by: { $0.count > $1.count }) {
            if text.uppercased().contains(biller) {
                return biller
            }
        }
        
        // Priority 3: First line that looks like a merchant name
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && $0.count >= 3 }
        
        for line in lines {
            let lower = line.lowercased()
            if !line.allSatisfy({ $0.isNumber || $0 == "." || $0 == "," || $0 == "/" || $0 == "-" }) &&
               !lower.hasPrefix("total") &&
               !lower.hasPrefix("amount") &&
               !lower.hasPrefix("date") &&
               !lower.hasPrefix("payment") &&
               !lower.contains("transaction id") {
                return String(line.prefix(30))
            }
        }
        
        return "Unknown"
    }
}

/// Result structure for bill parsing tests
struct BillParsedResult {
    let amount: Double
    let biller: String
    let category: String
    let currency: String
}
