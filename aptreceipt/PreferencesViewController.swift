import AppKit
import SwiftUI
import UniformTypeIdentifiers

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

    /// Arhivar standard: compact preference tabs; the data-heavy directories get more room.
    var preferredWidth: CGFloat {
        switch self {
        case .residents, .vendors:
            return 760
        default:
            return 560
        }
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

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var settings: ReceiptSettingsStore
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var updateChecker = GitHubUpdateChecker.shared
    @State private var confirmsPreferenceReset = false
    /// The tab this page shows. In the settings window each toolbar tab hosts its own page and all
    /// pages share one draft, so Save & Close commits the edits made on every tab.
    private let tab: SettingsTab
    private let onClose: (() -> Void)?

    /// - Parameters:
    ///   - viewModel: The shared draft. When `nil` (screenshots, standalone sheet) the page owns a fresh draft.
    ///   - onClose: Closes the hosting window after Cancel or a successful save.
    init(
        settings: ReceiptSettingsStore,
        initialTab: SettingsTab = .general,
        viewModel: SettingsViewModel? = nil,
        onClose: (() -> Void)? = nil
    ) {
        self.settings = settings
        let vm = viewModel ?? SettingsViewModel()
        if viewModel == nil {
            vm.selectedTab = initialTab
        }
        _viewModel = StateObject(wrappedValue: vm)
        self.tab = initialTab
        self.onClose = onClose
    }

    private var l10n: L10n {
        L10n(viewModel.language)
    }

    /// Only the visible page presents alerts; hidden toolbar pages stay quiet.
    private var isActivePage: Bool {
        viewModel.selectedTab == tab
    }

    var body: some View {
        VStack(spacing: 0) {
            // Every tab is a grouped Form that scrolls on its own (Arhivar standard).
            tabContent
                .frame(maxHeight: .infinity)

            Divider()

            // Footer Buttons
            HStack {
                Button(l10n.cancel) {
                    close()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(l10n.saveAndClose) {
                    if viewModel.save(to: settings) {
                        NotificationCenter.default.post(name: .settingsDidSave, object: settings)
                        close()
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: tab.preferredWidth, height: SettingsTab.preferredHeight)
        .onAppear {
            // Load once per draft; switching toolbar tabs must not discard edits made on other tabs.
            if !viewModel.isLoaded {
                viewModel.load(from: settings)
            }
        }
        .alert(item: isActivePage ? $viewModel.validationError : .constant(nil)) { issue in
            Alert(
                title: Text(l10n.validationErrorTitle),
                message: Text(issue.message),
                dismissButton: .default(Text(l10n.okButton))
            )
        }
        .alert(isPresented: isActivePage ? $viewModel.showRestartAlert : .constant(false)) {
            Alert(
                title: Text(l10n.restartWarningTitle),
                message: Text(l10n.restartMenuBarNotice),
                dismissButton: .default(Text(l10n.okButton))
            )
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch tab {
        case .general:
            generalSettingsTab
        case .residents:
            residentsTab
        case .vendors:
            vendorsTab
        case .appearance:
            appearanceTab
        case .signature:
            signatureTab
        case .backup:
            backupTab
        case .about:
            aboutTab
        }
    }

    private func close() {
        presentationMode.wrappedValue.dismiss()
        if let onClose {
            onClose()
        } else {
            SettingsWindowManager.shared.close()
        }
    }

    // MARK: - Tab 1: General Settings

    private var generalSettingsTab: some View {
        Form {
            buildingProfileSection
            buildingDetailsSection
            financialSection
            lateFeeSection
            scenarioSection
        }
        .formStyle(.grouped)
    }

    /// Form rows carry their own alignment, so the catalog's trailing colons are dropped for display only.
    private func formLabel(_ text: String) -> String {
        var label = text.trimmingCharacters(in: .whitespaces)
        while label.hasSuffix(":") {
            label.removeLast()
        }
        return label.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Building Profile (logo + live summary)

    private var buildingProfileSection: some View {
        Section {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(NSColor.textBackgroundColor))
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.accentColor.opacity(0.25), lineWidth: 1.5)

                    if let logo = settings.logoImage {
                        Image(nsImage: logo)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 52, height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Default2DBuildingLogo(size: 52)
                    }
                }
                .frame(width: 68, height: 68)

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.apartmentName.isEmpty ? l10n.buildingNamePlaceholder : viewModel.apartmentName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(viewModel.apartmentName.isEmpty ? .secondary : .primary)
                        .lineLimit(1)

                    Label(
                        viewModel.issuer.isEmpty ? l10n.heroNotSpecified : "\(l10n.heroStatsManager): \(viewModel.issuer)",
                        systemImage: "person.badge.shield.checkmark.fill"
                    )
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                    if settings.logoImage != nil {
                        Label(l10n.activeLogoBadge, systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Label(l10n.default2DLogoBadge, systemImage: "sparkles")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                heroStatChip(
                    icon: "building.2.fill",
                    label: "\(viewModel.flatCount) \(l10n.heroStatsFlats)",
                    color: .accentColor
                )
                heroStatChip(
                    icon: "person.fill",
                    label: viewModel.issuer.isEmpty ? "-" : viewModel.issuer,
                    color: .purple
                )
                heroStatChip(
                    icon: "banknote.fill",
                    label: "\(viewModel.defaultPayment) \(viewModel.currency.symbol)",
                    color: .green
                )
                heroStatChip(
                    icon: "number.circle.fill",
                    label: "#\(viewModel.sequenceNumber)",
                    color: .orange
                )
            }

            HStack(spacing: 10) {
                Button {
                    settings.importLogo()
                } label: {
                    Label(l10n.uploadLogoButton, systemImage: "arrow.up.doc.fill")
                }
                .buttonStyle(.borderedProminent)

                if settings.logoImage != nil {
                    Button(role: .destructive) {
                        settings.clearLogo()
                    } label: {
                        Label(l10n.removeLogoButton, systemImage: "trash.fill")
                    }
                    .buttonStyle(.bordered)
                }
            }
        } header: {
            Text(l10n.buildingHeroBadge)
        }
    }

    private func heroStatChip(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(color.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Building Details

    private var buildingDetailsSection: some View {
        Section {
            TextField(formLabel(l10n.buildingName), text: $viewModel.apartmentName, prompt: Text(l10n.buildingNamePlaceholder))
            TextField(formLabel(l10n.defaultManager), text: $viewModel.issuer, prompt: Text(l10n.defaultManagerPlaceholder))
            TextField(formLabel(l10n.totalFlats), text: $viewModel.flatCount, prompt: Text(l10n.totalFlatsPlaceholder))

            LabeledContent(formLabel(l10n.heroQuickFlats)) {
                HStack(spacing: 5) {
                    ForEach([6, 8, 10, 12, 16, 20, 24, 30], id: \.self) { count in
                        let isSelected = viewModel.flatCount == String(count)
                        Button {
                            viewModel.setQuickFlatCount(count)
                        } label: {
                            Text("\(count)")
                                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.12))
                                .foregroundColor(isSelected ? .white : .primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        } header: {
            Text(l10n.buildingDetails)
        }
    }

    // MARK: - Financial Defaults

    private var financialSection: some View {
        Section {
            TextField("\(formLabel(l10n.defaultDues)) (\(viewModel.currency.symbol))", text: $viewModel.defaultPayment, prompt: Text("1750"))
            TextField(formLabel(l10n.nextReceiptNo), text: $viewModel.sequenceNumber, prompt: Text("1"))
            LabeledContent(formLabel(l10n.currencySelection)) {
                currencyPicker
                    .fixedSize()
            }
        } header: {
            Text(l10n.financialSettings)
        }
    }

    // MARK: - Late Fee (jurisdiction profiles stay neutral; see user_rejected_spec.md)

    private var lateFeeSection: some View {
        Section {
            Toggle(isOn: $viewModel.isLateFeeEnabled) {
                Label(l10n.lateFeeEnableToggle, systemImage: "scalemass.fill")
            }

            if viewModel.isLateFeeEnabled {
                // Buttons rather than a picker: re-selecting the current profile re-applies its defaults.
                VStack(alignment: .leading, spacing: 8) {
                    Text(formLabel(l10n.lateFeeCountryProfileTitle))
                    // Profile titles cite statutes and are long; a 2×2 grid keeps each on one line.
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], alignment: .leading, spacing: 6) {
                        ForEach(LateFeeCountryProfile.allCases) { profile in
                            let isSelected = viewModel.lateFeeCountryProfile == profile
                            Button {
                                viewModel.selectCountryProfile(profile)
                            } label: {
                                HStack(spacing: 4) {
                                    Text(profile.flagEmoji)
                                    Text(profile.title(l10n: l10n))
                                        .font(.system(size: 10.5, weight: isSelected ? .bold : .medium))
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(isSelected ? Color.orange : Color.secondary.opacity(0.12))
                                .foregroundColor(isSelected ? .white : .primary)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                LabeledContent(formLabel(l10n.lateFeeMonthlyRateTitle)) {
                    HStack(spacing: 4) {
                        Text("%")
                            .foregroundColor(.secondary)
                        TextField("5.0", text: $viewModel.lateFeeMonthlyRate)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 70)
                            .labelsHidden()
                    }
                }

                HStack(spacing: 5) {
                    Spacer(minLength: 0)
                    ForEach(viewModel.lateFeeCountryProfile.quickPresets, id: \.self) { rate in
                        let isSelected = (Double(viewModel.lateFeeMonthlyRate.replacingOccurrences(of: ",", with: ".")) ?? -1) == rate
                        Button {
                            viewModel.lateFeeMonthlyRate = String(format: "%.1f", rate)
                        } label: {
                            Text(rate == viewModel.lateFeeCountryProfile.defaultRate ? "%\(String(format: "%.1f", rate)) (\(l10n.statutoryRateLabel))" : "%\(String(format: "%.1f", rate))")
                                .font(.system(size: 10.5, weight: isSelected ? .bold : .medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(isSelected ? Color.orange : Color.secondary.opacity(0.12))
                                .foregroundColor(isSelected ? .white : .primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }

                LabeledContent(formLabel(l10n.lateFeeDueDayTitle)) {
                    HStack(spacing: 4) {
                        Text(l10n.dueDayDayPrefix)
                            .foregroundColor(.secondary)
                        Picker("", selection: $viewModel.lateFeeDueDay) {
                            ForEach(1...31, id: \.self) { day in
                                Text("\(day)").tag(day)
                            }
                        }
                        .labelsHidden()
                        .fixedSize()
                        Text(l10n.dueDayDaySuffix)
                            .foregroundColor(.secondary)
                    }
                }

                Picker(formLabel(l10n.lateFeeGracePeriodTitle), selection: $viewModel.lateFeeGracePeriodDays) {
                    ForEach([0, 5, 10, 15, 20, 30, 45, 60], id: \.self) { days in
                        Text("\(days)").tag(days)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(formLabel(l10n.lateFeeCustomFootnoteTitle))
                        Spacer()
                        Button(l10n.lateFeeResetFootnoteButton) {
                            viewModel.lateFeeCustomFootnote = ""
                        }
                        .buttonStyle(.link)
                        .font(.callout)
                    }
                    TextField("", text: $viewModel.lateFeeCustomFootnote, prompt: Text(viewModel.lateFeeCountryProfile.defaultFootnote(for: settings.language)))
                        .textFieldStyle(.roundedBorder)
                        .labelsHidden()
                }
            }
        } header: {
            Text(l10n.lateFeeTitle)
        } footer: {
            VStack(alignment: .leading, spacing: 6) {
                Text(l10n.lateFeeSubtitle)
                if viewModel.isLateFeeEnabled {
                    Label {
                        Text(viewModel.lateFeeCountryProfile.defaultLegalNotice(for: settings.language))
                    } icon: {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.orange)
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Starter Scenarios

    private var scenarioSection: some View {
        Section {
            if viewModel.showSampleDefaultsFeedback {
                Label(l10n.sampleDefaultsLoadedFeedback, systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
            scenarioRow(flag: "🇹🇷", title: l10n.sampleScenarioTR, desc: l10n.sampleScenarioDescTR, lang: .turkish)
            scenarioRow(flag: "🇬🇧", title: l10n.sampleScenarioEN, desc: l10n.sampleScenarioDescEN, lang: .english)
            scenarioRow(flag: "🇷🇴", title: l10n.sampleScenarioRO, desc: l10n.sampleScenarioDescRO, lang: .romanian)
        } header: {
            Text(l10n.quickScenarioTitle)
        } footer: {
            Text(l10n.quickScenarioSubtitle)
        }
    }

    private func scenarioRow(flag: String, title: String, desc: String, lang: AppLanguage) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Text(flag)
                .font(.system(size: 20))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Button {
                viewModel.loadSampleDefaults(for: lang)
            } label: {
                Label(l10n.applyScenarioButton, systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    // MARK: - Tab 2: Residents Directory (Hero Scroller List)

    private var residentsTab: some View {
        Form {
            Section {
                LabeledContent {
                    Text("\(viewModel.availableApartments.count)")
                } label: {
                    Label(l10n.totalFlatsBadge, systemImage: "building.2.fill")
                }
                LabeledContent {
                    Text("\(viewModel.registeredCount)")
                } label: {
                    Label(l10n.registeredResidentsBadge, systemImage: "checkmark.circle.fill")
                }
                if viewModel.unassignedCount > 0 {
                    LabeledContent {
                        Text("\(viewModel.unassignedCount)")
                    } label: {
                        Label(l10n.vacantFlatsBadge, systemImage: "circle.dashed")
                    }
                }

                HStack(spacing: 10) {
                    Button {
                        viewModel.fillSampleResidents(for: viewModel.language)
                    } label: {
                        Label(l10n.fillSampleResidentsButton, systemImage: "sparkles")
                    }
                    .buttonStyle(.bordered)

                    // Clears the draft only; Cancel still undoes it.
                    Button(role: .destructive) {
                        viewModel.clearAllResidents()
                    } label: {
                        Label(l10n.clearAllResidentsButton, systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                }
            } header: {
                Text(l10n.residentsDirectoryTitle)
            } footer: {
                Text(l10n.residentsDirectoryDesc)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("", text: $viewModel.residentSearchQuery, prompt: Text(l10n.searchNeighborsPlaceholder))
                        .textFieldStyle(.plain)
                        .labelsHidden()
                    if !viewModel.residentSearchQuery.isEmpty {
                        Button {
                            viewModel.residentSearchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if viewModel.filteredApartments.isEmpty {
                    Label(l10n.noMatchingResidents, systemImage: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                } else {
                    ForEach(viewModel.filteredApartments, id: \.self) { flat in
                        residentCard(flat: flat)
                    }
                }
            } header: {
                Text(l10n.heroStatsFlats)
            }
        }
        .formStyle(.grouped)
    }

    private func residentCard(flat: Int) -> some View {
        let nameBinding = viewModel.bindingForResident(at: flat)
        let phoneBinding = viewModel.bindingForResidentPhone(at: flat)
        let isAssigned = !nameBinding.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        return HStack(spacing: 12) {
            // Flat Badge
            VStack(spacing: 1) {
                Text(l10n.flatPrefix.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(isAssigned ? .white.opacity(0.9) : .secondary)
                Text("\(flat)")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(isAssigned ? .white : .primary)
            }
            .frame(width: 48, height: 42)
            .background(
                isAssigned
                ? LinearGradient(
                    colors: [Color.accentColor, Color.accentColor.opacity(0.75)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                : LinearGradient(
                    colors: [Color.secondary.opacity(0.15), Color.secondary.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Resident Name & Phone Fields
            VStack(alignment: .leading, spacing: 3) {
                // Inside a Form a titled TextField becomes "label … value"; use a prompt instead.
                TextField("", text: nameBinding, prompt: Text(l10n.residentNamePlaceholder))
                    .textFieldStyle(.plain)
                    .labelsHidden()
                    .multilineTextAlignment(.leading)
                    .font(.system(size: 13, weight: .medium))

                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        TextField("", text: phoneBinding, prompt: Text(l10n.residentPhonePlaceholder))
                            .textFieldStyle(.plain)
                            .labelsHidden()
                            .multilineTextAlignment(.leading)
                            .lineLimit(1)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: 160)
                    }

                    if isAssigned {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.green)
                            Text(l10n.flatAssigned)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack(spacing: 3) {
                            Image(systemName: "circle.dashed")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary.opacity(0.6))
                            Text(l10n.flatUnassigned)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                    }
                }
            }

            Spacer()

            // Clear Button
            if isAssigned {
                Button {
                    viewModel.clearResident(for: flat)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
                .help(l10n.clearResidentButton)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Tab: Vendors & Services

    private var vendorsTab: some View {
        Form {
            Section {
                LabeledContent {
                    Text("\(viewModel.vendors.count)")
                } label: {
                    Label(l10n.registeredVendorsBadge, systemImage: "building.2.fill")
                }
                LabeledContent {
                    Text("\(viewModel.expenseServices.count)")
                } label: {
                    Label(l10n.presetServicesBadge, systemImage: "sparkles")
                }

                Button {
                    viewModel.loadSampleVendorsAndServices(for: viewModel.language)
                } label: {
                    Label(l10n.loadSampleVendorsButton, systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)

                if viewModel.showSampleVendorsFeedback {
                    Label(l10n.sampleVendorsLoadedFeedback, systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            } header: {
                Text(l10n.vendorsTitle)
            } footer: {
                Text(l10n.vendorsSubtitle)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section {
                TextField(formLabel(l10n.vendorNameField), text: $viewModel.newVendorName)
                TextField(formLabel(l10n.vendorCategoryField), text: $viewModel.newVendorCategory)
                TextField(formLabel(l10n.vendorContactField), text: $viewModel.newVendorContact)
                HStack {
                    Spacer()
                    Button {
                        viewModel.addVendor()
                    } label: {
                        Label(l10n.saveVendorButton, systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.newVendorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                searchRow(text: $viewModel.vendorSearchQuery, prompt: l10n.searchVendorsPlaceholder)

                if viewModel.filteredVendors.isEmpty {
                    Text(l10n.noVendorsFound)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.filteredVendors) { vendor in
                        vendorRow(vendor)
                    }
                }
            } header: {
                Text(l10n.vendorListHeader)
            }

            Section {
                TextField(formLabel(l10n.serviceNameField), text: $viewModel.newServiceName)
                TextField(formLabel(l10n.serviceSuggestedVendorField), text: $viewModel.newServiceSuggestedVendor)
                TextField(formLabel(l10n.serviceDescriptionField), text: $viewModel.newServiceDescription)
                HStack {
                    Spacer()
                    Button {
                        viewModel.addExpenseService()
                    } label: {
                        Label(l10n.saveServiceButton, systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.newServiceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if viewModel.expenseServices.isEmpty {
                    Text(l10n.noServicesFound)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.expenseServices) { service in
                        serviceRow(service)
                    }
                }
            } header: {
                Text(l10n.serviceListHeader)
            }
        }
        .formStyle(.grouped)
    }

    private func searchRow(text: Binding<String>, prompt: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("", text: text, prompt: Text(prompt))
                .textFieldStyle(.plain)
                .labelsHidden()
            if !text.wrappedValue.isEmpty {
                Button {
                    text.wrappedValue = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func vendorRow(_ vendor: VendorRecord) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "building.2.fill")
                .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(vendor.name)
                        .font(.system(size: 12, weight: .bold))
                    if !vendor.category.isEmpty {
                        Text(vendor.category)
                            .font(.system(size: 9, weight: .semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                if !vendor.contactInfo.isEmpty {
                    Text(vendor.contactInfo)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button {
                viewModel.deleteVendor(id: vendor.id)
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
            .help(l10n.deleteButton)
        }
    }

    private func serviceRow(_ service: ExpenseServicePreset) -> some View {
        HStack(spacing: 10) {
            Image(systemName: service.iconName.isEmpty ? "briefcase.fill" : service.iconName)
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(service.name)
                        .font(.system(size: 12, weight: .bold))
                    if let vendor = service.suggestedVendor, !vendor.isEmpty {
                        Text(vendor)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                Text(service.defaultDescription)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Button {
                viewModel.deleteExpenseService(id: service.id)
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
            .help(l10n.deleteButton)
        }
    }

    // MARK: - Tab: Appearance & Language

    private var appearanceTab: some View {
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
    private var themeSelection: Binding<AppTheme> {
        Binding(
            get: { viewModel.theme },
            set: { theme in
                viewModel.theme = theme
                settings.theme = theme
            }
        )
    }

    /// Currency applies immediately (draft and store), as the former currency cards did.
    private var currencySelection: Binding<AppCurrency> {
        Binding(
            get: { viewModel.currency },
            set: { currency in
                viewModel.currency = currency
                settings.currency = currency
            }
        )
    }

    private var currencyPicker: some View {
        Picker(l10n.currencySection, selection: currencySelection) {
            ForEach(AppCurrency.allCases) { currency in
                Text("\(currency.symbol)  \(currency.code) · \(currency.title(l10n: l10n))").tag(currency)
            }
        }
        .labelsHidden()
    }

    private func themeIcon(_ theme: AppTheme) -> String {
        switch theme {
        case .system: return "laptopcomputer"
        case .light: return "sun.max.fill"
        case .dark: return "moon.stars.fill"
        }
    }

    // MARK: - Language Selection

    private struct LanguageOption {
        let language: AppLanguage
        let flag: String
        let title: String
        let description: String
    }

    private var languageOptions: [LanguageOption] {
        [
            LanguageOption(language: .turkish, flag: "🇹🇷", title: "Türkçe", description: l10n.langDescTR),
            LanguageOption(language: .english, flag: "🇬🇧", title: "English", description: l10n.langDescEN),
            LanguageOption(language: .romanian, flag: "🇷🇴", title: "Română", description: l10n.langDescRO),
            LanguageOption(language: .system, flag: "🌐", title: l10n.langSystem, description: l10n.langDescSystem),
        ]
    }

    private var languageSelection: Binding<AppLanguage> {
        Binding(
            get: { viewModel.language },
            set: { selectLanguage($0) }
        )
    }

    private func selectLanguage(_ lang: AppLanguage) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            viewModel.selectLanguage(lang, settings: settings)
        }
    }

    // MARK: - Tab 4: Signature

    private var signatureTab: some View {
        Form {
            Section {
                LabeledContent(settings.signatureImage == nil ? l10n.noSignatureYet : l10n.loadedSignature) {
                    if let image = settings.signatureImage {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 90)
                            .padding(6)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        Image(systemName: "signature")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .foregroundColor(.secondary.opacity(0.6))
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
            } header: {
                Text(l10n.signatureTitle)
            } footer: {
                Text(l10n.signatureDesc)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Tab: Backup & Restore

    private var backupTab: some View {
        Form {
            Section {
                LabeledContent(l10n.totalFlatsBadge, value: "\(viewModel.availableApartments.count)")
                LabeledContent(l10n.totalArchived, value: "\(ReceiptArchiveStore.shared.records.count)")

                // One row per action: the full labels do not fit side by side at 560 pt.
                Button {
                    exportFullBackup()
                } label: {
                    Label(l10n.exportBackupButton, systemImage: "square.and.arrow.up.fill")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    importFullBackup()
                } label: {
                    Label(l10n.importBackupButton, systemImage: "square.and.arrow.down.fill")
                }
                .buttonStyle(.bordered)

                if let msg = viewModel.backupSuccessMessage {
                    Label(msg, systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.callout.bold())
                } else if let err = viewModel.backupErrorMessage {
                    Label(err, systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.callout.bold())
                }
            } header: {
                Text(l10n.backupTitle)
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Text(l10n.backupSubtitle)
                    Label(l10n.backupNotice, systemImage: "info.circle.fill")
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
    }

    private func exportFullBackup() {
        guard let data = settings.exportSystemBackup() else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd_HHmmss"
        panel.nameFieldStringValue = "AptReceipt_Backup_\(df.string(from: Date())).json"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try data.write(to: url, options: .atomic)
                viewModel.backupSuccessMessage = l10n.backupExportSuccess
                viewModel.backupErrorMessage = nil
            } catch {
                viewModel.backupErrorMessage = error.localizedDescription
                viewModel.backupSuccessMessage = nil
            }
        }
    }

    private func importFullBackup() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try Data(contentsOf: url)
                try settings.importSystemBackup(from: data)
                viewModel.load(from: settings)
                viewModel.backupSuccessMessage = l10n.backupImportSuccess
                viewModel.backupErrorMessage = nil
            } catch {
                viewModel.backupErrorMessage = l10n.backupImportError
                viewModel.backupSuccessMessage = nil
            }
        }
    }

    // MARK: - Tab 5: About (Gözden geçirilmiş)

    private var aboutTab: some View {
        Form {
            Section {
                AboutContentView(settings: settings, showsUpdateButton: false)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } header: {
                Text(l10n.tabAbout)
            }

            Section {
                LabeledContent(l10n.installedVersionLabel, value: "\(AppInfo.version) (\(AppInfo.build))")
                LabeledContent(l10n.updateStatusLabel) {
                    updateStatusView
                }
                LabeledContent(l10n.lastChecked) {
                    if let last = updateChecker.lastCheckedDate {
                        Text(last.formatted(date: .numeric, time: .shortened))
                    } else {
                        Text(l10n.neverChecked)
                    }
                }
                .foregroundColor(.secondary)

                HStack {
                    Button(l10n.checkNowButton) {
                        updateChecker.checkForUpdates(userInitiated: false)
                    }
                    .disabled(updateChecker.isChecking || updateChecker.isDownloading)

                    if case .updateAvailable(let release) = updateChecker.status {
                        Button(String(format: l10n.downloadVersionFormat, release.tagName)) {
                            updateChecker.downloadUpdate(release: release)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(updateChecker.isDownloading)
                    }
                }

                Toggle(l10n.checkUpdatesAtLaunchToggle, isOn: $settings.checkUpdatesAtLaunch)
            } header: {
                Text(l10n.softwareUpdateSection)
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(l10n.softwareUpdateDesc)
                    Text(l10n.checkUpdatesAtLaunchFooter)
                }
                .fixedSize(horizontal: false, vertical: true)
            }

            Section {
                Button(l10n.resetSettingsButton, role: .destructive) {
                    confirmsPreferenceReset = true
                }
            } header: {
                Text(l10n.resetSectionHeader)
            } footer: {
                Text(l10n.resetSettingsFooter)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
        .confirmationDialog(l10n.resetSettingsConfirmTitle, isPresented: $confirmsPreferenceReset) {
            Button(l10n.resetSettingsConfirmAction, role: .destructive) {
                viewModel.resetPreferences(settings: settings)
            }
        }
        .sheet(isPresented: $settings.showLicenseViewer) {
            LicenseViewerSheet(l10n: l10n)
        }
    }

    @ViewBuilder
    private var updateStatusView: some View {
        switch updateChecker.status {
        case .idle:
            Text(l10n.updateStatusIdle)
                .foregroundColor(.secondary)
        case .checking:
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text(l10n.checkingForUpdates)
            }
            .foregroundColor(.secondary)
        case .upToDate:
            Label(l10n.upToDateTitle, systemImage: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .updateAvailable(let release):
            Label("\(l10n.updateAvailableTitle) \(release.tagName)", systemImage: "arrow.down.circle.fill")
                .foregroundColor(.accentColor)
        case .failed(let message):
            let isInfo = updateChecker.lastFailure == .noPublicRelease
            Label(message, systemImage: isInfo ? "info.circle" : "exclamationmark.triangle.fill")
                .foregroundColor(isInfo ? .secondary : .orange)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Settings View Model

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var selectedTab: SettingsTab = .general
    @Published var apartmentName: String = ""
    @Published var issuer: String = ""
    @Published var defaultPayment: String = ""
    @Published var flatCount: String = "1"
    @Published var sequenceNumber: String = "1"
    @Published var language: AppLanguage = .system
    @Published var theme: AppTheme = .system
    @Published var currency: AppCurrency = .turkishLira
    @Published var isLateFeeEnabled: Bool = false
    @Published var lateFeeMonthlyRate: String = "5.0"
    @Published var lateFeeDueDay: Int = 15
    @Published var lateFeeCountryProfile: LateFeeCountryProfile = .international
    @Published var lateFeeGracePeriodDays: Int = 0
    @Published var lateFeeCustomFootnote: String = ""
    @Published var showRestartAlert: Bool = false
    @Published var showSampleDefaultsFeedback: Bool = false

    @Published var residents: [Int: String] = [:]
    @Published var residentPhones: [Int: String] = [:]
    @Published var residentSearchQuery: String = ""
    @Published var backupSuccessMessage: String? = nil
    @Published var backupErrorMessage: String? = nil

    @Published var vendors: [VendorRecord] = []
    @Published var vendorSearchQuery: String = ""
    @Published var newVendorName: String = ""
    @Published var newVendorCategory: String = ""
    @Published var newVendorContact: String = ""

    @Published var expenseServices: [ExpenseServicePreset] = []
    @Published var newServiceName: String = ""
    @Published var newServiceDescription: String = ""
    @Published var newServiceSuggestedVendor: String = ""
    @Published var showSampleVendorsFeedback: Bool = false

    @Published var selectedApartment: Int = 1
    @Published var selectedOwner: String = ""
    @Published var showOwnerSavedFeedback: Bool = false

    @Published var validationError: ValidationError?

    /// Set by `load(from:)`; pages load the shared draft only once.
    private(set) var isLoaded = false

    var totalFlatCount: Int {
        Int(flatCount) ?? 1
    }

    var availableApartments: [Int] {
        if let count = Int(flatCount), count > 0 {
            return Array(1...count)
        }
        return [1]
    }

    var registeredCount: Int {
        availableApartments.filter { flat in
            let name = residents[flat]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return !name.isEmpty
        }.count
    }

    var unassignedCount: Int {
        max(0, availableApartments.count - registeredCount)
    }

    var filteredApartments: [Int] {
        let query = residentSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            return availableApartments
        }
        return availableApartments.filter { flat in
            let flatStr = String(flat)
            let name = (residents[flat] ?? "").lowercased()
            return flatStr.contains(query) || name.contains(query)
        }
    }

    var filteredVendors: [VendorRecord] {
        let query = vendorSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            return vendors
        }
        return vendors.filter { v in
            v.name.lowercased().contains(query) || v.category.lowercased().contains(query) || v.contactInfo.lowercased().contains(query)
        }
    }

    func addVendor() {
        let trimmedName = newVendorName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let trimmedCategory = newVendorCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContact = newVendorContact.trimmingCharacters(in: .whitespacesAndNewlines)
        let vendor = VendorRecord(name: trimmedName, category: trimmedCategory, contactInfo: trimmedContact)
        vendors.append(vendor)
        newVendorName = ""
        newVendorCategory = ""
        newVendorContact = ""
    }

    func deleteVendor(id: UUID) {
        vendors.removeAll { $0.id == id }
    }

    func addExpenseService() {
        let trimmedName = newServiceName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let trimmedDesc = newServiceDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedVendor = newServiceSuggestedVendor.trimmingCharacters(in: .whitespacesAndNewlines)
        let service = ExpenseServicePreset(
            name: trimmedName,
            defaultDescription: trimmedDesc.isEmpty ? trimmedName : trimmedDesc,
            iconName: "briefcase.fill",
            suggestedVendor: trimmedVendor.isEmpty ? nil : trimmedVendor
        )
        expenseServices.append(service)
        newServiceName = ""
        newServiceDescription = ""
        newServiceSuggestedVendor = ""
    }

    func deleteExpenseService(id: UUID) {
        expenseServices.removeAll { $0.id == id }
    }

    func loadSampleVendorsAndServices(for targetLang: AppLanguage) {
        let samples = SampleData.defaults(for: targetLang)
        vendors = samples.defaultVendors
        expenseServices = samples.defaultServices
        showSampleVendorsFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showSampleVendorsFeedback = false
        }
    }

    func bindingForResident(at flat: Int) -> Binding<String> {
        Binding<String>(
            get: { self.residents[flat] ?? "" },
            set: { self.residents[flat] = $0 }
        )
    }

    func bindingForResidentPhone(at flat: Int) -> Binding<String> {
        Binding<String>(
            get: { self.residentPhones[flat] ?? "" },
            set: { self.residentPhones[flat] = $0 }
        )
    }

    func clearResident(for flat: Int) {
        residents[flat] = ""
        residentPhones[flat] = ""
    }

    func fillSampleResidents(for targetLang: AppLanguage) {
        let samples = SampleData.defaults(for: targetLang)
        let maxFlats = max(1, totalFlatCount)
        for (apt, name) in samples.residents {
            if apt <= maxFlats {
                residents[apt] = name
            }
        }
    }

    func clearAllResidents() {
        for apt in availableApartments {
            residents[apt] = ""
            residentPhones[apt] = ""
        }
    }

    func load(from settings: ReceiptSettingsStore) {
        isLoaded = true
        apartmentName = settings.apartmentName
        issuer = settings.issuer
        defaultPayment = settings.defaultPayment
        flatCount = String(settings.flatCount)
        sequenceNumber = String(settings.seqNumber)
        language = settings.language
        theme = settings.theme
        currency = settings.currency
        isLateFeeEnabled = settings.isLateFeeEnabled
        lateFeeMonthlyRate = String(format: "%.1f", settings.lateFeeMonthlyRate)
        lateFeeDueDay = settings.lateFeeDueDay
        lateFeeCountryProfile = settings.lateFeeCountryProfile
        lateFeeGracePeriodDays = settings.lateFeeGracePeriodDays
        lateFeeCustomFootnote = settings.lateFeeCustomFootnote
        vendors = settings.vendors
        expenseServices = settings.expenseServices
        selectedApartment = settings.apartmentNumbers.first ?? 1
        selectedOwner = settings.owner(for: selectedApartment)
        showOwnerSavedFeedback = false
        backupSuccessMessage = nil
        backupErrorMessage = nil

        var loaded: [Int: String] = [:]
        var loadedPhones: [Int: String] = [:]
        for apt in 1...settings.flatCount {
            loaded[apt] = settings.owner(for: apt)
            loadedPhones[apt] = settings.ownerPhone(for: apt)
        }
        residents = loaded
        residentPhones = loadedPhones
    }

    /// The language and its default currency apply at once; a sample (or empty) building switches to that
    /// language's sample data, which is stored right away; the restart notice is shown. Unrelated pending
    /// edits on other tabs stay in the draft for Save & Close or Cancel.
    func selectLanguage(_ lang: AppLanguage, settings: ReceiptSettingsStore) {
        language = lang
        settings.language = lang
        let resolved = L10n(lang).resolvedLanguage
        let newCurrency = AppCurrency.default(for: resolved)
        currency = newCurrency
        settings.currency = newCurrency

        let sampleApts = [
            SampleData.defaults(for: .english).apartmentName,
            SampleData.defaults(for: .turkish).apartmentName,
            SampleData.defaults(for: .romanian).apartmentName
        ]
        if sampleApts.contains(apartmentName) || apartmentName.isEmpty {
            loadSampleDefaults(for: lang)
            commitSampleData(to: settings)
        }
        showRestartAlert = true
    }

    /// Stores the fields `loadSampleDefaults(for:)` filled, with the same normalization as `save(to:)`.
    private func commitSampleData(to settings: ReceiptSettingsStore) {
        let flats = max(1, Int(flatCount) ?? settings.flatCount)
        settings.apartmentName = apartmentName.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.issuer = issuer.trimmingCharacters(in: .whitespacesAndNewlines).localizedCapitalized
        settings.defaultPayment = defaultPayment.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.flatCount = flats
        settings.currency = currency
        settings.vendors = vendors
        settings.expenseServices = expenseServices
        for apt in 1...flats {
            let name = (residents[apt] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            settings.saveOwner(name.localizedCapitalized, apartmentNumber: apt)
        }
        settings.objectWillChange.send()
        NotificationCenter.default.post(name: .settingsDidSave, object: settings)
    }

    /// Resets the stored preferences and mirrors them into the draft. Other draft edits (building,
    /// residents, vendors) are kept, so Save & Close still commits them.
    func resetPreferences(settings: ReceiptSettingsStore) {
        settings.resetPreferencesToDefaults()
        language = settings.language
        theme = settings.theme
        currency = settings.currency
        isLateFeeEnabled = settings.isLateFeeEnabled
        lateFeeMonthlyRate = String(format: "%.1f", settings.lateFeeMonthlyRate)
        lateFeeDueDay = settings.lateFeeDueDay
        lateFeeCountryProfile = settings.lateFeeCountryProfile
        lateFeeGracePeriodDays = settings.lateFeeGracePeriodDays
        lateFeeCustomFootnote = settings.lateFeeCustomFootnote
    }

    func selectCountryProfile(_ profile: LateFeeCountryProfile) {
        lateFeeCountryProfile = profile
        lateFeeMonthlyRate = String(format: "%.1f", profile.defaultRate)
        lateFeeDueDay = profile.defaultDueDay
        lateFeeGracePeriodDays = profile.defaultGraceDays
        lateFeeCustomFootnote = ""
    }

    func loadSampleDefaults(for targetLang: AppLanguage) {
        let samples = SampleData.defaults(for: targetLang)
        apartmentName = samples.apartmentName
        issuer = samples.issuer
        defaultPayment = samples.defaultPayment
        flatCount = String(samples.flatCount)
        currency = samples.currency
        vendors = samples.defaultVendors
        expenseServices = samples.defaultServices

        var loaded: [Int: String] = [:]
        for (apt, name) in samples.residents {
            loaded[apt] = name
        }
        residents = loaded

        selectedOwner = samples.residents[selectedApartment] ?? (samples.residents[1] ?? "")
        showSampleDefaultsFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showSampleDefaultsFeedback = false
        }
    }

    func setQuickFlatCount(_ count: Int) {
        flatCount = String(count)
        let samples = SampleData.defaults(for: language)
        for (apt, name) in samples.residents {
            if apt <= count && (residents[apt] == nil || residents[apt]?.isEmpty == true) {
                residents[apt] = name
            }
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
        settings.isLateFeeEnabled = isLateFeeEnabled
        let normalizedFeeRate = lateFeeMonthlyRate.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        if let feeRate = Double(normalizedFeeRate), feeRate >= 0 {
            settings.lateFeeMonthlyRate = feeRate
        }
        settings.lateFeeDueDay = max(1, min(31, lateFeeDueDay))
        settings.lateFeeCountryProfile = lateFeeCountryProfile
        settings.lateFeeGracePeriodDays = max(0, min(60, lateFeeGracePeriodDays))
        settings.lateFeeCustomFootnote = lateFeeCustomFootnote.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.vendors = vendors
        settings.expenseServices = expenseServices

        for apt in 1...flats {
            let name = (residents[apt] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            settings.saveOwner(name.localizedCapitalized, apartmentNumber: apt)
            let phone = (residentPhones[apt] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            settings.saveOwnerPhone(phone, apartmentNumber: apt)
        }

        settings.objectWillChange.send()
        NotificationCenter.default.post(name: .settingsDidSave, object: settings)

        return true
    }
}
