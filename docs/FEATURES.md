# Expense Ginie - Features

## Home Screen
- Pie chart visualization of expenses by category
- Date filter (current month, previous months, all time)
- Total spending, transaction count, category count stats
- Category-wise expense breakdown with budget indicators
- Floating action button (+) with options:
  - Analyse Bank Statement (PDF upload)
  - Analyse Credit Card Statement (PDF upload)
  - Add Manually (SMS text input)

## Category Detail Screen
- List of all expenses in selected category
- Expandable expense cards (tap to view full SMS/description)
- Swipe to delete expense
- Date and amount display per expense

## Review Screen
- **From Siri** section - expenses added via voice
- **From SMS** section - shared SMS expenses
- **From Bank Statement** section - PDF imported expenses
- Per expense card:
  - Editable date picker
  - Category picker with auto-detect option
  - Expandable description (first line visible, tap to expand)
  - Accept (✓) button to add expense
  - Swipe to delete
  - Currency warning (⚠️) for non-INR amounts with edit popup
- Clear all pending expenses option
- AI indicator (sparkles) for AI-parsed bank statement items

## Add Expense (Manual)
- Paste or type SMS/transaction text
- Auto-parse amount, date, biller, category
- Multi-expense support (separate with blank lines or `---`)
- Category override before saving

## PDF Import (Bank Statement / Credit Card)
- Separate flows for bank statements vs credit card statements
- Local on-device processing (privacy indicator shown)
- AI parsing with Apple Intelligence (iOS 26+) or regex fallback
- Auto-categorization of transactions
- Currency detection (INR, USD, EUR, GBP, AED, etc.)
- Parsed expenses go to Review screen
- PDF deleted immediately after processing

## Edit Expense Popup (Non-INR Currency)
- Triggered by warning icon on non-INR expenses
- Shows original currency and amount
- Editable amount field (for manual conversion to INR)
- Editable description
- Category picker
- Date picker

## Share Extension
- Share SMS directly from Messages app
- Multi-expense support in single share
- Success confirmation with count
- Expenses queued for review in main app

## Siri Integration
- Voice commands: "Track [category] expense in Expense Ginie"
- Supported phrases:
  - "Track Food expense in Expense Ginie"
  - "Track Transport in Expense Ginie"
  - "Track expense in Expense Ginie for Shopping"
  - "Track my Bills expense in Expense Ginie"
- Amount, biller, date input via Siri dialog
- Expenses queued for review

## Settings Screen
- **Billers**: Manage biller-to-category mappings
- **Permissions**: App permissions status and settings
- **Data Management**: Export/import data, clear data
- **Theme**: Accent color customization

## Permissions Screen
- **Siri & Shortcuts**: Status and link to settings
- **Apple Intelligence**: Availability status (Enabled/Not Enabled/Unavailable)
- **AI Features**: "Analyse Statements" toggle (opt-in for AI parsing)
- Example Siri phrases displayed

## Budget Management
- Set monthly budget per category
- Budget progress indicator on Home screen
- Visual warning when approaching/exceeding budget

## Data & Storage
- SwiftData for expense persistence
- App Groups for Share Extension data sharing
- Local JSON queues for pending expenses (SMS, Siri, Bank Statement)

## Supported Categories
- Banking, Food, Groceries, Transport, Shopping
- UPI, Bills, Entertainment, Medical, Other

## Supported Currencies (Detection)
- INR (₹), USD ($), EUR (€), GBP (£)
- AED, SGD, AUD, CAD, JPY

