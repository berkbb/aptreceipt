import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Settings Tab Enum

enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "building"
    case residents = "residents"
    case appearance = "appearance"
    case signature = "signature"
    case about = "about"

    var id: String { rawValue }

    func title(l10n: L10n) -> String {
        switch self {
        case .general:
            return l10n.tabBuilding
        case .residents:
            return l10n.tabResidents
        case .appearance:
            return l10n.tabAppearance
        case .signature:
            return l10n.tabSignature
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
        case .appearance:
            return "paintbrush.fill"
        case .signature:
            return "signature"
        case .about:
            return "info.circle.fill"
        }
    }
}

// MARK: - Settings View

@MainActor
struct SettingsView: View {
    @ObservedObject var settings: ReceiptSettingsStore
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.presentationMode) private var presentationMode
    @State private var selectedTab: SettingsTab = .general
    @State private var isPresentingLicense: Bool = false

    init(settings: ReceiptSettingsStore, initialTab: SettingsTab = .general) {
        self.settings = settings
        _selectedTab = State(initialValue: initialTab)
    }

    private var l10n: L10n {
        L10n(viewModel.language)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "gearshape.2.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(l10n.settingsTitle)
                        .font(.system(size: 16, weight: .bold))
                    Text(l10n.settingsSubtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Tab Bar
            HStack(spacing: 6) {
                ForEach(SettingsTab.allCases) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: tab.iconName)
                            Text(tab.title(l10n: l10n))
                        }
                        .font(.system(size: 12, weight: selectedTab == tab ? .bold : .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            selectedTab == tab
                            ? Color.accentColor.opacity(0.18)
                            : Color.clear
                        )
                        .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.6))

            Divider()

            // Active Tab Content
            ScrollView {
                VStack(spacing: 16) {
                    switch selectedTab {
                    case .general:
                        generalSettingsTab
                    case .residents:
                        residentsTab
                    case .appearance:
                        appearanceTab
                    case .signature:
                        signatureTab
                    case .about:
                        aboutTab
                    }
                }
                .padding(20)
            }
            .frame(maxHeight: .infinity)

            Divider()

            // Footer Buttons
            HStack {
                Button(l10n.cancel) {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(l10n.saveAndClose) {
                    if viewModel.save(to: settings) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .onAppear {
            viewModel.load(from: settings)
        }
        .alert(item: $viewModel.validationError) { issue in
            Alert(
                title: Text(l10n.validationErrorTitle),
                message: Text(issue.message),
                dismissButton: .default(Text(l10n.okButton))
            )
        }
        .alert(isPresented: $viewModel.showRestartAlert) {
            Alert(
                title: Text(l10n.restartWarningTitle),
                message: Text(l10n.restartMenuBarNotice),
                dismissButton: .default(Text(l10n.okButton))
            )
        }
    }

    // MARK: - Tab 1: General Settings

    private var generalSettingsTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Group 1: Apartman Bilgileri
            VStack(alignment: .leading, spacing: 10) {
                Label(l10n.buildingDetails, systemImage: "building.2.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)

                settingsField(title: l10n.buildingName, text: $viewModel.apartmentName, placeholder: "Örn: Güneş Apartmanı")
                settingsField(title: l10n.defaultManager, text: $viewModel.issuer, placeholder: "Örn: Ahmet Yılmaz")
                settingsField(title: l10n.totalFlats, text: $viewModel.flatCount, placeholder: "Örn: 10")
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Group 2: Mali Ayarlar
            VStack(alignment: .leading, spacing: 10) {
                Label(l10n.financialSettings, systemImage: "banknote.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)

                settingsField(title: "\(l10n.defaultDues) (\(viewModel.currency.symbol))", text: $viewModel.defaultPayment, placeholder: "1750")
                settingsField(title: l10n.nextReceiptNo, text: $viewModel.sequenceNumber, placeholder: "1")

                HStack {
                    Text(l10n.currencySelection)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(width: 200, alignment: .leading)

                    Picker("", selection: $viewModel.currency) {
                        ForEach(AppCurrency.allCases) { curr in
                            Text(curr.title(l10n: l10n)).tag(curr)
                        }
                    }
                    .labelsHidden()
                    .onChange(of: viewModel.currency) { newCurr in
                        settings.currency = newCurr
                    }
                }
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Group 3: Örnek Değerler / Sample Defaults
            VStack(alignment: .leading, spacing: 10) {
                Label(l10n.sampleDefaultsSection, systemImage: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)

                Text(l10n.sampleDefaultsDesc)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    Button {
                        viewModel.loadSampleDefaults(for: viewModel.language)
                    } label: {
                        Label(l10n.loadSampleDefaultsButton, systemImage: "arrow.counterclockwise.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)

                    if viewModel.showSampleDefaultsFeedback {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(l10n.sampleDefaultsLoadedFeedback)
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Tab 2: Residents Directory

    private var residentsTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(l10n.residentsDirectoryTitle)
                .font(.system(size: 14, weight: .bold))

            Text(l10n.residentsDirectoryDesc)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Picker(l10n.flatLabel, selection: $viewModel.selectedApartment) {
                    ForEach(viewModel.availableApartments, id: \.self) { number in
                        Text("\(l10n.flatPrefix) \(number)").tag(number)
                    }
                }
                .frame(width: 140)
                .onChange(of: viewModel.selectedApartment) { newValue in
                    viewModel.selectedOwner = settings.owner(for: newValue)
                }

                TextField(l10n.residentNamePlaceholder, text: $viewModel.selectedOwner)
                    .textFieldStyle(.roundedBorder)

                Button(l10n.saveButton) {
                    settings.saveOwner(viewModel.selectedOwner.localizedCapitalized, apartmentNumber: viewModel.selectedApartment)
                    viewModel.showOwnerSavedFeedback = true
                }
                .buttonStyle(.bordered)
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            if viewModel.showOwnerSavedFeedback {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("\(l10n.flatPrefix) \(viewModel.selectedApartment) \(l10n.residentSavedFeedback)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
    }

    // MARK: - Tab 3: Appearance & Language

    private var appearanceTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Theme selection
            VStack(alignment: .leading, spacing: 10) {
                Label(l10n.appearanceSection, systemImage: "circle.righthalf.filled")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)

                HStack {
                    Text(l10n.themeSelection)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(width: 200, alignment: .leading)

                    Picker("", selection: $viewModel.theme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.title(l10n: l10n)).tag(theme)
                        }
                    }
                    .labelsHidden()
                    .onChange(of: viewModel.theme) { newTheme in
                        settings.theme = newTheme
                    }
                }
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Language selection
            VStack(alignment: .leading, spacing: 10) {
                Label(l10n.languageSection, systemImage: "globe")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)

                HStack {
                    Text(l10n.languageSelection)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(width: 200, alignment: .leading)

                    Picker("", selection: $viewModel.language) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.title(l10n: l10n)).tag(lang)
                        }
                    }
                    .labelsHidden()
                    .onChange(of: viewModel.language) { newLang in
                        settings.language = newLang
                        viewModel.showRestartAlert = true
                    }
                }

                // Restart warning notice
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 13))
                    Text(l10n.restartMenuBarNotice)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .background(Color.orange.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Currency selection
            VStack(alignment: .leading, spacing: 10) {
                Label(l10n.currencySection, systemImage: "coloncurrencysign.circle.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)

                HStack {
                    Text(l10n.currencySelection)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(width: 200, alignment: .leading)

                    Picker("", selection: $viewModel.currency) {
                        ForEach(AppCurrency.allCases) { curr in
                            Text(curr.title(l10n: l10n)).tag(curr)
                        }
                    }
                    .labelsHidden()
                    .onChange(of: viewModel.currency) { newCurrency in
                        settings.currency = newCurrency
                    }
                }
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Tab 4: Signature

    private var signatureTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(l10n.signatureTitle)
                .font(.system(size: 14, weight: .bold))

            Text(l10n.signatureDesc)
                .font(.caption)
                .foregroundColor(.secondary)

            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .frame(height: 150)

                if let image = settings.signatureImage {
                    VStack(spacing: 6) {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 90)
                            .padding(6)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text(l10n.loadedSignature)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "signature")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .foregroundColor(.secondary.opacity(0.6))
                        Text(l10n.noSignatureYet)
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                }
            }

            HStack(spacing: 12) {
                Button {
                    settings.importSignature()
                } label: {
                    Label(l10n.uploadSignatureButton, systemImage: "arrow.up.doc.fill")
                }
                .buttonStyle(.borderedProminent)

                if settings.signatureImage != nil {
                    Button(role: .destructive) {
                        settings.clearSignature()
                    } label: {
                        Label(l10n.removeSignatureButton, systemImage: "trash.fill")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    // MARK: - Tab 5: About (Gözden geçirilmiş)

    private var aboutTab: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 68, height: 68)
                    .shadow(color: Color.accentColor.opacity(0.35), radius: 8, x: 0, y: 4)

                Image(systemName: "building.2.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.white)
            }

            VStack(spacing: 4) {
                Text(l10n.appTitle)
                    .font(.title2.bold())
                Text(l10n.appVersionText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Publisher Card
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "person.badge.shield.checkmark.fill")
                        .foregroundColor(.accentColor)
                        .font(.title3)
                    Text(l10n.publisher)
                        .font(.headline)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.12))
                .clipShape(Capsule())

                // License Card & Clickable Viewer
                VStack(spacing: 10) {
                    Text(l10n.license)
                        .font(.callout)
                        .foregroundColor(.secondary)

                    Button {
                        isPresentingLicense = true
                    } label: {
                        Label(l10n.viewLicenseButton, systemImage: "doc.text.magnifyingglass")
                            .font(.callout.bold())
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }
                .padding(14)
                .frame(maxWidth: 380)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )

                Text(l10n.copyright)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .sheet(isPresented: $isPresentingLicense) {
            LicenseViewerSheet(l10n: l10n)
        }
    }

    private func settingsField(title: String, text: Binding<String>, placeholder: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 200, alignment: .leading)
            TextField(placeholder, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

// MARK: - Settings View Model

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var apartmentName: String = ""
    @Published var issuer: String = ""
    @Published var defaultPayment: String = ""
    @Published var flatCount: String = "1"
    @Published var sequenceNumber: String = "1"
    @Published var language: AppLanguage = .system
    @Published var theme: AppTheme = .system
    @Published var currency: AppCurrency = .turkishLira
    @Published var showRestartAlert: Bool = false
    @Published var showSampleDefaultsFeedback: Bool = false

    @Published var selectedApartment: Int = 1
    @Published var selectedOwner: String = ""
    @Published var showOwnerSavedFeedback: Bool = false

    @Published var validationError: ValidationError?

    var availableApartments: [Int] {
        if let count = Int(flatCount), count > 0 {
            return Array(1...count)
        }
        return [1]
    }

    func load(from settings: ReceiptSettingsStore) {
        apartmentName = settings.apartmentName
        issuer = settings.issuer
        defaultPayment = settings.defaultPayment
        flatCount = String(settings.flatCount)
        sequenceNumber = String(settings.seqNumber)
        language = settings.language
        theme = settings.theme
        currency = settings.currency
        selectedApartment = settings.apartmentNumbers.first ?? 1
        selectedOwner = settings.owner(for: selectedApartment)
        showOwnerSavedFeedback = false
    }

    func loadSampleDefaults(for targetLang: AppLanguage) {
        let samples = SampleData.defaults(for: targetLang)
        apartmentName = samples.apartmentName
        issuer = samples.issuer
        defaultPayment = samples.defaultPayment
        flatCount = String(samples.flatCount)
        currency = samples.currency
        selectedOwner = samples.residents[selectedApartment] ?? (samples.residents[1] ?? "")
        showSampleDefaultsFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showSampleDefaultsFeedback = false
        }
    }

    func save(to settings: ReceiptSettingsStore) -> Bool {
        let l10n = L10n(language)
        let trimmedApartmentName = apartmentName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedIssuer = issuer.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDefaultPayment = defaultPayment.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let flats = Int(flatCount), flats > 0 else {
            validationError = ValidationError(message: l10n.errFlatCountInvalid)
            return false
        }
        guard let sequence = Int(sequenceNumber), sequence > 0 else {
            validationError = ValidationError(message: l10n.errSequenceInvalid)
            return false
        }
        guard Double(trimmedDefaultPayment.replacingOccurrences(of: ",", with: ".")) != nil else {
            validationError = ValidationError(message: l10n.errAmountInvalid)
            return false
        }
        guard !trimmedApartmentName.isEmpty, !trimmedIssuer.isEmpty else {
            validationError = ValidationError(message: l10n.errBuildingIssuerRequired)
            return false
        }

        settings.apartmentName = trimmedApartmentName
        settings.issuer = trimmedIssuer.localizedCapitalized
        settings.defaultPayment = trimmedDefaultPayment
        settings.flatCount = flats
        settings.seqNumber = sequence
        settings.language = language
        settings.theme = theme
        settings.currency = currency

        if !selectedOwner.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            settings.saveOwner(selectedOwner.localizedCapitalized, apartmentNumber: selectedApartment)
        }

        return true
    }
}
