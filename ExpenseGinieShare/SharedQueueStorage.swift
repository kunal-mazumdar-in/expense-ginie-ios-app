import Foundation

/// Shared storage between main app and Share Extension using App Group
/// NOTE: This file is duplicated in both targets - keep them in sync!
class SharedQueueStorage {
    static let shared = SharedQueueStorage()
    
    // IMPORTANT: This must match the App Group ID in both targets
    static let appGroupID = "group.com.kunalm.expenseginie"
    
    private let queueFileName = "pending_sms_queue.json"
    
    private var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupID)
    }
    
    private var queueFileURL: URL? {
        containerURL?.appendingPathComponent(queueFileName)
    }
    
    struct PendingSMS: Codable, Identifiable {
        let id: UUID
        let text: String
        let dateAdded: Date
        
        init(text: String) {
            self.id = UUID()
            self.text = text
            self.dateAdded = Date()
        }
    }
    
    /// Add SMS to pending queue (called from Share Extension)
    /// Supports multiple expenses separated by blank lines or "---" delimiters
    /// Returns the number of expenses added
    @discardableResult
    func addToQueue(smsText: String) -> Int {
        let segments = splitIntoExpenses(text: smsText)
        guard !segments.isEmpty else { return 0 }
        
        var queue = loadQueue()
        for segment in segments {
            queue.append(PendingSMS(text: segment))
        }
        saveQueue(queue)
        return segments.count
    }
    
    /// Split text into multiple expense segments
    /// Delimiters: blank lines (double newline) or lines with 2+ dashes (any type)
    private func splitIntoExpenses(text: String) -> [String] {
        // Normalize line endings
        var normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        
        // All types of dashes to recognize as separators:
        // - Hyphen-minus (-) U+002D
        // - En-dash (–) U+2013
        // - Em-dash (—) U+2014
        // - Horizontal bar (―) U+2015
        let dashCharacters: Set<Character> = ["-", "–", "—", "―"]
        
        // Replace dash-only lines (2+ dashes of any type) with empty line
        let lines = normalized.components(separatedBy: "\n")
        var processedLines: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // Check if line contains only dash characters (2 or more)
            let isDashSeparator = trimmed.count >= 2 && trimmed.allSatisfy { dashCharacters.contains($0) }
            
            if isDashSeparator {
                // Replace dash line with empty line (becomes separator)
                processedLines.append("")
            } else {
                processedLines.append(line)
            }
        }
        
        normalized = processedLines.joined(separator: "\n")
        
        // Now split by double newlines (blank lines)
        let segments = normalized
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        return segments
    }
    
    /// Load all pending SMSs
    func loadQueue() -> [PendingSMS] {
        guard let url = queueFileURL,
              FileManager.default.fileExists(atPath: url.path) else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([PendingSMS].self, from: data)
        } catch {
            print("Error loading queue: \(error)")
            return []
        }
    }
    
    /// Save queue to shared container
    private func saveQueue(_ queue: [PendingSMS]) {
        guard let url = queueFileURL else {
            print("Error: App Group container not available")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(queue)
            try data.write(to: url)
        } catch {
            print("Error saving queue: \(error)")
        }
    }
    
    /// Remove specific item from queue
    func removeFromQueue(id: UUID) {
        var queue = loadQueue()
        queue.removeAll { $0.id == id }
        saveQueue(queue)
    }
    
    /// Clear entire queue
    func clearQueue() {
        saveQueue([])
    }
    
    /// Get count of pending items
    func pendingCount() -> Int {
        loadQueue().count
    }
}

