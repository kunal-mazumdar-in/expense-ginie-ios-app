import Foundation

class BudgetStorage: ObservableObject {
    static let shared = BudgetStorage()
    
    @Published var budgets: [String: Double] = [:] {
        didSet {
            save()
        }
    }
    
    private let fileName = "category_budgets.json"
    
    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }
    
    init() {
        load()
    }
    
    // MARK: - Public Methods
    
    func setBudget(for category: String, amount: Double) {
        if amount > 0 {
            budgets[category] = amount
        } else {
            budgets.removeValue(forKey: category)
        }
    }
    
    func getBudget(for category: String) -> Double? {
        budgets[category]
    }
    
    func hasBudget(for category: String) -> Bool {
        budgets[category] != nil && budgets[category]! > 0
    }
    
    func isOverBudget(category: String, spent: Double) -> Bool {
        guard let budget = budgets[category] else { return false }
        return spent > budget
    }
    
    func budgetStatus(category: String, spent: Double) -> BudgetStatus {
        guard let budget = budgets[category], budget > 0 else {
            return .noBudget
        }
        
        let difference = spent - budget
        if difference > 0 {
            return .exceeded(by: difference)
        } else {
            return .withinBudget(remaining: abs(difference))
        }
    }
    
    // MARK: - Persistence
    
    private func save() {
        do {
            let data = try JSONEncoder().encode(budgets)
            try data.write(to: fileURL)
        } catch {
            print("Error saving budgets: \(error)")
        }
    }
    
    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: fileURL)
            budgets = try JSONDecoder().decode([String: Double].self, from: data)
        } catch {
            print("Error loading budgets: \(error)")
        }
    }
}

// MARK: - Budget Status
enum BudgetStatus: Equatable {
    case noBudget
    case withinBudget(remaining: Double)
    case exceeded(by: Double)
    
    var isExceeded: Bool {
        if case .exceeded = self { return true }
        return false
    }
    
    var isNoBudget: Bool {
        if case .noBudget = self { return true }
        return false
    }
}

