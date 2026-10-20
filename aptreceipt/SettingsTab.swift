import SwiftUI

// MARK: - Settings Tab Enum

enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "building"
    case residents = "residents"
    case vendors = "vendors"
    case appearance = "appearance"
    case signature = "signature"
    case backup = "backup"
    case about = "about"

    var id: String { rawValue }

    /// Every tab uses the width of the widest one (Residents, Vendors), so the window keeps one size.
    static let preferredWidth: CGFloat = 760

    var preferredWidth: CGFloat {
        Self.preferredWidth
    }

    static let preferredHeight: CGFloat = 620

    func title(l10n: L10n) -> String {
        switch self {
        case .general:
            return l10n.tabBuilding
        case .residents:
            return l10n.tabResidents
        case .vendors:
            return l10n.tabVendors
        case .appearance:
            return l10n.tabAppearance
        case .signature:
            return l10n.tabSignature
        case .backup:
            return l10n.tabBackup
        case .about:
            return l10n.tabAbout
        }
    }

    var iconName: String {
        switch self {
        case .general:
            return "building.2.fill"
        case .residents:
            return "person.2.fill"
        case .vendors:
            return "briefcase.fill"
        case .appearance:
            return "paintbrush.fill"
        case .signature:
            return "signature"
        case .backup:
            return "arrow.triangle.2.circlepath.circle.fill"
        case .about:
            return "info.circle.fill"
        }
    }
}
