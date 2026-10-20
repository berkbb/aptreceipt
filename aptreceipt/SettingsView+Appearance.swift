import AppKit
import SwiftUI
import UniformTypeIdentifiers

extension SettingsView {
    // MARK: - Tab: Appearance & Language

    var appearanceTab: some View {
        Form {
            Section {
                Picker(l10n.appearanceSection, selection: themeSelection) {
                    ForEach(AppTheme.allCases) { theme in
                        Label(theme.title(l10n: l10n), systemImage: themeIcon(theme))
                            .tag(theme)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            } header: {
                Text(l10n.appearanceSection)
            }

            Section {
                Picker(l10n.languageSection, selection: languageSelection) {
                    ForEach(languageOptions, id: \.language) { option in
                        Text("\(option.flag)  \(option.title)").tag(option.language)
                    }
                }
                .labelsHidden()
            } header: {
                Text(l10n.languageSection)
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    if let selected = languageOptions.first(where: { $0.language == viewModel.language }) {
                        Text(selected.description)
                    }
                    Label {
                        Text(l10n.restartMenuBarNotice)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                    }
                }
                .font(.footnote)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            Section {
                currencyPicker
            } header: {
                Text(l10n.currencySection)
            }
        }
        .formStyle(.grouped)
    }

    /// Theme applies immediately (draft and store), as the former theme cards did.
    var themeSelection: Binding<AppTheme> {
        Binding(
            get: { viewModel.theme },
            set: { theme in
                viewModel.theme = theme
                settings.theme = theme
            }
        )
    }

    /// Currency applies immediately (draft and store), as the former currency cards did.
    var currencySelection: Binding<AppCurrency> {
        Binding(
            get: { viewModel.currency },
            set: { currency in
                viewModel.currency = currency
                settings.currency = currency
            }
        )
    }

    var currencyPicker: some View {
        Picker(l10n.currencySection, selection: currencySelection) {
            ForEach(AppCurrency.allCases) { currency in
                Text("\(currency.symbol)  \(currency.code) · \(currency.title(l10n: l10n))").tag(currency)
            }
        }
        .labelsHidden()
    }

    func themeIcon(_ theme: AppTheme) -> String {
        switch theme {
        case .system: return "laptopcomputer"
        case .light: return "sun.max.fill"
        case .dark: return "moon.stars.fill"
        }
    }

    // MARK: - Language Selection

    struct LanguageOption {
        let language: AppLanguage
        let flag: String
        let title: String
        let description: String
    }

    var languageOptions: [LanguageOption] {
        [
            LanguageOption(language: .turkish, flag: "🇹🇷", title: "Türkçe", description: l10n.langDescTR),
            LanguageOption(language: .english, flag: "🇬🇧", title: "English", description: l10n.langDescEN),
            LanguageOption(language: .romanian, flag: "🇷🇴", title: "Română", description: l10n.langDescRO),
            LanguageOption(language: .system, flag: "🌐", title: l10n.langSystem, description: l10n.langDescSystem),
        ]
    }

    var languageSelection: Binding<AppLanguage> {
        Binding(
            get: { viewModel.language },
            set: { selectLanguage($0) }
        )
    }

    func selectLanguage(_ lang: AppLanguage) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            viewModel.selectLanguage(lang, settings: settings)
        }
    }
}
