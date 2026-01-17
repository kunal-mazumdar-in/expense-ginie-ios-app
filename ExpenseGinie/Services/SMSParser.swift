import Foundation

// Common currency symbols and codes
enum DetectedCurrency: String, Codable, CaseIterable {
    case inr = "INR"  // Indian Rupee ₹
    case usd = "USD"  // US Dollar $
    case eur = "EUR"  // Euro €
    case gbp = "GBP"  // British Pound £
    case aed = "AED"  // UAE Dirham
    case sgd = "SGD"  // Singapore Dollar
    case aud = "AUD"  // Australian Dollar
    case cad = "CAD"  // Canadian Dollar
    case jpy = "JPY"  // Japanese Yen ¥
    case unknown = "Unknown"
    
    var symbol: String {
        switch self {
        case .inr: return "₹"
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .aed: return "AED"
        case .sgd: return "S$"
        case .aud: return "A$"
        case .cad: return "C$"
        case .jpy: return "¥"
        case .unknown: return "?"
        }
    }
    
    var isINR: Bool {
        self == .inr
    }
}

struct ParsedSMS {
    let amount: Double
    let biller: String
    let category: String
    let date: Date
    let rawSMS: String
    let detectedCurrency: DetectedCurrency
}

@MainActor
class SMSParser {
    private let mappingStorage: MappingStorage
    
    init(mappingStorage: MappingStorage = .shared) {
        self.mappingStorage = mappingStorage
    }
    
    func parse(sms: String) -> ParsedSMS? {
        guard let (amount, currency) = extractAmountAndCurrency(from: sms), amount > 0 else {
            return nil
        }
        
        let (biller, category) = detectBillerAndCategory(in: sms)
        let date = extractDate(from: sms) ?? Date()
        
        return ParsedSMS(
            amount: amount,
            biller: biller,
            category: category,
            date: date,
            rawSMS: sms,
            detectedCurrency: currency
        )
    }
    
    /// Extract amount and currency from SMS - supports multiple currency formats
    private func extractAmountAndCurrency(from sms: String) -> (Double, DetectedCurrency)? {
        // Currency patterns with their corresponding currency type
        // Order matters - more specific patterns first
        let currencyPatterns: [(pattern: String, currency: DetectedCurrency)] = [
            // INR patterns
            ("(?:Rs\\.?|INR|₹)\\s*([\\d,]+\\.?\\d*)", .inr),
            ("([\\d,]+\\.?\\d*)\\s*(?:Rs\\.?|INR)", .inr),
            // USD patterns
            ("(?:USD|US\\$|\\$)\\s*([\\d,]+\\.?\\d*)", .usd),
            ("([\\d,]+\\.?\\d*)\\s*(?:USD|US\\$)", .usd),
            // EUR patterns
            ("(?:EUR|€)\\s*([\\d,]+\\.?\\d*)", .eur),
            ("([\\d,]+\\.?\\d*)\\s*(?:EUR|€)", .eur),
            // GBP patterns
            ("(?:GBP|£)\\s*([\\d,]+\\.?\\d*)", .gbp),
            ("([\\d,]+\\.?\\d*)\\s*(?:GBP|£)", .gbp),
            // AED patterns
            ("(?:AED|Dh|DH)\\s*([\\d,]+\\.?\\d*)", .aed),
            ("([\\d,]+\\.?\\d*)\\s*(?:AED|Dh|DH)", .aed),
            // SGD patterns
            ("(?:SGD|S\\$)\\s*([\\d,]+\\.?\\d*)", .sgd),
            ("([\\d,]+\\.?\\d*)\\s*(?:SGD|S\\$)", .sgd),
            // AUD patterns
            ("(?:AUD|A\\$)\\s*([\\d,]+\\.?\\d*)", .aud),
            ("([\\d,]+\\.?\\d*)\\s*(?:AUD|A\\$)", .aud),
            // CAD patterns
            ("(?:CAD|C\\$)\\s*([\\d,]+\\.?\\d*)", .cad),
            ("([\\d,]+\\.?\\d*)\\s*(?:CAD|C\\$)", .cad),
            // JPY patterns
            ("(?:JPY|¥)\\s*([\\d,]+\\.?\\d*)", .jpy),
            ("([\\d,]+\\.?\\d*)\\s*(?:JPY|¥)", .jpy),
        ]
        
        for (pattern, currency) in currencyPatterns {
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
        
        // Fallback: try to find any amount without currency marker
        let genericPatterns = [
            "(?:debited|credited|paid|spent|received).*?([\\d,]+\\.\\d{2})",
            "([\\d,]+\\.\\d{2})\\s*(?:debited|credited)"
        ]
        
        for pattern in genericPatterns {
            if let match = sms.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let matchedString = String(sms[match])
                if let numberMatch = matchedString.range(of: "[\\d,]+\\.\\d{2}", options: .regularExpression) {
                    let numberStr = String(matchedString[numberMatch]).replacingOccurrences(of: ",", with: "")
                    if let amount = Double(numberStr), amount > 0 {
                        // Assume INR for Indian bank messages without explicit currency
                        return (amount, .inr)
                    }
                }
            }
        }
        
        return nil
    }
    
