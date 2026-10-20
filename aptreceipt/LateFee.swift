import Foundation

// MARK: - Late Payment Compensation Country Profile

enum LateFeeCountryProfile: String, CaseIterable, Identifiable, Codable {
    case turkey = "turkey"
    case romania = "romania"
    case international = "international"
    case custom = "custom"

    var id: String { rawValue }

    var flagEmoji: String {
        switch self {
        case .turkey: return "🇹🇷"
        case .romania: return "🇷🇴"
        case .international: return "🌐"
        case .custom: return "⚙️"
        }
    }

    func title(l10n: L10n) -> String {
        switch self {
        case .turkey: return l10n.lateFeeProfileTurkey
        case .romania: return l10n.lateFeeProfileRomania
        case .international: return l10n.lateFeeProfileInternational
        case .custom: return l10n.lateFeeProfileCustom
        }
    }

    var defaultRate: Double {
        switch self {
        case .turkey: return 5.0
        case .romania: return 6.0
        case .international: return 5.0
        case .custom: return 5.0
        }
    }

    var defaultDueDay: Int {
        switch self {
        case .turkey: return 15
        case .romania: return 20
        case .international: return 10
        case .custom: return 15
        }
    }

    var defaultGraceDays: Int {
        switch self {
        case .turkey: return 0
        case .romania: return 30
        case .international: return 10
        case .custom: return 0
        }
    }

    var quickPresets: [Double] {
        switch self {
        case .turkey: return [3.0, 5.0, 7.5, 10.0]
        case .romania: return [3.0, 5.0, 6.0, 10.0]
        case .international: return [2.5, 5.0, 7.5, 10.0]
        case .custom: return [3.0, 5.0, 7.5, 10.0]
        }
    }

    func defaultFootnote(for language: AppLanguage) -> String {
        let l10n = L10n(language)
        switch self {
        case .turkey: return l10n.lateFeeFootnoteTurkey
        case .romania: return l10n.lateFeeFootnoteRomania
        case .international: return l10n.lateFeeFootnoteInternational
        case .custom: return l10n.lateFeeFootnoteCustom
        }
    }

    func defaultLegalNotice(for language: AppLanguage) -> String {
        let l10n = L10n(language)
        switch self {
        case .turkey: return l10n.lateFeeNoticeTurkey
        case .romania: return l10n.lateFeeNoticeRomania
        case .international: return l10n.lateFeeNoticeInternational
        case .custom: return l10n.lateFeeNoticeCustom
        }
    }

    static func `default`(for language: AppLanguage) -> LateFeeCountryProfile {
        switch language {
        case .turkish: return .turkey
        case .romanian: return .romania
        default: return .international
        }
    }
}

// MARK: - Money

/// Money arithmetic in `Decimal`, rounded half-up to cents, so half a cent never rounds the wrong way because
/// of binary floating point (1.005 → 1.01, not 1.00). Amounts are still stored as JSON numbers (`Double`)
/// so archives and backups stay compatible; each is read at its decimal value before calculating.
enum Money {
    /// The decimal value a stored amount stands for: its shortest form, e.g. 1.005 rather than 1.00499….
    static func decimal(_ value: Double) -> Decimal {
        guard value.isFinite else { return 0 }
        return Decimal(string: "\(value)") ?? Decimal(value)
    }

    /// Rounds half-up (away from zero) to cents.
    static func rounded(_ value: Decimal) -> Decimal {
        var input = value
        var result = Decimal()
        NSDecimalRound(&result, &input, 2, .plain)
        return result
    }

    /// The nearest `Double` to a decimal amount, for storage and formatting.
    static func double(_ value: Decimal) -> Double {
        Double("\(value)") ?? NSDecimalNumber(decimal: value).doubleValue
    }

    static func roundedToCents(_ value: Double) -> Double {
        double(rounded(decimal(value)))
    }

    /// Whole cents, rounded half-up.
    static func cents(_ value: Double) -> Int {
        NSDecimalNumber(decimal: rounded(decimal(value)) * 100).intValue
    }

    /// Sum of amounts in cents precision.
    static func sum<S: Sequence>(_ values: S) -> Double where S.Element == Double {
        double(rounded(values.reduce(Decimal(0)) { $0 + decimal($1) }))
    }

    /// `amount - deduction`, never below zero, rounded to cents.
    static func difference(_ amount: Double, _ deduction: Double) -> Double {
        double(rounded(max(0, decimal(amount) - decimal(deduction))))
    }
}

// MARK: - Late Payment Schedule

/// When a period's dues become late: due on the due day of the period's month (its last day when the month
/// is shorter), free of charge through the grace days, and after that every started month counts as one
/// late month. Example: due 15 October, no grace, paid 3 November → 1; paid 16 November → 2.
struct LatePaymentSchedule: Equatable {
    /// Due date and the last day without a late fee, both at the start of the day.
    let dueDate: Date
    let graceEnd: Date
    private let calendar: Calendar

    init?(year: Int, month: Int, dueDay: Int, graceDays: Int, calendar: Calendar = .current) {
        guard let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let dayCount = calendar.range(of: .day, in: .month, for: monthStart)?.count,
              let due = calendar.date(from: DateComponents(year: year, month: month, day: min(max(1, dueDay), dayCount))),
              let grace = calendar.date(byAdding: .day, value: max(0, graceDays), to: due) else { return nil }
        self.dueDate = calendar.startOfDay(for: due)
        self.graceEnd = calendar.startOfDay(for: grace)
        self.calendar = calendar
    }

    /// The schedule for the month of `period`.
    init?(period: Date, dueDay: Int, graceDays: Int, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.year, .month], from: period)
        guard let year = components.year, let month = components.month else { return nil }
        self.init(year: year, month: month, dueDay: dueDay, graceDays: graceDays, calendar: calendar)
    }

    var hasGracePeriod: Bool { graceEnd > dueDate }

    /// Started months after the grace end; 0 when paid on or before it.
    func lateMonths(paidOn date: Date) -> Int {
        let paid = calendar.startOfDay(for: date)
        guard paid > graceEnd else { return 0 }
        let elapsed = calendar.dateComponents([.month, .day], from: graceEnd, to: paid)
        let fullMonths = max(0, elapsed.month ?? 0)
        return (elapsed.day ?? 0) > 0 || fullMonths == 0 ? fullMonths + 1 : fullMonths
    }
}

// MARK: - Late Payment Compensation Calculator

enum LateFeeCalculator {
    /// Late fee for `base` at `monthlyRate` percent per month over `months`, rounded half-up to cents.
    static func fee(base: Double, monthlyRate: Double, months: Int) -> Double {
        Money.double(Money.rounded(Money.decimal(base) * Money.decimal(monthlyRate) / 100 * Decimal(months)))
    }

    /// Dues plus late fee, rounded half-up to cents.
    static func grandTotal(base: Double, lateFee: Double) -> Double {
        Money.double(Money.rounded(Money.decimal(base) + Money.decimal(lateFee)))
    }

    static func roundedToCents(_ value: Double) -> Double {
        Money.roundedToCents(value)
    }
}
