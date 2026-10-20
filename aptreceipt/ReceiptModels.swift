import Foundation

// MARK: - Vendor & Service Models

struct VendorRecord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var category: String = ""
    var contactInfo: String = ""
}

struct ExpenseServicePreset: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var defaultDescription: String
    var iconName: String = "briefcase.fill"
    var suggestedVendor: String? = nil
}

// MARK: - Models

struct ValidationError: Identifiable {
    let id = UUID()
    let message: String
}

enum ReceiptKind: String, CaseIterable, Identifiable, Codable {
    case income
    case outcome
    case managementExpense = "management_expense"

    var id: String { rawValue }

    func title(l10n: L10n) -> String {
        switch self {
        case .income:
            return l10n.incomeTitle
        case .outcome:
            return l10n.outcomeTitle
        case .managementExpense:
            return l10n.managementExpenseTitle
        }
    }

    func badgeTitle(l10n: L10n) -> String {
        switch self {
        case .income:
            return l10n.filterIncome
        case .outcome:
            return l10n.filterOutcome
        case .managementExpense:
            return l10n.filterManagement
        }
    }

    var iconName: String {
        switch self {
        case .income:
            return "arrow.down.left.circle.fill"
        case .outcome:
            return "arrow.up.right.circle.fill"
        case .managementExpense:
            return "briefcase.fill"
        }
    }
}

struct ReceiptDraft: Identifiable, Codable {
    var id: UUID = UUID()
    let receiver: String
    let issuer: String
    let notes: String
    let monthYear: String
    let apartmentNumber: Int
    let amount: Double
    let sequenceNumber: Int
    let createdDate: String
    let showApartmentNumber: Bool
    let kind: ReceiptKind
    var currency: AppCurrency = .turkishLira
    var invoiceAttachmentPath: String? = nil
    var isLateFeeApplied: Bool = false
    var lateFeeRate: Double = 0.0
    var lateMonths: Int = 0
    var lateFeeAmount: Double = 0.0
    var baseAmount: Double = 0.0
    var lateFeeFootnote: String? = nil

    enum CodingKeys: String, CodingKey {
        case id, receiver, issuer, notes, monthYear, apartmentNumber, amount
        case sequenceNumber, createdDate, showApartmentNumber, kind, currency
        case invoiceAttachmentPath, isLateFeeApplied, lateFeeRate, lateMonths, lateFeeAmount, baseAmount
        case lateFeeFootnote
    }

    init(
        id: UUID = UUID(),
        receiver: String,
        issuer: String,
        notes: String,
        monthYear: String,
        apartmentNumber: Int,
        amount: Double,
        sequenceNumber: Int,
        createdDate: String,
        showApartmentNumber: Bool,
        kind: ReceiptKind,
        currency: AppCurrency = .turkishLira,
        invoiceAttachmentPath: String? = nil,
        isLateFeeApplied: Bool = false,
        lateFeeRate: Double = 0.0,
        lateMonths: Int = 0,
        lateFeeAmount: Double = 0.0,
        baseAmount: Double = 0.0,
        lateFeeFootnote: String? = nil
    ) {
        self.id = id
        self.receiver = receiver
        self.issuer = issuer
        self.notes = notes
        self.monthYear = monthYear
        self.apartmentNumber = apartmentNumber
        self.amount = amount
        self.sequenceNumber = sequenceNumber
        self.createdDate = createdDate
        self.showApartmentNumber = showApartmentNumber
        self.kind = kind
        self.currency = currency
        self.invoiceAttachmentPath = invoiceAttachmentPath
        self.isLateFeeApplied = isLateFeeApplied
        self.lateFeeRate = lateFeeRate
        self.lateMonths = lateMonths
        self.lateFeeAmount = lateFeeAmount
        self.baseAmount = baseAmount > 0 ? baseAmount : (isLateFeeApplied ? max(0, amount - lateFeeAmount) : amount)
        self.lateFeeFootnote = lateFeeFootnote
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        receiver = try container.decode(String.self, forKey: .receiver)
        issuer = try container.decode(String.self, forKey: .issuer)
        notes = try container.decode(String.self, forKey: .notes)
        monthYear = try container.decode(String.self, forKey: .monthYear)
        apartmentNumber = try container.decode(Int.self, forKey: .apartmentNumber)
        amount = try container.decode(Double.self, forKey: .amount)
        sequenceNumber = try container.decode(Int.self, forKey: .sequenceNumber)
        createdDate = try container.decode(String.self, forKey: .createdDate)
        showApartmentNumber = try container.decode(Bool.self, forKey: .showApartmentNumber)
        kind = try container.decode(ReceiptKind.self, forKey: .kind)
        currency = try container.decodeIfPresent(AppCurrency.self, forKey: .currency) ?? .turkishLira
        invoiceAttachmentPath = try container.decodeIfPresent(String.self, forKey: .invoiceAttachmentPath)
        isLateFeeApplied = try container.decodeIfPresent(Bool.self, forKey: .isLateFeeApplied) ?? false
        lateFeeRate = try container.decodeIfPresent(Double.self, forKey: .lateFeeRate) ?? 0.0
        lateMonths = try container.decodeIfPresent(Int.self, forKey: .lateMonths) ?? 0
        let decodedLateFee = try container.decodeIfPresent(Double.self, forKey: .lateFeeAmount) ?? 0.0
        lateFeeAmount = decodedLateFee
        baseAmount = try container.decodeIfPresent(Double.self, forKey: .baseAmount) ?? (amount - decodedLateFee)
        lateFeeFootnote = try container.decodeIfPresent(String.self, forKey: .lateFeeFootnote)
    }
}

// MARK: - Portable System Backup Model

struct SystemBackupPackage: Codable {
    var version: String = "2.1"
    var exportDate: Date = Date()
    var apartmentName: String
    var issuer: String
    var defaultPayment: String
    var flatCount: Int
    var seqNumber: Int
    var language: String
    var currency: String
    var residents: [Int: String]
    var residentPhones: [Int: String]
    var vendors: [VendorRecord]
    var expenseServices: [ExpenseServicePreset]
    var archivedReceipts: [ReceiptRecord]
    var isLateFeeEnabled: Bool? = false
    var lateFeeMonthlyRate: Double? = 5.0
    var lateFeeDueDay: Int? = 15
    var lateFeeCountryProfile: String? = "international"
    var lateFeeGracePeriodDays: Int? = 0
    var lateFeeCustomFootnote: String? = nil
    /// Receipt verification keys (Base64), the current one first; missing in backups made before 3.6.
    var receiptVerificationKeys: [String]? = nil
}
