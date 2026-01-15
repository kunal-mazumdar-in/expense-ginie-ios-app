import SwiftUI

struct BudgetView: View {
    @ObservedObject var budgetStorage: BudgetStorage
    @EnvironmentObject var themeSettings: ThemeSettings
    
    private let categories = ["Banking", "Food", "Groceries", "Transport", "Shopping", "UPI", "Bills", "Entertainment", "Medical", "Other"]
    
    var body: some View {
        List {
            Section {
                ForEach(categories, id: \.self) { category in
                    BudgetRow(
                        category: category,
                        budgetStorage: budgetStorage
                    )
                }
            } header: {
                Text("Monthly Budget per Category")
            } footer: {
                Text("Set a monthly budget for each category. Leave at ₹0 to disable budget tracking for that category.")
            }
        }
        .listStyle(.insetGrouped)
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("Budget")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Budget Row
struct BudgetRow: View {
    let category: String
    let budgetStorage: BudgetStorage
    
    @State private var budgetText: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: AppTheme.iconForCategory(category))
                .font(.title3)
                .foregroundStyle(AppTheme.colorForCategory(category))
                .frame(width: 32)
            
            // Category name
            Text(category)
                .font(.body)
            
            Spacer()
            
            // Budget input
            HStack(spacing: 4) {
                Text("₹")
                    .foregroundStyle(.secondary)
                
                TextField("0", text: $budgetText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .focused($isFocused)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .onAppear {
            let currentBudget = budgetStorage.getBudget(for: category) ?? 0
            budgetText = currentBudget > 0 ? String(Int(currentBudget)) : ""
        }
        .onChange(of: isFocused) { _, focused in
            if !focused {
                // Save when focus is lost
                let filtered = budgetText.filter { $0.isNumber }
                let amount = Double(filtered) ?? 0
                budgetStorage.setBudget(for: category, amount: amount)
            }
        }
    }
}

// MARK: - Budget Tab Wrapper
struct BudgetTabView: View {
    @ObservedObject var budgetStorage: BudgetStorage
    
    var body: some View {
        NavigationStack {
            BudgetView(budgetStorage: budgetStorage)
        }
    }
}

#Preview {
    BudgetView(budgetStorage: BudgetStorage.shared)
        .environmentObject(ThemeSettings.shared)
}
