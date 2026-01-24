import Foundation
import SwiftData

@Model
final class BillerMapping {
    @Attribute(.unique) var biller: String  // Stored uppercase for case-insensitive matching
    var category: String
    
    init(biller: String, category: String) {
        self.biller = biller.uppercased()
        self.category = category
    }
    
    // MARK: - Centralized Categorization
    
    /// Categorize a transaction description by matching against known billers/keywords
    /// Used by all parsers (SMS, Bank Statement, Credit Card) for consistent categorization
    static func categorize(_ description: String) -> String {
        let desc = description.lowercased()
        
        // Sort defaults by biller length (descending) to match longer/more specific names first
        // e.g., "AMAZON PAY" should match before "AMAZON"
        let sortedDefaults = defaults.sorted { $0.biller.count > $1.biller.count }
        
        // First, check against default billers (exact/partial match)
        for (biller, category) in sortedDefaults {
            if desc.contains(biller.lowercased()) {
                return category
            }
        }
        
        // Fallback to keyword-based categorization for generic terms
        for (keywords, category) in keywordCategories {
            if keywords.contains(where: { desc.contains($0) }) {
                return category
            }
        }
        
        return "Other"
    }
    
    /// Generic keywords that don't match specific billers but indicate a category
    private static let keywordCategories: [([String], String)] = [
        // Food & Dining
        (["restaurant", "cafe", "food court", "dining", "eatery", "bakery", "dhaba"], "Food & Dining"),
        
        // Transport & Fuel
        (["petrol", "fuel", "diesel", "parking", "toll", "fastag"], "Transport & Fuel"),
        
        // Groceries (before Shopping - "grocery" should match before generic "store")
        (["grocery", "supermarket", "vegetables", "fruits", "kirana"], "Groceries"),
        
        // Shopping
        (["mall", "store", "retail", "mart", "shop", "boutique"], "Shopping"),
        
        // Utilities
        (["electricity", "water bill", "gas bill", "sewage", "municipal"], "Utilities"),
        
        // Medical & Healthcare
        (["hospital", "clinic", "doctor", "pharmacy", "medical", "diagnostic", "lab test", "pathology"], "Medical & Healthcare"),
        
        // Entertainment
        (["movie", "cinema", "theatre", "concert", "event", "game", "amusement"], "Entertainment"),
        
        // OTT (Streaming Platforms)
        (["streaming", "ott", "watch party", "binge"], "OTT"),
        
        // Education & Learning
        (["school", "college", "university", "tuition", "coaching", "education", "course"], "Education & Learning"),
        
        // Travel & Vacation
        (["flight", "hotel", "resort", "travel", "tour", "vacation", "airline"], "Travel & Vacation"),
        
        // Banking & Fees
        (["atm", "cash withdrawal", "bank fee", "annual fee", "interest charge", "finance charge", "late fee", "processing fee"], "Banking & Fees"),
        
        // Debt & EMI
        (["emi", "loan", "instalment", "installment", "credit line"], "Debt & EMI"),
        
        // Insurance
        (["insurance", "premium", "policy"], "Insurance"),
        
        // Housing & Rent
        (["rent", "housing", "apartment", "flat", "pg ", "hostel", "maintenance"], "Housing & Rent"),
        
        // Subscriptions
        (["subscription", "membership", "premium plan", "monthly plan", "annual plan"], "Subscriptions"),
        
        // Bills & Recharge
        (["recharge", "mobile", "broadband", "internet", "dth", "cable"], "Bills & Recharge"),
        
        // Gifts & Donations
        (["gift", "donation", "charity", "ngo", "temple", "church", "mosque", "gurudwara"], "Gifts & Donations"),
        
        // Vehicle Maintenance
        (["service center", "car wash", "tyre", "spare parts", "garage", "mechanic"], "Vehicle Maintenance"),
        
        // Pet Care
        (["pet", "veterinary", "vet clinic", "pet shop", "pet food"], "Pet Care"),
        
        // Professional Fees
        (["consultant", "lawyer", "chartered accountant", "ca ", "legal", "professional fee"], "Professional Fees"),
        
        // Taxes
        (["tax", "gst", "income tax", "tds", "challan"], "Taxes")
    ]
    
