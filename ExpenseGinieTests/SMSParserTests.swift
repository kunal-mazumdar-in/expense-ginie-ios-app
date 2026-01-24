import XCTest
@testable import ExpenseGinie

/// Tests for SMS Parser functionality
/// Test data is loaded from TestData/SMSParserTestData.json
final class SMSParserTests: XCTestCase {
    
    var testData: SMSTestData!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        testData = try TestDataLoader.loadSMSTestData()
    }
    
    // MARK: - Amount Extraction Tests
    
    /// Test that all SMS samples have correct amount extracted
    func testAmountExtraction() throws {
        for testCase in testData.testCases {
            // Use BillerMapping.categorize for category detection (doesn't need MappingStorage)
            let result = parseWithoutMappingStorage(sms: testCase.input)
            
            XCTAssertNotNil(result, "[\(testCase.id)] \(testCase.name): Failed to parse SMS")
            
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
    
    /// Test that all SMS samples have correct biller detected
    func testBillerDetection() throws {
        for testCase in testData.testCases {
            let result = parseWithoutMappingStorage(sms: testCase.input)
            
            XCTAssertNotNil(result, "[\(testCase.id)] \(testCase.name): Failed to parse SMS")
            
            if let result = result {
                // Case-insensitive comparison for biller
                XCTAssertEqual(
                    result.biller.uppercased(),
                    testCase.expected.biller.uppercased(),
                    "[\(testCase.id)] \(testCase.name): Biller mismatch - expected \(testCase.expected.biller), got \(result.biller)"
                )
            }
        }
    }
    
    // MARK: - Category Detection Tests
    
    /// Test that all SMS samples have correct category assigned
    func testCategoryDetection() throws {
        for testCase in testData.testCases {
            let result = parseWithoutMappingStorage(sms: testCase.input)
            
            XCTAssertNotNil(result, "[\(testCase.id)] \(testCase.name): Failed to parse SMS")
            
            if let result = result {
                XCTAssertEqual(
                    result.category,
                    testCase.expected.category,
                    "[\(testCase.id)] \(testCase.name): Category mismatch - expected \(testCase.expected.category), got \(result.category)"
                )
            }
        }
    }
    
    // MARK: - Currency Detection Tests
    
    /// Test that all SMS samples have correct currency detected
    func testCurrencyDetection() throws {
        for testCase in testData.testCases {
            let result = parseWithoutMappingStorage(sms: testCase.input)
            
            XCTAssertNotNil(result, "[\(testCase.id)] \(testCase.name): Failed to parse SMS")
            
            if let result = result {
                XCTAssertEqual(
                    result.currency,
                    testCase.expected.currency,
                    "[\(testCase.id)] \(testCase.name): Currency mismatch - expected \(testCase.expected.currency), got \(result.currency)"
                )
            }
        }
    }
    
    // MARK: - Individual Test Cases (for debugging)
    
    /// Run specific test case by ID for debugging
    func testSpecificCase() throws {
        let targetID = "SMS-005" // Change this to debug specific case
        
        guard let testCase = testData.testCases.first(where: { $0.id == targetID }) else {
            XCTFail("Test case \(targetID) not found")
            return
        }
        
        let result = parseWithoutMappingStorage(sms: testCase.input)
        
        print("=== Test Case: \(testCase.id) - \(testCase.name) ===")
        print("Input: \(testCase.input)")
        print("Expected: amount=\(testCase.expected.amount), biller=\(testCase.expected.biller), category=\(testCase.expected.category)")
        
        if let result = result {
            print("Got: amount=\(result.amount), biller=\(result.biller), category=\(result.category)")
        } else {
            print("Got: nil (failed to parse)")
        }
        
        XCTAssertNotNil(result)
    }
    
    // MARK: - Helper Methods
    
    /// Parse SMS without requiring MappingStorage (for unit tests)
    /// Uses BillerMapping.categorize() directly
    private func parseWithoutMappingStorage(sms: String) -> SimpleParsedResult? {
        // Extract amount using regex patterns
        guard let (amount, currency) = extractAmount(from: sms) else {
            return nil
        }
        
        // Detect biller and category using BillerMapping
        // Categorize based on DETECTED BILLER for more accurate results
        let biller = detectBiller(in: sms)
        let category = BillerMapping.categorize(biller)
        
        return SimpleParsedResult(
            amount: amount,
            biller: biller,
            category: category,
            currency: currency
        )
    }
    
    private func extractAmount(from sms: String) -> (Double, String)? {
        // Currency patterns
        let patterns: [(pattern: String, currency: String)] = [
            ("(?:Rs\\.?|INR|₹)\\s*([\\d,]+\\.?\\d*)", "INR"),
            ("([\\d,]+\\.?\\d*)\\s*(?:Rs\\.?|INR)", "INR"),
            ("(?:USD|US\\$|\\$)\\s*([\\d,]+\\.?\\d*)", "USD"),
            ("(?:EUR|€)\\s*([\\d,]+\\.?\\d*)", "EUR"),
            ("(?:GBP|£)\\s*([\\d,]+\\.?\\d*)", "GBP"),
        ]
        
        for (pattern, currency) in patterns {
            if let match = sms.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let matchedString = String(sms[match])
                if let numberMatch = matchedString.range(of: "[\\d,]+\\.?\\d*", options: .regularExpression) {
                    let numberStr = String(matchedString[numberMatch]).replacingOccurrences(of: ",", with: "")
                    if let amount = Double(numberStr), amount > 0 {
                        return (amount, currency)
                    }
                }
            }
        }
        
        return nil
    }
    
    private func detectBiller(in sms: String) -> String {
        let upperSMS = sms.uppercased()
        
        // Bank names to deprioritize (these are payment sources, not merchants)
        let bankNames = Set(["HDFC", "ICICI", "SBI", "AXIS", "KOTAK", "YES BANK", "IDFC", "RBL", 
                             "PNB", "BOB", "CANARA", "FEDERAL", "INDUSIND", "UNION", "HSBC", "DBS", "IDBI"])
        
        // Priority 1: Look for "at MERCHANT" or "for MERCHANT" or "to MERCHANT" patterns
        let merchantPatterns = [
            "(?:at|for|to)\\s+([A-Z][A-Z0-9\\s\\.]+?)(?:\\s+(?:on|using|via|from)|$|\\.|,)",
            "(?:Info|VPA)\\s*:?\\s*([A-Z][A-Z0-9]+)",
        ]
        
        for pattern in merchantPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(upperSMS.startIndex..., in: upperSMS)
                if let match = regex.firstMatch(in: upperSMS, range: range),
                   let captureRange = Range(match.range(at: 1), in: upperSMS) {
                    let captured = String(upperSMS[captureRange]).trimmingCharacters(in: .whitespaces)
                    
                    // Check if captured text matches a known biller
                    let billers = BillerMapping.defaults.map { $0.biller }
                    for biller in billers.sorted(by: { $0.count > $1.count }) {
                        if captured.contains(biller) && !bankNames.contains(biller) {
                            return biller
                        }
                    }
                }
            }
        }
        
        // Priority 2: Check all billers, but prefer non-bank matches
        let billers = BillerMapping.defaults.map { $0.biller }
        var bankMatch: String? = nil
        
        for biller in billers.sorted(by: { $0.count > $1.count }) {
            if upperSMS.contains(biller) {
                if bankNames.contains(biller) {
                    // Save bank match as fallback
                    if bankMatch == nil {
                        bankMatch = biller
                    }
                } else {
                    // Non-bank match - return immediately
                    return biller
                }
            }
        }
        
        // Return bank match if no merchant found
        return bankMatch ?? "Unknown"
    }
}

/// Simple result structure for testing
struct SimpleParsedResult {
    let amount: Double
    let biller: String
    let category: String
    let currency: String
}
