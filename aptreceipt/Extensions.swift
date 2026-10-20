import Foundation

// MARK: - Display Formatting

/// Amounts and percentages as the app language writes them, so every screen matches the printed receipt.
enum AppFormat {
    /// e.g. "₺1.750,00" (tr), "$1,750.00" (en), "1.750,00 Lei" (ro).
    static func currency(_ value: Double, _ currency: AppCurrency, l10n: L10n) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = l10n.locale
        formatter.currencySymbol = currency.symbol
        formatter.currencyCode = currency.code
        return formatter.string(from: NSNumber(value: value)) ?? "\(currency.symbol) \(String(format: "%.2f", value))"
    }

    /// e.g. "%16,7" (tr), "16.7%" (en), "16,7%" (ro). Turkish puts the sign first.
    static func percent(_ value: Double, l10n: L10n, minimumFractionDigits: Int = 1, maximumFractionDigits: Int = 1) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = l10n.locale
        formatter.minimumFractionDigits = minimumFractionDigits
        formatter.maximumFractionDigits = maximumFractionDigits
        let number = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)
        return l10n.resolvedLanguage == .turkish ? "%\(number)" : "\(number)%"
    }
}

// MARK: - Receipt Period

/// A receipt period such as "Ekim 2026", "October 2026" or "Octombrie 2026" reduced to year and month.
/// Receipts keep the period text of the language they were created in; this lets the same month written
/// in different app languages count as one period and be shown in the current language.
struct ReceiptPeriod: Hashable, Comparable {
    let year: Int
    let month: Int

    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        return calendar
    }()

    /// The app's languages, with both the format and the stand-alone month forms.
    private static let parsers: [DateFormatter] = ["tr_TR", "en_US", "ro_RO"].flatMap { identifier in
        ["MMMM yyyy", "LLLL yyyy"].map { format in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: identifier)
            formatter.calendar = calendar
            formatter.timeZone = calendar.timeZone
            formatter.dateFormat = format
            formatter.isLenient = true
            return formatter
        }
    }

    init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }

    init?(monthYear: String) {
        let text = monthYear.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        for parser in Self.parsers {
            // Also try the language's own lower case ("EKİM" → "ekim"), which plain matching misses.
            let candidates = [text, text.lowercased(with: parser.locale)]
            if let date = candidates.lazy.compactMap({ parser.date(from: $0) }).first {
                let components = Self.calendar.dateComponents([.year, .month], from: date)
                guard let year = components.year, let month = components.month else { continue }
                self.init(year: year, month: month)
                return
            }
        }
        return nil
    }

    /// Stable identifier, e.g. "2026-10".
    var id: String { String(format: "%04d-%02d", year, month) }

    /// Same format as new receipts ("MMMM yyyy") in the given locale.
    func title(locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = Self.calendar
        formatter.timeZone = Self.calendar.timeZone
        formatter.dateFormat = "MMMM yyyy"
        let date = Self.calendar.date(from: DateComponents(year: year, month: month, day: 15)) ?? Date()
        return formatter.string(from: date)
    }

    static func < (lhs: ReceiptPeriod, rhs: ReceiptPeriod) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }
}

// MARK: - Extensions

extension Date {
    func monthYearString(locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }

    func dayMonthYearString(locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("d MMMM yyyy")
        return formatter.string(from: self)
    }
}

extension Notification.Name {
    static let appLanguageDidChange = Notification.Name("appLanguageDidChange")
    static let settingsDidSave = Notification.Name("settingsDidSave")
}
