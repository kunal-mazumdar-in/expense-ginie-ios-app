import XCTest
@testable import ExpenseGinie

/// Tests for BillerMapping.categorize() - Category detection from merchant names
/// Test data is loaded from TestData/CategoryDetectionTestData.json
final class CategoryDetectionTests: XCTestCase {
    
    var testData: CategoryTestData!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        testData = try TestDataLoader.loadCategoryTestData()
    }
    
    // MARK: - Category Detection Tests
    
    /// Test all category detection cases
    func testAllCategoryDetection() throws {
        var passed = 0
        var failed = 0
        var failures: [String] = []
        
        for testCase in testData.testCases {
            let detectedCategory = BillerMapping.categorize(testCase.input)
            
            if detectedCategory == testCase.expectedCategory {
                passed += 1
            } else {
                failed += 1
                failures.append("[\(testCase.id)] \(testCase.name): expected '\(testCase.expectedCategory)', got '\(detectedCategory)'")
            }
        }
        
        // Print summary
        print("\n=== Category Detection Test Results ===")
        print("Passed: \(passed)/\(testData.testCases.count)")
        print("Failed: \(failed)/\(testData.testCases.count)")
        
        if !failures.isEmpty {
            print("\nFailures:")
            for failure in failures {
                print("  - \(failure)")
            }
        }
        
        // Assert all passed
        XCTAssertEqual(failed, 0, "\(failed) category detection tests failed")
    }
    
    // MARK: - OTT Category Tests
    
    /// Specific tests for OTT category detection
    func testOTTCategoryDetection() throws {
        let ottTestCases = testData.testCases.filter { $0.expectedCategory == "OTT" }
        
        for testCase in ottTestCases {
            let detectedCategory = BillerMapping.categorize(testCase.input)
            XCTAssertEqual(
                detectedCategory,
                "OTT",
                "[\(testCase.id)] \(testCase.name): OTT detection failed - got '\(detectedCategory)'"
            )
        }
    }
    
    // MARK: - Food Category Tests
    
    /// Specific tests for Food & Dining category detection
    func testFoodCategoryDetection() throws {
        let foodTestCases = testData.testCases.filter { $0.expectedCategory == "Food & Dining" }
        
        for testCase in foodTestCases {
            let detectedCategory = BillerMapping.categorize(testCase.input)
            XCTAssertEqual(
                detectedCategory,
                "Food & Dining",
                "[\(testCase.id)] \(testCase.name): Food detection failed - got '\(detectedCategory)'"
            )
        }
    }
    
    // MARK: - Transport Category Tests
    
    /// Specific tests for Transport & Fuel category detection
    func testTransportCategoryDetection() throws {
        let transportTestCases = testData.testCases.filter { $0.expectedCategory == "Transport & Fuel" }
        
        for testCase in transportTestCases {
            let detectedCategory = BillerMapping.categorize(testCase.input)
            XCTAssertEqual(
                detectedCategory,
                "Transport & Fuel",
                "[\(testCase.id)] \(testCase.name): Transport detection failed - got '\(detectedCategory)'"
            )
        }
    }
    
    // MARK: - Shopping Category Tests
    
    /// Specific tests for Shopping category detection
    func testShoppingCategoryDetection() throws {
        let shoppingTestCases = testData.testCases.filter { $0.expectedCategory == "Shopping" }
        
        for testCase in shoppingTestCases {
            let detectedCategory = BillerMapping.categorize(testCase.input)
            XCTAssertEqual(
                detectedCategory,
                "Shopping",
                "[\(testCase.id)] \(testCase.name): Shopping detection failed - got '\(detectedCategory)'"
            )
        }
    }
    
    // MARK: - Unknown/Other Category Tests
    
    /// Test that unknown merchants default to "Other"
    func testUnknownCategoryDetection() throws {
        let unknownTestCases = testData.testCases.filter { $0.expectedCategory == "Other" }
        
        for testCase in unknownTestCases {
            let detectedCategory = BillerMapping.categorize(testCase.input)
            XCTAssertEqual(
                detectedCategory,
                "Other",
                "[\(testCase.id)] \(testCase.name): Should be 'Other' but got '\(detectedCategory)'"
            )
        }
    }
    
    // MARK: - Individual Test Case (for debugging)
    
    /// Run specific test case by ID for debugging
    func testSpecificCategoryCase() throws {
        let targetID = "CAT-003" // Change this to debug specific case
        
        guard let testCase = testData.testCases.first(where: { $0.id == targetID }) else {
            XCTFail("Test case \(targetID) not found")
            return
        }
        
        let detectedCategory = BillerMapping.categorize(testCase.input)
        
        print("=== Test Case: \(testCase.id) - \(testCase.name) ===")
        print("Input: \(testCase.input)")
        print("Expected Category: \(testCase.expectedCategory)")
        print("Detected Category: \(detectedCategory)")
        
        XCTAssertEqual(detectedCategory, testCase.expectedCategory)
    }
    
    // MARK: - Coverage Report
    
    /// Generate coverage report for all categories
    func testCategoryDistribution() throws {
        var categoryCount: [String: Int] = [:]
        
        for testCase in testData.testCases {
            categoryCount[testCase.expectedCategory, default: 0] += 1
        }
        
        print("\n=== Category Test Coverage ===")
        for (category, count) in categoryCount.sorted(by: { $0.key < $1.key }) {
            print("\(category): \(count) test cases")
        }
        print("Total: \(testData.testCases.count) test cases")
    }
}
