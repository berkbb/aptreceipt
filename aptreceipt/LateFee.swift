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
        case .turkey:
            return l10n.isTurkish ? "Türkiye (KMK Md. 20/c)" : (l10n.isRomanian ? "Turcia (KMK Art. 20)" : "Turkey (KMK Art. 20)")
        case .romania:
            return l10n.isTurkish ? "Romanya (Legea 196/2018)" : (l10n.isRomanian ? "România (Legea 196/2018)" : "Romania (Law 196/2018)")
        case .international:
            return l10n.isTurkish ? "Uluslararası / Genel (HOA)" : (l10n.isRomanian ? "Internațional / General (HOA)" : "International / General (HOA)")
        case .custom:
            return l10n.isTurkish ? "Özel Yapılandırma" : (l10n.isRomanian ? "Personalizat" : "Custom Jurisdiction")
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
        switch self {
        case .turkey:
            switch language {
            case .turkish: return "* 634 Sayılı Kat Mülkiyeti Kanunu Madde 20/c uyarınca hesaplanmıştır."
            case .romanian: return "* Calculat conform art. 20/c din legislația asociațiilor de proprietari."
            default: return "* Calculated pursuant to Article 20/c of Property Law No. 634."
            }
        case .romania:
            switch language {
            case .turkish: return "* Romanya 196/2018 Sayılı Kanun Madde 77 (azami %0.2/gün) uyarınca hesaplanmıştır."
            case .romanian: return "* Calculat conform Legii 196/2018 Art. 77 privind asociațiile de proprietari (max. 0.2%/zi)."
            default: return "* Calculated pursuant to Romanian Law No. 196/2018 Art. 77 on Owners Associations."
            }
        case .international:
            switch language {
            case .turkish: return "* Bina yönetim planı ve işletme projesi gecikme hükümleri uyarınca hesaplanmıştır."
            case .romanian: return "* Calculat conform regulamentului de ordine interioară al asociației."
            default: return "* Calculated in accordance with condominium property association late fee regulations."
            }
        case .custom:
            switch language {
            case .turkish: return "* İlgili yönetim kurulu kararı ve gecikme tazminatı esasları uyarınca hesaplanmıştır."
            case .romanian: return "* Calculat conform deciziei comitetului executiv privind penalitățile."
            default: return "* Calculated in accordance with management board late penalty resolutions."
            }
        }
    }

    func defaultLegalNotice(for language: AppLanguage) -> String {
        switch self {
        case .turkey:
            switch language {
            case .turkish: return "634 sayılı Kat Mülkiyeti Kanunu Madde 20/c gereği vaktinde ödenmeyen aidata aylık %5 kanuni gecikme tazminatı uygulanır."
            case .romanian: return "Conform art. 20/c din Legea Asociațiilor, se aplică 5% penalizare lunară pentru restanțe."
            default: return "Under Article 20/c of Property Law No. 634, a 5% monthly compensation is legally applied to overdue dues."
            }
        case .romania:
            switch language {
            case .turkish: return "Romanya 196/2018 Sayılı Kanun Md. 77 gereği, 30 günlük son ödeme süresini aşan aidatlara günlük azami %0.2 (aylık yakl. %6) ceza uygulanabilir."
            case .romanian: return "Conform Legii 196/2018 Art. 77, asociația poate stabili penalizări de până la 0.2%/zi după un termen de grație de 30 de zile."
            default: return "Under Romanian Law 196/2018 Art. 77, associations may apply late penalties up to 0.2% per day after a 30-day grace period."
            }
        case .international:
            switch language {
            case .turkish: return "Bina ve site yönetim kuralları uyarınca vaktinde ödenmeyen aidatlara aylık gecikme bedeli işletilir."
            case .romanian: return "Penalitățile de întârziere se aplică în conformitate cu regulamentul asociației de proprietari."
            default: return "Late fees and penalties are applied to overdue dues in accordance with condominium HOA regulations."
            }
        case .custom:
            switch language {
            case .turkish: return "Özel gecikme oranı, son ödeme günü ve makbuz dipnotunu serbestçe belirleyebilirsiniz."
            case .romanian: return "Puteți defini liber rata penalizării, scadența și nota legală de pe chitanță."
            default: return "Freely configure your custom penalty rate, payment due threshold, and receipt legal citation."
            }
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