    /// Extract date from SMS - supports multiple Indian date formats
    func extractDate(from sms: String) -> Date? {
        let datePatterns: [(pattern: String, format: String)] = [
            // DD/MM/YY or DD/MM/YYYY
            ("\\b(\\d{1,2}/\\d{1,2}/\\d{2,4})\\b", "dd/MM/yy"),
            // DD-MM-YY or DD-MM-YYYY
            ("\\b(\\d{1,2}-\\d{1,2}-\\d{2,4})\\b", "dd-MM-yy"),
            // DD.MM.YY or DD.MM.YYYY
            ("\\b(\\d{1,2}\\.\\d{1,2}\\.\\d{2,4})\\b", "dd.MM.yy"),
            // DD-Mon-YY or DD-Mon-YYYY (e.g., 15-Jan-26)
            ("\\b(\\d{1,2}-[A-Za-z]{3}-\\d{2,4})\\b", "dd-MMM-yy"),
            // DD Mon YY or DD Mon YYYY (e.g., 15 Jan 26)
            ("\\b(\\d{1,2}\\s+[A-Za-z]{3}\\s+\\d{2,4})\\b", "dd MMM yy"),
            // Mon DD, YYYY (e.g., Jan 15, 2026)
            ("\\b([A-Za-z]{3}\\s+\\d{1,2},?\\s+\\d{4})\\b", "MMM dd, yyyy"),
            // YYYY-MM-DD (ISO format)
            ("\\b(\\d{4}-\\d{2}-\\d{2})\\b", "yyyy-MM-dd"),
        ]
        
        for (pattern, format) in datePatterns {
            if let range = sms.range(of: pattern, options: .regularExpression) {
                let dateString = String(sms[range])
                if let date = parseDate(dateString, format: format) {
                    return date
                }
            }
        }
        
        return nil
    }
    
    private func parseDate(_ dateString: String, format: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        // Try the exact format first
        formatter.dateFormat = format
        if let date = formatter.date(from: dateString) {
            return adjustYearIfNeeded(date)
        }
        
        // Try with 4-digit year if 2-digit failed
        let format4Digit = format.replacingOccurrences(of: "yy", with: "yyyy")
        formatter.dateFormat = format4Digit
        if let date = formatter.date(from: dateString) {
            return adjustYearIfNeeded(date)
        }
        
        return nil
    }
    
    /// Adjust year for 2-digit years to ensure they're in a reasonable range
    private func adjustYearIfNeeded(_ date: Date) -> Date {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        
        // If year seems too far in future (like 2099), it's probably a parsing issue
        // Assume dates should be within last 1 year to next 1 year
        let currentYear = calendar.component(.year, from: Date())
        
        if year > currentYear + 1 {
            // Probably parsed wrong century, adjust
            var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            components.year = (year % 100) + 2000
            return calendar.date(from: components) ?? date
        }
        
        return date
    }
    
    /// Detect biller by scanning SMS body for known biller keywords (case-insensitive)
    /// Returns first match if multiple found
    func detectBillerAndCategory(in sms: String) -> (biller: String, category: String) {
        // Get all billers sorted by length (longer first to match specific names before generic)
        let sortedBillers = mappingStorage.mappings.keys.sorted { $0.count > $1.count }
        
        // Find all matching billers with their position in the SMS (case-insensitive)
        var matches: [(biller: String, position: Int, category: String)] = []
        
        for biller in sortedBillers {
            if let range = sms.range(of: biller, options: .caseInsensitive) {
                let position = sms.distance(from: sms.startIndex, to: range.lowerBound)
                let category = mappingStorage.mappings[biller] ?? "Other"
                matches.append((biller, position, category))
            }
        }
        
        // Return first match (by position in SMS), or default
        if let firstMatch = matches.sorted(by: { $0.position < $1.position }).first {
            return (firstMatch.biller, firstMatch.category)
        }
        
        return ("Unknown", "Other")
    }
    
    /// Recategorize an existing expense using current mappings
    func recategorize(expense: Expense) -> Expense {
        let (biller, category) = detectBillerAndCategory(in: expense.rawSMS)
        return Expense(
            amount: expense.amount,
            category: category,
            biller: biller,
            rawSMS: expense.rawSMS,
            date: expense.date
        )
    }
}