    // MARK: - Default Billers
    
    // Default billers to seed on first launch
    static let defaults: [(biller: String, category: String)] = [
        // Banking & Fees
        ("HDFC", "Banking & Fees"),
        ("SBI", "Banking & Fees"),
        ("ICICI", "Banking & Fees"),
        ("AXIS", "Banking & Fees"),
        ("KOTAK", "Banking & Fees"),
        ("YES BANK", "Banking & Fees"),
        ("IDFC", "Banking & Fees"),
        ("RBL", "Banking & Fees"),
        ("PUNJAB NATIONAL BANK", "Banking & Fees"),
        ("PNB", "Banking & Fees"),
        ("BANK OF BARODA", "Banking & Fees"),
        ("BOB", "Banking & Fees"),
        ("CANARA BANK", "Banking & Fees"),
        ("FEDERAL BANK", "Banking & Fees"),
        ("INDUSIND BANK", "Banking & Fees"),
        ("UNION BANK", "Banking & Fees"),
        ("STANDARD CHARTERED", "Banking & Fees"),
        ("HSBC", "Banking & Fees"),
        ("DBS", "Banking & Fees"),
        ("IDBI BANK", "Banking & Fees"),

        // Food & Dining
        ("SWIGGY", "Food & Dining"),
        ("ZOMATO", "Food & Dining"),
        ("DOMINOS", "Food & Dining"),
        ("MCDONALDS", "Food & Dining"),
        ("STARBUCKS", "Food & Dining"),
        ("KFC", "Food & Dining"),
        ("BURGER KING", "Food & Dining"),
        ("PIZZA HUT", "Food & Dining"),
        ("DUNKIN", "Food & Dining"),
        ("CAFE COFFEE DAY", "Food & Dining"),
        ("CCD", "Food & Dining"),
        ("SUBWAY", "Food & Dining"),
        ("BEHROUZ BIRYANI", "Food & Dining"),
        ("FAASOS", "Food & Dining"),
        ("WOW! MOMO", "Food & Dining"),
        ("TACO BELL", "Food & Dining"),
        ("PIZZA EXPRESS", "Food & Dining"),
        ("BASKIN ROBBINS", "Food & Dining"),
        ("BARBEQUE NATION", "Food & Dining"),
        ("REBEL FOODS", "Food & Dining"),

        // Transport & Fuel
        ("UBER", "Transport & Fuel"),
        ("OLA", "Transport & Fuel"),
        ("RAPIDO", "Transport & Fuel"),
        ("METRO", "Transport & Fuel"),
        ("IRCTC", "Transport & Fuel"),
        ("INDIAN OIL", "Transport & Fuel"),
        ("HP PETROL", "Transport & Fuel"),
        ("BHARAT PETROLEUM", "Transport & Fuel"),
        ("BPCL", "Transport & Fuel"),
        ("IOCL", "Transport & Fuel"),
        ("SHELL", "Transport & Fuel"),
        ("BLUSMART", "Transport & Fuel"),
        ("ZOOMCAR", "Transport & Fuel"),
        ("NAYARA ENERGY", "Transport & Fuel"),
        ("JIO-BP", "Transport & Fuel"),
        ("FASTAG", "Transport & Fuel"),

        // Shopping
        ("AMAZON", "Shopping"),
        ("FLIPKART", "Shopping"),
        ("MYNTRA", "Shopping"),
        ("AJIO", "Shopping"),
        ("NYKAA", "Shopping"),
        ("MEESHO", "Shopping"),
        ("TATA CLIQ", "Shopping"),
        ("CROMA", "Shopping"),
        ("RELIANCE", "Shopping"),
        ("WESTSIDE", "Shopping"),
        ("PANTALOONS", "Shopping"),
        ("SHOPPERS STOP", "Shopping"),
        ("DECATHLON", "Shopping"),
        ("H&M", "Shopping"),
        ("ZARA", "Shopping"),
        ("LENSKART", "Shopping"),
        ("PEPPERFRY", "Shopping"),
        ("URBAN LADDER", "Shopping"),
        ("TITAN", "Shopping"),
        ("TANISHQ", "Shopping"),
        ("CARATLANE", "Shopping"),

        // UPI / Petty Cash
        ("PHONEPE", "UPI / Petty Cash"),
        ("PAYTM", "UPI / Petty Cash"),
        ("GPAY", "UPI / Petty Cash"),
        ("GOOGLE PAY", "UPI / Petty Cash"),
        ("CRED", "UPI / Petty Cash"),
        ("BHIM", "UPI / Petty Cash"),
        ("SLICE", "UPI / Petty Cash"),
        ("MOBIKWIK", "UPI / Petty Cash"),
        ("FREECHARGE", "UPI / Petty Cash"),
        ("AMAZON PAY", "UPI / Petty Cash"),
        ("WHATSAPP PAY", "UPI / Petty Cash"),

        // Groceries
        ("BIGBASKET", "Groceries"),
        ("BLINKIT", "Groceries"),
        ("ZEPTO", "Groceries"),
        ("INSTAMART", "Groceries"),
        ("DMART", "Groceries"),
        ("MORE", "Groceries"),
        ("RELIANCE FRESH", "Groceries"),
        ("JIOMART", "Groceries"),
        ("AMAZON FRESH", "Groceries"),
        ("SPENCER'S", "Groceries"),
        ("NATURE'S BASKET", "Groceries"),
        ("SPAR", "Groceries"),
        ("STAR BAZAAR", "Groceries"),
        ("LISCIOUS", "Groceries"),
        ("FRESHMENU", "Groceries"),

        // Subscriptions (Non-OTT: Music, Productivity, etc.)
        ("SPOTIFY", "Subscriptions"),
        ("APPLE MUSIC", "Subscriptions"),
        ("APPLE SERVICES", "Subscriptions"),
        ("AUDIBLE", "Subscriptions"),
        ("LINKEDIN", "Subscriptions"),
        ("OPENAI", "Subscriptions"),
        ("CHATGPT", "Subscriptions"),
        ("CURSOR", "Subscriptions"),
        ("GITHUB", "Subscriptions"),
        ("NOTION", "Subscriptions"),
        ("CANVA", "Subscriptions"),
        ("JIOSAAVN", "Subscriptions"),
        ("GAANA", "Subscriptions"),
        ("WYNK MUSIC", "Subscriptions"),
        ("TATA PLAY", "Subscriptions"),
        ("AIRTEL XSTREAM", "Subscriptions"),
        ("YOUTUBE MUSIC", "Subscriptions"),
        ("AMAZON MUSIC", "Subscriptions"),

        // Bills & Recharge
        ("AIRTEL", "Bills & Recharge"),
        ("JIO", "Bills & Recharge"),
        ("VI", "Bills & Recharge"),
        ("VODAFONE", "Bills & Recharge"),
        ("BSNL", "Bills & Recharge"),
        ("ACT FIBERNET", "Bills & Recharge"),
        ("HATHWAY", "Bills & Recharge"),
        ("TATA SKY", "Bills & Recharge"),
        ("D2H", "Bills & Recharge"),
        ("EXCITEL", "Bills & Recharge"),
        ("YOU BROADBAND", "Bills & Recharge"),
        ("ALLIANCE BROADBAND", "Bills & Recharge"),
        ("MTNL", "Bills & Recharge"),
        ("SUN DIRECT", "Bills & Recharge"),
        ("DISH TV", "Bills & Recharge"),

        // Utilities
        ("BESCOM", "Utilities"),
        ("MSEDCL", "Utilities"),
        ("TATA POWER", "Utilities"),
        ("ADANI", "Utilities"),
        ("MAHANAGAR GAS", "Utilities"),
        ("IGL", "Utilities"),
        ("PIPED GAS", "Utilities"),
        ("TORRENT POWER", "Utilities"),
        ("CESC", "Utilities"),
        ("GUJARAT GAS", "Utilities"),
        ("BWSSB", "Utilities"),
        ("DJB", "Utilities"),

        // Medical & Healthcare
        ("APOLLO", "Medical & Healthcare"),
        ("PHARMEASY", "Medical & Healthcare"),
        ("NETMEDS", "Medical & Healthcare"),
        ("1MG", "Medical & Healthcare"),
        ("TATA 1MG", "Medical & Healthcare"),
        ("MEDPLUS", "Medical & Healthcare"),
        ("PRACTO", "Medical & Healthcare"),
        ("CULT FIT", "Medical & Healthcare"),
        ("CULTFIT", "Medical & Healthcare"),
        ("MAX HEALTHCARE", "Medical & Healthcare"),
        ("FORTIS", "Medical & Healthcare"),
        ("MANIPAL HOSPITALS", "Medical & Healthcare"),
        ("DR LAL PATHLABS", "Medical & Healthcare"),
        ("METROPOLIS", "Medical & Healthcare"),
        ("HEALTHKART", "Medical & Healthcare"),
        ("TRUEMEDS", "Medical & Healthcare"),

        // Insurance
        ("LIC", "Insurance"),
        ("HDFC LIFE", "Insurance"),
        ("ICICI PRUDENTIAL", "Insurance"),
        ("SBI LIFE", "Insurance"),
        ("MAX LIFE", "Insurance"),
        ("STAR HEALTH", "Insurance"),
        ("ACKO", "Insurance"),
        ("DIGIT", "Insurance"),
        ("CARE HEALTH", "Insurance"),
        ("NIVA BUPA", "Insurance"),
        ("RELIANCE GENERAL", "Insurance"),
        ("BAJAJ ALLIANZ", "Insurance"),
        ("TATA AIG", "Insurance"),
        ("POLICYBAZAAR", "Insurance"),
        ("DITTO", "Insurance"),

        // Debt & EMI
        ("BAJAJ FINSERV", "Debt & EMI"),
        ("BAJAJ FINANCE", "Debt & EMI"),
        ("HOME CREDIT", "Debt & EMI"),
        ("TATA CAPITAL", "Debt & EMI"),
        ("MUTHOOT FINANCE", "Debt & EMI"),
        ("MANAPPURAM FINANCE", "Debt & EMI"),
        ("L&T FINANCE", "Debt & EMI"),
        ("MAHINDRA FINANCE", "Debt & EMI"),
        ("ADITYA BIRLA CAPITAL", "Debt & EMI"),
        ("NAVI", "Debt & EMI"),
        ("KREDITBEE", "Debt & EMI"),
        ("MONEYVIEW", "Debt & EMI"),

        // Education & Learning
        ("UDEMY", "Education & Learning"),
        ("COURSERA", "Education & Learning"),
        ("SKILLSHARE", "Education & Learning"),
        ("BYJU", "Education & Learning"),
        ("UNACADEMY", "Education & Learning"),
        ("LINKEDIN LEARNING", "Education & Learning"),
        ("UPGRAD", "Education & Learning"),
        ("SIMPLILEARN", "Education & Learning"),
        ("PHYSICS WALLAH", "Education & Learning"),
        ("VEDANTU", "Education & Learning"),
        ("KHAN ACADEMY", "Education & Learning"),
        ("DUOLINGO", "Education & Learning"),

        // Travel & Vacation
        ("MAKEMYTRIP", "Travel & Vacation"),
        ("MMT", "Travel & Vacation"),
        ("GOIBIBO", "Travel & Vacation"),
        ("CLEARTRIP", "Travel & Vacation"),
        ("YATRA", "Travel & Vacation"),
        ("BOOKING.COM", "Travel & Vacation"),
        ("AIRBNB", "Travel & Vacation"),
        ("OYO", "Travel & Vacation"),
        ("REDBUS", "Travel & Vacation"),
        ("EASEMYTRIP", "Travel & Vacation"),
        ("INDIGO", "Travel & Vacation"),
        ("AIR INDIA", "Travel & Vacation"),
        ("SPICEJET", "Travel & Vacation"),
        ("VISTARA", "Travel & Vacation"),
        ("AKASA AIR", "Travel & Vacation"),
        ("THOMAS COOK", "Travel & Vacation"),
        ("AGODA", "Travel & Vacation"),
        ("TRIVAGO", "Travel & Vacation"),

        // Entertainment
        ("PVR", "Entertainment"),
        ("INOX", "Entertainment"),
        ("BOOKMYSHOW", "Entertainment"),
        ("CINEPOLIS", "Entertainment"),
        ("MIRAJ CINEMAS", "Entertainment"),
        ("CARNIVAL CINEMAS", "Entertainment"),
        ("EVENTBRITE", "Entertainment"),
        ("PAYTM INSIDER", "Entertainment"),

        // OTT (Streaming Platforms)
        // Global Giants
        ("NETFLIX", "OTT"),
        ("AMAZON PRIME VIDEO", "OTT"),
        ("PRIME VIDEO", "OTT"),
        ("DISNEY+", "OTT"),
        ("DISNEY PLUS", "OTT"),
        ("MAX", "OTT"),
        ("HBO MAX", "OTT"),
        ("YOUTUBE PREMIUM", "OTT"),
        ("APPLE TV+", "OTT"),
        ("APPLE TV PLUS", "OTT"),
        
        // Major US & International Services
        ("HULU", "OTT"),
        ("PEACOCK", "OTT"),
        ("PARAMOUNT+", "OTT"),
        ("PARAMOUNT PLUS", "OTT"),
        ("DISCOVERY+", "OTT"),
        ("DISCOVERY PLUS", "OTT"),
        ("STAR+", "OTT"),
        ("RAKUTEN TV", "OTT"),
        ("VIAPLAY", "OTT"),
        
        // Indian Market Leaders
        ("JIOHOTSTAR", "OTT"),
        ("JIO HOTSTAR", "OTT"),
        ("HOTSTAR", "OTT"),
        ("ZEE5", "OTT"),
        ("SONYLIV", "OTT"),
        ("SONY LIV", "OTT"),
        ("MX PLAYER", "OTT"),
        ("ALTBALAJI", "OTT"),
        ("ALT BALAJI", "OTT"),
        ("AHA", "OTT"),
        ("SUN NXT", "OTT"),
        ("SUNNXT", "OTT"),
        ("HOICHOI", "OTT"),
        
        // Anime & Niche
        ("CRUNCHYROLL", "OTT"),
        ("HIDIVE", "OTT"),
        ("MUBI", "OTT"),
        ("CURIOSITYSTREAM", "OTT"),
        ("CURIOSITY STREAM", "OTT"),
        ("SHUDDER", "OTT"),
        ("BRITBOX", "OTT"),
        
        // Free Ad-Supported (FAST) & AVOD
        ("TUBI", "OTT"),
        ("PLUTO TV", "OTT"),
        ("THE ROKU CHANNEL", "OTT"),
        ("ROKU CHANNEL", "OTT"),
        ("FREEVEE", "OTT"),
        ("VUDU", "OTT"),

        // Investments
        ("ZERODHA", "Investments"),
        ("GROWW", "Investments"),
        ("UPSTOX", "Investments"),
        ("ANGEL ONE", "Investments"),
        ("KUVERA", "Investments"),
        ("ET MONEY", "Investments"),
        ("INDMONEY", "Investments"),
        ("SMALLCASE", "Investments"),
        ("COINSWITCH", "Investments"),
        ("WAZIRX", "Investments"),

        // Housing & Rent
        ("NOBROKER", "Housing & Rent"),
        ("MAGICBRICKS", "Housing & Rent"),
        ("HOUSING.COM", "Housing & Rent"),
        ("99ACRES", "Housing & Rent"),

        // Pet Care
        ("HEADS UP FOR TAILS", "Pet Care"),
        ("HUFT", "Pet Care"),
        ("ZIGLY", "Pet Care"),
        ("SUPERTAILS", "Pet Care"),

        // Vehicle Maintenance
        ("GOMECHANIC", "Vehicle Maintenance"),
        ("PITSTOP", "Vehicle Maintenance"),
        ("MARUTI SUZUKI SERVICE", "Vehicle Maintenance"),
        ("HYUNDAI SERVICE", "Vehicle Maintenance"),

        // Taxes
        ("INCOME TAX DEPARTMENT", "Taxes"),
        ("GST PORTAL", "Taxes"),
        ("CLEARTAX", "Taxes"),

        // Business & Marketing
        ("GOOGLE ADS", "Marketing & Ads"),
        ("META ADS", "Marketing & Ads"),
        ("FACEBOOK ADS", "Marketing & Ads"),
        ("WEWORK", "Business Operations"),
        ("AWFIS", "Business Operations"),
        ("FIVERR", "Professional Fees"),
        ("UPWORK", "Professional Fees")
    ]
}

