import Foundation

// MARK: - Test Data Models

/// SMS Parser test case structure
struct SMSTestCase: Codable {
    let id: String
    let name: String
    let input: String
    let expected: SMSExpectedResult
}

struct SMSExpectedResult: Codable {
    let amount: Double
    let biller: String
    let category: String
    let currency: String
}

struct SMSTestData: Codable {
    let description: String
    let version: String
    let testCases: [SMSTestCase]
}

/// Bill Parser test case structure
struct BillTestCase: Codable {
    let id: String
    let name: String
    let input: String
    let expected: BillExpectedResult
}

struct BillExpectedResult: Codable {
    let amount: Double
    let biller: String
    let category: String
    let currency: String
}

struct BillTestData: Codable {
    let description: String
    let version: String
    let testCases: [BillTestCase]
}

/// Category Detection test case structure
struct CategoryTestCase: Codable {
    let id: String
    let name: String
    let input: String
    let expectedCategory: String
}

struct CategoryTestData: Codable {
    let description: String
    let version: String
    let testCases: [CategoryTestCase]
}

// MARK: - Test Data Loader

enum TestDataLoader {
    
    /// Load SMS parser test data from JSON file
    static func loadSMSTestData() throws -> SMSTestData {
        try load(filename: "SMSParserTestData", type: SMSTestData.self)
    }
    
    /// Load Bill parser test data from JSON file
    static func loadBillTestData() throws -> BillTestData {
        try load(filename: "BillParserTestData", type: BillTestData.self)
    }
    
    /// Load Category detection test data from JSON file
    static func loadCategoryTestData() throws -> CategoryTestData {
        try load(filename: "CategoryDetectionTestData", type: CategoryTestData.self)
    }
    
    private static func load<T: Codable>(filename: String, type: T.Type) throws -> T {
        guard let url = Bundle(for: BundleFinder.self).url(forResource: filename, withExtension: "json") else {
            throw TestDataError.fileNotFound(filename)
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}

// Helper class to find the test bundle
private class BundleFinder {}

enum TestDataError: Error, LocalizedError {
    case fileNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "Test data file '\(filename).json' not found in test bundle"
        }
    }
}
