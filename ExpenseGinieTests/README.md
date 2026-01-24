# ExpenseGinie Parser Tests

Unit tests for the expense parsing modules using data-driven test cases.

## Test Structure

```
ExpenseGinieTests/
├── TestData/                          # JSON test data files
│   ├── SMSParserTestData.json         # 20 SMS parsing test cases
│   ├── BillParserTestData.json        # 12 bill/receipt test cases
│   └── CategoryDetectionTestData.json # 45 category detection test cases
├── ParserTestModels.swift             # Test data models & loader
├── SMSParserTests.swift               # SMS parser tests
├── BillParserTests.swift              # Bill/receipt parser tests
├── CategoryDetectionTests.swift       # BillerMapping.categorize() tests
└── README.md                          # This file
```

## Adding Test Target to Xcode

Since the test target doesn't exist yet, follow these steps:

### Step 1: Add Test Target in Xcode

1. Open `ExpenseGinie.xcodeproj` in Xcode
2. Go to **File → New → Target**
3. Select **iOS → Unit Testing Bundle**
4. Name it `ExpenseGinieTests`
5. Ensure "Target to be Tested" is set to `ExpenseGinie`
6. Click **Finish**

### Step 2: Add Test Files to Target

1. In Xcode, select the `ExpenseGinieTests` folder in the navigator
2. Right-click → **Add Files to "ExpenseGinie"**
3. Select all files in `ExpenseGinieTests/`:
   - `ParserTestModels.swift`
   - `SMSParserTests.swift`
   - `BillParserTests.swift`
   - `CategoryDetectionTests.swift`
4. Ensure "ExpenseGinieTests" target is checked
5. Click **Add**

### Step 3: Add Test Data to Bundle

1. Select the `TestData` folder
2. Right-click → **Add Files to "ExpenseGinie"**
3. Select all JSON files in `TestData/`
4. **Important**: Check "ExpenseGinieTests" as the target
5. Ensure "Copy items if needed" is checked
6. Click **Add**

### Step 4: Verify Bundle Resources

1. Select `ExpenseGinieTests` target
2. Go to **Build Phases**
3. Expand **Copy Bundle Resources**
4. Verify all 3 JSON files are listed:
   - `SMSParserTestData.json`
   - `BillParserTestData.json`
   - `CategoryDetectionTestData.json`

## Running Tests

### Run All Tests
```bash
# From command line
xcodebuild test -scheme ExpenseGinie -destination 'platform=iOS Simulator,name=iPhone 15'

# Or in Xcode: Cmd + U
```

### Run Specific Test Class
In Xcode:
1. Open the test file (e.g., `SMSParserTests.swift`)
2. Click the diamond icon next to the class name
3. Or use **Product → Test** (Cmd + U)

### Run Individual Test
1. Click the diamond icon next to any test method
2. Or right-click on test name → **Run "testName"**

## Test Data Format

### SMS Test Case
```json
{
  "id": "SMS-001",
  "name": "HDFC Bank UPI Debit",
  "input": "Your a/c XXXX1234 is debited for Rs.500.00...",
  "expected": {
    "amount": 500.00,
    "biller": "SWIGGY",
    "category": "Food & Dining",
    "currency": "INR"
  }
}
```

### Bill Test Case
```json
{
  "id": "BILL-001",
  "name": "Restaurant Bill with GST",
  "input": "CAFE COFFEE DAY\nBill No: 12345\n...",
  "expected": {
    "amount": 504.00,
    "biller": "CAFE COFFEE DAY",
    "category": "Food & Dining",
    "currency": "INR"
  }
}
```

### Category Test Case
```json
{
  "id": "CAT-001",
  "name": "Food Delivery - Swiggy",
  "input": "SWIGGY ORDER",
  "expectedCategory": "Food & Dining"
}
```

## Adding New Test Cases

### 1. Add to JSON File
Edit the appropriate JSON file in `TestData/`:

```json
{
  "id": "SMS-021",
  "name": "New Bank SMS Format",
  "input": "Your new bank SMS format here...",
  "expected": {
    "amount": 100.00,
    "biller": "MERCHANT",
    "category": "Category Name",
    "currency": "INR"
  }
}
```

### 2. Run Tests
Tests automatically pick up new cases from JSON files.

## Test Coverage

| Test File | Test Cases | Coverage |
|-----------|------------|----------|
| SMSParserTestData.json | 20 | Bank SMS from HDFC, ICICI, SBI, Axis, Kotak |
| BillParserTestData.json | 12 | Restaurants, receipts, payment screenshots |
| CategoryDetectionTestData.json | 45 | All categories including OTT |

### Categories Covered
- Food & Dining (Swiggy, Zomato, restaurants)
- Transport & Fuel (Uber, Ola, petrol)
- Shopping (Amazon, Flipkart)
- Groceries (BigBasket, Zepto, Blinkit)
- OTT (Netflix, Hotstar, Prime Video, Zee5, etc.)
- Subscriptions (Spotify, music services)
- Medical & Healthcare
- Utilities (electricity, gas)
- Bills & Recharge (Airtel, Jio)
- Entertainment (PVR, BookMyShow)
- Travel & Vacation
- Insurance
- Debt & EMI
- Education & Learning
- Banking & Fees
- UPI / Petty Cash
- Investments

## Debugging Failed Tests

### View Test Output
1. Run tests in Xcode
2. Open **Report Navigator** (Cmd + 9)
3. Select the test run
4. Click on failed test to see details

### Debug Specific Case
Edit the `testSpecificCase()` method in any test file:

```swift
func testSpecificCase() throws {
    let targetID = "SMS-005" // Change this ID
    // ... test runs with detailed output
}
```

## Continuous Integration

For CI/CD, use:

```bash
# Run tests and output results
xcodebuild test \
  -scheme ExpenseGinie \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -resultBundlePath TestResults.xcresult

# Generate code coverage report
xcrun xccov view --report TestResults.xcresult
```
