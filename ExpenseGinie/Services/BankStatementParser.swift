import Foundation
import PDFKit

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Bank Statement Parser
/// Parses bank account statements (savings/current accounts)
/// Extracts: Debits, Withdrawals, UPI transfers OUT, NEFT/IMPS/RTGS outgoing
@MainActor
class BankStatementParser: ObservableObject {
    static let shared = BankStatementParser()
    
    @Published var isProcessing = false
    @Published var processingStatus = ""
    
    private init() {}
    
    // MARK: - Main Parse Function
    func parse(from url: URL) async -> PDFParseResult {
        isProcessing = true
        processingStatus = "Reading bank statement..."
        
        defer {
            isProcessing = false
            processingStatus = ""
            deletePDF(at: url)
        }
        
        // Extract text from PDF
        guard let pdfText = extractText(from: url) else {
            return .extractionFailed("Could not read PDF content")
        }
        
        guard !pdfText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .extractionFailed("PDF appears to be empty or scanned (no text layer)")
        }
        
        processingStatus = "Analyzing bank transactions..."
        
        // Use AI if enabled, otherwise heuristics
        let llmAvailability = LLMAvailability.shared
        
        if llmAvailability.shouldUseAIParsing {
            if #available(iOS 26.0, *) {
                #if canImport(FoundationModels)
                print("✅ AI parsing enabled for Bank Statement")
                processingStatus = "Using AI to extract transactions..."
                return await parseWithAI(text: pdfText)
                #endif
            }
        }
        
        print("ℹ️ Using heuristics for Bank Statement parsing")
        return parseWithHeuristics(text: pdfText)
    }
    
    // MARK: - PDF Text Extraction
    private func extractText(from url: URL) -> String? {
        guard let document = PDFDocument(url: url) else { return nil }
        
        var fullText = ""
        for pageIndex in 0..<document.pageCount {
            if let page = document.page(at: pageIndex),
               let pageText = page.string {
                fullText += pageText + "\n"
            }
        }
        return fullText
    }
    
    // MARK: - AI Parsing
    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func parseWithAI(text: String) async -> PDFParseResult {
        print("🏦 Starting AI parsing for Bank Statement...")
        do {
            let transactions = try await callAI(with: text)
            if transactions.isEmpty {
                print("🏦 AI returned no transactions, falling back to heuristics")
                return parseWithHeuristics(text: text)
            }
            print("🏦 AI successfully parsed \(transactions.count) bank transactions")
            return .success(transactions, parsedWithAI: true)
        } catch {
            print("🏦 AI parsing error: \(error)")
            
            // Handle context window errors with retry
            let errorString = String(describing: error)
            if errorString.contains("exceededContextWindowSize") || errorString.contains("context") {
                print("🏦 Context window exceeded, retrying with smaller text...")
                let smallerText = String(text.prefix(3000))
                do {
                    let transactions = try await callAI(with: smallerText)
                    if !transactions.isEmpty {
                        return .success(transactions, parsedWithAI: true)
                    }
                } catch {
                    print("🏦 Retry failed: \(error)")
                }
            }
            
            return parseWithHeuristics(text: text)
        }
    }
    
    @available(iOS 26.0, *)
    private func callAI(with text: String) async throws -> [ParsedTransaction] {
        let session = LanguageModelSession()
        
        // Truncate text for context window
        let maxLength = 6000
        var truncatedText = text
        if text.count > maxLength {
            let prefix = String(text.prefix(maxLength))
            if let lastNewline = prefix.lastIndex(of: "\n") {
                truncatedText = String(prefix[..<lastNewline])
            } else {
                truncatedText = prefix
            }
        }
        
        // Bank statement specific prompt
        let prompt = """
        You are a BANK STATEMENT parser. Extract ONLY outgoing/expense transactions.

        For each transaction, extract:
        - date: transaction date in DD/MM/YYYY format
        - description: payee/merchant name only (max 50 chars)
        - amount: numeric value (positive number, no currency symbol or commas)
        - category: one of [Housing & Rent, Utilities, Groceries, Food & Dining, Transport & Fuel, Shopping, Medical & Healthcare, Entertainment, Subscriptions, Bills & Recharge, Insurance, Debt & EMI, Investments, Education & Learning, Travel & Vacation, Banking & Fees, UPI / Petty Cash, Other]
        - currency: 3-letter code (INR, USD, EUR, GBP, AED, SGD, AUD, CAD, JPY) - detect from statement

        EXTRACT ONLY THESE (money going OUT of account):
        ✓ UPI transfers/payments (sent to merchants or individuals)
        ✓ NEFT/IMPS/RTGS transfers OUT
        ✓ POS purchases (debit card transactions)
        ✓ ATM withdrawals
        ✓ Bill payments, recharges
        ✓ Cheque debits
        ✓ Standing instructions/auto-debits
        ✓ Bank fees/charges
        ✓ Foreign currency transactions (note the currency!)

        SKIP THESE (money coming INTO account):
        ✗ Salary credits
        ✗ UPI/NEFT/IMPS received
        ✗ Interest credits
        ✗ Refunds, reversals, cashbacks
        ✗ FD maturity credits
        ✗ Any row with "CR" or "CREDIT" or positive balance addition

        Look for columns: Date, Narration/Description, Debit, Credit, Balance
        Only extract rows where DEBIT column has value (not Credit column)

        Return ONLY a JSON array, no explanation:

        Statement Text:
        \(truncatedText)
        """
        
        print("🏦 Sending bank statement to LLM...")
        let response = try await session.respond(to: prompt)
        print("🏦 LLM response received")
        
        return parseJSONResponse(response.content)
    }
    #endif
    
    // MARK: - Heuristic Parsing
    private func parseWithHeuristics(text: String) -> PDFParseResult {
        let transactions = parseTransactionsHeuristically(from: text)
        if transactions.isEmpty {
            return .noTransactionsFound
        }
        return .success(transactions, parsedWithAI: false)
    }
    
    private func parseTransactionsHeuristically(from text: String) -> [ParsedTransaction] {
        var transactions: [ParsedTransaction] = []
        let lines = text.components(separatedBy: .newlines)
        
        // Date patterns
        let datePatterns = [
            "\\d{1,2}/\\d{1,2}/\\d{2,4}",
            "\\d{1,2}-\\d{1,2}-\\d{2,4}",
            "\\d{1,2}-[A-Za-z]{3}-\\d{2,4}",
            "\\d{1,2}\\s+[A-Za-z]{3}\\s+\\d{2,4}"
        ]
        
        // Bank statement specific debit keywords
        let debitKeywords = ["DR", "DEBIT", "UPI", "IMPS", "NEFT", "RTGS", "ATM", "POS", "WITHDRAWAL", "PAID", "TRF", "TRANSFER"]
        let creditKeywords = ["CR", "CREDIT", "SALARY", "REFUND", "REVERSAL", "CASHBACK", "INT", "INTEREST"]
        
        var i = 0
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { i += 1; continue }
            
            // Find date
            var foundDate: Date?
            for pattern in datePatterns {
                if let range = line.range(of: pattern, options: .regularExpression) {
                    foundDate = parseDate(String(line[range]))
                    if foundDate != nil { break }
                }
            }
            
            if let date = foundDate {
                var contextLines = [line]
                for j in 1...2 where i + j < lines.count {
                    contextLines.append(lines[i + j])
                }
                let context = contextLines.joined(separator: " ")
                let contextUpper = context.uppercased()
                
                // Check if debit (not credit)
                let isDebit = debitKeywords.contains { contextUpper.contains($0) }
                let isCredit = creditKeywords.contains { contextUpper.contains($0) }
                
                if isDebit && !isCredit {
                    if let (amount, currency) = extractAmountAndCurrency(from: context), amount > 0 {
                        let description = extractDescription(from: context)
                        transactions.append(ParsedTransaction(
                            date: date,
                            description: description,
                            amount: amount,
                            category: categorize(description),
                            currency: currency
                        ))
                    }
                }
            }
            i += 1
        }
        
        return removeDuplicates(from: transactions)
    }
    
    // MARK: - Currency Detection
    private func extractAmountAndCurrency(from text: String) -> (Double, DetectedCurrency)? {
        let currencyPatterns: [(pattern: String, currency: DetectedCurrency)] = [
            ("(?:Rs\\.?|INR|₹)\\s*([\\d,]+\\.?\\d*)", .inr),
            ("([\\d,]+\\.?\\d*)\\s*(?:Rs\\.?|INR)", .inr),
            ("(?:USD|US\\$|\\$)\\s*([\\d,]+\\.?\\d*)", .usd),
            ("([\\d,]+\\.?\\d*)\\s*(?:USD|US\\$)", .usd),
            ("(?:EUR|€)\\s*([\\d,]+\\.?\\d*)", .eur),
            ("([\\d,]+\\.?\\d*)\\s*(?:EUR|€)", .eur),
            ("(?:GBP|£)\\s*([\\d,]+\\.?\\d*)", .gbp),
            ("([\\d,]+\\.?\\d*)\\s*(?:GBP|£)", .gbp),
            ("(?:AED|Dh|DH)\\s*([\\d,]+\\.?\\d*)", .aed),
            ("([\\d,]+\\.?\\d*)\\s*(?:AED|Dh|DH)", .aed),
        ]
        
        for (pattern, currency) in currencyPatterns {
            if let match = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let matchedString = String(text[match])
                if let numberMatch = matchedString.range(of: "[\\d,]+\\.?\\d*", options: .regularExpression) {
                    let numberStr = String(matchedString[numberMatch]).replacingOccurrences(of: ",", with: "")
                    if let amount = Double(numberStr), amount > 0 {
                        return (amount, currency)
                    }
                }
            }
        }
        
        // Fallback: try generic amount pattern, assume INR for Indian bank statements
        let genericPattern = "([\\d,]+\\.\\d{2})"
        if let match = text.range(of: genericPattern, options: .regularExpression) {
            let numberStr = String(text[match]).replacingOccurrences(of: ",", with: "")
            if let amount = Double(numberStr), amount > 0 {
                return (amount, .inr)
            }
        }
        
        return nil
    }
    
    // MARK: - Helpers
    private func parseDate(_ dateString: String) -> Date? {
        let formats = ["dd/MM/yy", "dd/MM/yyyy", "dd-MM-yy", "dd-MM-yyyy", "dd-MMM-yy", "dd-MMM-yyyy", "dd MMM yy", "dd MMM yyyy"]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_IN")
        
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                let calendar = Calendar.current
                let year = calendar.component(.year, from: date)
                if year < 100 {
                    var components = calendar.dateComponents([.year, .month, .day], from: date)
                    components.year = 2000 + year
                    return calendar.date(from: components)
                }
                return date
            }
        }
        return nil
    }
    
    private func extractDescription(from context: String) -> String {
        var description = context
        let patternsToRemove = [
            "\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4}",
            "[\\d,]+\\.\\d{2}",
            "\\b(DR|CR|DEBIT|CREDIT)\\b",
            "\\b\\d{10,}\\b"
        ]
        
        for pattern in patternsToRemove {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                description = regex.stringByReplacingMatches(in: description, range: NSRange(description.startIndex..., in: description), withTemplate: "")
            }
        }
        
        description = description.components(separatedBy: .whitespaces).filter { !$0.isEmpty }.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        
        if description.count > 50 {
            description = String(description.prefix(50)) + "..."
        }
        return description.isEmpty ? "Bank Transaction" : description
    }
    
    private func categorize(_ description: String) -> String {
        BillerMapping.categorize(description)
    }
    
    private func removeDuplicates(from transactions: [ParsedTransaction]) -> [ParsedTransaction] {
        var seen = Set<String>()
        return transactions.filter { t in
            let key = "\(t.date.timeIntervalSince1970)-\(t.amount)"
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
    }
    
    #if canImport(FoundationModels)
    private func parseJSONResponse(_ response: String) -> [ParsedTransaction] {
        var jsonString = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let startIndex = jsonString.firstIndex(of: "["),
              let endIndex = jsonString.lastIndex(of: "]") else { return [] }
        
        jsonString = String(jsonString[startIndex...endIndex])
        guard let data = jsonString.data(using: .utf8) else { return [] }
        
        struct LLMTransaction: Codable {
            let date: String
            let description: String
            let amount: Double
            let category: String
            let currency: String?
        }
        
        do {
            let llmTransactions = try JSONDecoder().decode([LLMTransaction].self, from: data)
            let dateFormats = ["yyyy-MM-dd", "dd/MM/yyyy", "dd-MM-yyyy", "MM/dd/yyyy", "dd/MM/yy", "dd-MM-yy"]
            let formatter = DateFormatter()
            
            return llmTransactions.compactMap { llm -> ParsedTransaction? in
                var parsedDate: Date?
                for format in dateFormats {
                    formatter.dateFormat = format
                    if let date = formatter.date(from: llm.date) {
                        parsedDate = date
                        break
                    }
                }
                guard let date = parsedDate else { return nil }
                
                let validCategories = AppTheme.allCategories
                let category = validCategories.contains(llm.category) ? llm.category : "Other"
                
                // Parse currency
                let currency = DetectedCurrency(rawValue: llm.currency?.uppercased() ?? "INR") ?? .inr
                
                return ParsedTransaction(date: date, description: llm.description, amount: llm.amount, category: category, currency: currency)
            }
        } catch {
            print("🏦 JSON parsing error: \(error)")
            return []
        }
    }
    #endif
    
    private func deletePDF(at url: URL) {
        try? FileManager.default.removeItem(at: url)
        print("🏦 PDF deleted")
    }
}

