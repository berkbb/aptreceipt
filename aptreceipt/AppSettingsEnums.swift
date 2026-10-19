import SwiftUI

// MARK: - Language & Theme Enums

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case english = "en"
    case turkish = "tr"
    case romanian = "ro"

    var id: String { rawValue }

    func title(l10n: L10n) -> String {
        switch self {
        case .system:
            return l10n.langSystem
        case .english:
            return "English"
        case .turkish:
            return "Türkçe"
        case .romanian:
            return "Română"
        }
    }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var id: String { rawValue }

    func title(l10n: L10n) -> String {
        switch self {
        case .system:
            return l10n.themeSystem
        case .light:
            return l10n.themeLight
        case .dark:
            return l10n.themeDark
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum AppCurrency: String, CaseIterable, Identifiable, Codable {
    case turkishLira = "TRY"
    case romanianLeu = "RON"
    case usDollar = "USD"
    case euro = "EUR"
    case britishPound = "GBP"

    var id: String { rawValue }

    var code: String { rawValue }

    var symbol: String {
        switch self {
        case .turkishLira: return "₺"
        case .romanianLeu: return "Lei"
        case .usDollar: return "$"
        case .euro: return "€"
        case .britishPound: return "£"
        }
    }

    func title(l10n: L10n) -> String {
        switch self {
        case .turkishLira:
            return "\(l10n.currencyTRY) (\(symbol))"
        case .romanianLeu:
            return "\(l10n.currencyRON) (\(symbol))"
        case .usDollar:
            return "\(l10n.currencyUSD) (\(symbol))"
        case .euro:
            return "\(l10n.currencyEUR) (\(symbol))"
        case .britishPound:
            return "\(l10n.currencyGBP) (\(symbol))"
        }
    }

    static func `default`(for language: AppLanguage) -> AppCurrency {
        switch language {
        case .turkish:
            return .turkishLira
        case .romanian:
            return .romanianLeu
        case .english, .system:
            return .usDollar
        }
    }
}
