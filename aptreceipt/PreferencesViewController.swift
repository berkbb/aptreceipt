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
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.presentationMode) private var presentationMode

    init(settings: ReceiptSettingsStore, initialTab: SettingsTab = .general) {
        self.settings = settings
        let vm = SettingsViewModel()
        vm.selectedTab = initialTab
        _viewModel = StateObject(wrappedValue: vm)
    }

    private var l10n: L10n {
        L10n(viewModel.language)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                if let icon = NSApplication.shared.applicationIconImage {
                    Image(nsImage: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                } else {
                    Image(systemName: "gearshape.2.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundColor(.accentColor)
                }

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

            // Tab Bar (Hero Segmented Deck)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(SettingsTab.allCases) { tab in
                        let isSelected = viewModel.selectedTab == tab
                        Button {
                            viewModel.selectedTab = tab
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: tab.iconName)
                                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                Text(tab.title(l10n: l10n))
                                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                isSelected
                                ? Color.accentColor.opacity(0.18)
                                : Color.clear
                            )
                            .foregroundColor(isSelected ? .accentColor : .secondary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(isSelected ? Color.accentColor.opacity(0.35) : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(Color(NSColor.controlBackgroundColor).opacity(0.6))

            Divider()

            // Active Tab Content
            ScrollView {
                VStack(spacing: 16) {
                    switch viewModel.selectedTab {
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
                .padding(20)
            }
            .frame(maxHeight: .infinity)

            Divider()

            // Footer Buttons
            HStack {
                Button(l10n.cancel) {
                    presentationMode.wrappedValue.dismiss()
                    SettingsWindowManager.shared.close()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(l10n.saveAndClose) {
                    if viewModel.save(to: settings) {
                        NotificationCenter.default.post(name: .settingsDidSave, object: settings)
                        presentationMode.wrappedValue.dismiss()
                        SettingsWindowManager.shared.close()
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 800, idealWidth: 840, minHeight: 580, idealHeight: 640)
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
            // Hero Showcase: Apartman Başlık & Durum Kartı
            buildingHeroCard

            // Group 1: Apartman Bilgileri & Hızlı Daire Seçici
            VStack(alignment: .leading, spacing: 12) {
                Label(l10n.buildingDetails, systemImage: "building.2.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)

                settingsField(title: l10n.buildingName, text: $viewModel.apartmentName, placeholder: l10n.buildingNamePlaceholder)
                settingsField(title: l10n.defaultManager, text: $viewModel.issuer, placeholder: l10n.defaultManagerPlaceholder)

                // Total Flats with Interactive Hero Chips
                VStack(alignment: .leading, spacing: 8) {
                    settingsField(title: l10n.totalFlats, text: $viewModel.flatCount, placeholder: l10n.totalFlatsPlaceholder)

                    HStack(spacing: 8) {
                        Text(l10n.heroQuickFlats)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .frame(width: 200, alignment: .leading)

                        HStack(spacing: 5) {
                            ForEach([6, 8, 10, 12, 16, 20, 24, 30], id: \.self) { count in
                                let isSelected = viewModel.flatCount == String(count)
                                Button {
                                    viewModel.setQuickFlatCount(count)
                                } label: {
                                    Text("\(count)")
                                        .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                        .padding(.horizontal, 9)
                                        .padding(.vertical, 4)
                                        .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.12))
                                        .foregroundColor(isSelected ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))


            // Group 2: Mali Ayarlar & Hero Para Birimi Kartları
            VStack(alignment: .leading, spacing: 12) {
                Label(l10n.financialSettings, systemImage: "banknote.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)

                settingsField(title: "\(l10n.defaultDues) (\(viewModel.currency.symbol))", text: $viewModel.defaultPayment, placeholder: "1750")
                settingsField(title: l10n.nextReceiptNo, text: $viewModel.sequenceNumber, placeholder: "1")

                VStack(alignment: .leading, spacing: 8) {
                    Text(l10n.currencySelection)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    currencyHeroDeck
                }
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Group: Kat Mülkiyeti Kanunu (KMK Md. 20) Gecikme Tazminatı
            lateFeeSettingsCard

            // Group 3: Hızlı Başlangıç Senaryo Kartları
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Label(l10n.quickScenarioTitle, systemImage: "sparkles.rectangle.stack.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                        Text(l10n.quickScenarioSubtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
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

                HStack(spacing: 10) {
                    scenarioHeroCard(
                        flag: "🇹🇷",
                        title: l10n.sampleScenarioTR,
                        desc: l10n.sampleScenarioDescTR,
                        lang: .turkish,
                        color: .red
                    )

                    scenarioHeroCard(
                        flag: "🇬🇧",
                        title: l10n.sampleScenarioEN,
                        desc: l10n.sampleScenarioDescEN,
                        lang: .english,
                        color: .blue
                    )

                    scenarioHeroCard(
                        flag: "🇷🇴",
                        title: l10n.sampleScenarioRO,
                        desc: l10n.sampleScenarioDescRO,
                        lang: .romanian,
                        color: .yellow
                    )
                }
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Kat Mülkiyeti Kanunu (KMK Md. 20) Gecikme Tazminatı Card

    private var lateFeeSettingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "scalemass.fill")
                    .font(.system(size: 15))
                    .foregroundColor(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(l10n.lateFeeTitle)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                    Text(l10n.lateFeeSubtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Toggle("", isOn: $viewModel.isLateFeeEnabled)
                    .toggleStyle(.switch)
            }

            if viewModel.isLateFeeEnabled {
                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    // Manual Rate Entry & Presets
                    HStack(alignment: .center, spacing: 12) {
                        Text(l10n.lateFeeMonthlyRateTitle)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 170, alignment: .leading)

                        HStack(spacing: 4) {
                            Text("%")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                            TextField("5.0", text: $viewModel.lateFeeMonthlyRate)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .frame(width: 55)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color(NSColor.textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )

                        // Quick Chips: [%3.0], [%5.0 Kanuni], [%7.5], [%10.0]
                        HStack(spacing: 5) {
                            ForEach([3.0, 5.0, 7.5, 10.0], id: \.self) { rate in
                                let isSelected = (Double(viewModel.lateFeeMonthlyRate.replacingOccurrences(of: ",", with: ".")) ?? -1) == rate
                                Button {
                                    viewModel.lateFeeMonthlyRate = String(format: "%.1f", rate)
                                } label: {
                                    Text(rate == 5.0 ? l10n.statutoryRateChip : "%\(String(format: "%.1f", rate))")
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
                    }

                    // Monthly Due Day (Grace Threshold)
                    HStack(spacing: 12) {
                        Text(l10n.lateFeeDueDayTitle)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 170, alignment: .leading)

                        HStack(spacing: 8) {
                            Text(l10n.dueDayDayPrefix)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)

                            Picker("", selection: $viewModel.lateFeeDueDay) {
                                ForEach(1...31, id: \.self) { day in
                                    Text("\(day)").tag(day)
                                }
                            }
                            .frame(width: 65)

                            Text(l10n.dueDayDaySuffix)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }

                    // Legal Footnote
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                            .padding(.top, 2)
                        Text(l10n.lateFeeLegalNotice)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Building Hero Showcase Card

    private var buildingHeroCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Interactive Building Logo Avatar
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
                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)

                // Building Identity Details
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(l10n.buildingHeroBadge)
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.accentColor.opacity(0.14))
                            .foregroundColor(.accentColor)
                            .clipShape(Capsule())

                        if settings.logoImage != nil {
                            HStack(spacing: 3) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 10))
                                Text(l10n.activeLogoBadge)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.green)
                            }
                        } else {
                            HStack(spacing: 3) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.accentColor)
                                    .font(.system(size: 10))
                                Text(l10n.default2DLogoBadge)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Text(viewModel.apartmentName.isEmpty ? l10n.buildingNamePlaceholder : viewModel.apartmentName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(viewModel.apartmentName.isEmpty ? .secondary : .primary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.shield.checkmark.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(viewModel.issuer.isEmpty ? l10n.heroNotSpecified : "\(l10n.heroStatsManager): \(viewModel.issuer)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Logo Action Buttons
                VStack(spacing: 6) {
                    Button {
                        settings.importLogo()
                    } label: {
                        Label(l10n.uploadLogoButton, systemImage: "arrow.up.doc.fill")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    if settings.logoImage != nil {
                        Button(role: .destructive) {
                            settings.clearLogo()
                        } label: {
                            Label(l10n.removeLogoButton, systemImage: "trash.fill")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }

            Divider()

            // 4 Live Stats Chips
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
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [
                    Color(NSColor.controlBackgroundColor),
                    Color(NSColor.controlBackgroundColor).opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
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

    // MARK: - Scenario Hero Card

    private func scenarioHeroCard(flag: String, title: String, desc: String, lang: AppLanguage, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(flag)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .lineLimit(1)
            }

            Text(desc)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Button {
                viewModel.loadSampleDefaults(for: lang)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 10))
                    Text(l10n.applyScenarioButton)
                        .font(.system(size: 10, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 110)
        .background(Color(NSColor.textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
        )
    }

    // MARK: - Currency Hero Deck

    private var currencyHeroDeck: some View {
        HStack(spacing: 8) {
            ForEach(AppCurrency.allCases) { curr in
                let isSelected = viewModel.currency == curr
                Button {
                    viewModel.currency = curr
                    settings.currency = curr
                } label: {
                    HStack(spacing: 6) {
                        Text(curr.symbol)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isSelected ? .accentColor : .secondary)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(curr.code)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(isSelected ? .primary : .secondary)
                            Text(curr.title(l10n: l10n))
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        isSelected
                        ? Color.accentColor.opacity(0.12)
                        : Color(NSColor.textBackgroundColor)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.18), lineWidth: isSelected ? 1.5 : 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Tab 2: Residents Directory (Hero Scroller List)

    private var residentsTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Label(l10n.residentsDirectoryTitle, systemImage: "person.2.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text(l10n.residentsDirectoryDesc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            // Hero Summary & Action Bar
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    // Total Flats Badge
                    HStack(spacing: 5) {
                        Image(systemName: "building.2.fill")
                            .foregroundColor(.accentColor)
                        Text("\(viewModel.availableApartments.count) \(l10n.totalFlatsBadge)")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(Capsule())

                    // Registered Badge
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(viewModel.registeredCount) \(l10n.registeredResidentsBadge)")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.green.opacity(0.12))
                    .clipShape(Capsule())

                    // Unassigned Badge
                    if viewModel.unassignedCount > 0 {
                        HStack(spacing: 5) {
                            Image(systemName: "circle.dashed")
                                .foregroundColor(.orange)
                            Text("\(viewModel.unassignedCount) \(l10n.vacantFlatsBadge)")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(Capsule())
                    }

                    Spacer()

                    // Quick Action: Fill Sample Residents
                    Button {
                        viewModel.fillSampleResidents(for: viewModel.language)
                    } label: {
                        Label(l10n.fillSampleResidentsButton, systemImage: "sparkles")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    // Quick Action: Clear All
                    Button(role: .destructive) {
                        viewModel.clearAllResidents()
                    } label: {
                        Label(l10n.clearAllResidentsButton, systemImage: "trash")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                // Search & Filter Bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))

                    TextField(l10n.searchNeighborsPlaceholder, text: $viewModel.residentSearchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))

                    if !viewModel.residentSearchQuery.isEmpty {
                        Button {
                            viewModel.residentSearchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(NSColor.textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Flats Hero List
            if viewModel.filteredApartments.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text(l10n.noMatchingResidents)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.filteredApartments, id: \.self) { flat in
                        residentCard(flat: flat)
                    }
                }
            }
        }
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
                TextField(l10n.residentNamePlaceholder, text: nameBinding)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium))

                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        TextField(l10n.residentPhonePlaceholder, text: phoneBinding)
                            .textFieldStyle(.plain)
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
                .help(l10n.clearAllResidentsButton)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isAssigned ? Color.accentColor.opacity(0.25) : Color.secondary.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Tab: Vendors & Services

    private var vendorsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Label(l10n.vendorsTitle, systemImage: "briefcase.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text(l10n.vendorsSubtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            // Hero Status Bar
            HStack(spacing: 8) {
                // Registered Vendors Badge
                HStack(spacing: 5) {
                    Image(systemName: "building.2.fill")
                        .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))
                    Text("\(viewModel.vendors.count) \(l10n.registeredVendorsBadge)")
                        .font(.system(size: 11, weight: .semibold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(red: 0.22, green: 0.42, blue: 0.88).opacity(0.12))
                .clipShape(Capsule())

                // Preset Services Badge
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.orange)
                    Text("\(viewModel.expenseServices.count) \(l10n.presetServicesBadge)")
                        .font(.system(size: 11, weight: .semibold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.orange.opacity(0.12))
                .clipShape(Capsule())

                Spacer()

                // Restore Defaults
                Button {
                    viewModel.loadSampleVendorsAndServices(for: viewModel.language)
                } label: {
                    Label(l10n.loadSampleVendorsButton, systemImage: "arrow.counterclockwise")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            // Success feedback banner
            if viewModel.showSampleVendorsFeedback {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(l10n.sampleVendorsLoadedFeedback)
                        .font(.system(size: 11, weight: .medium))
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // Section 1: Vendor Directory
            VStack(alignment: .leading, spacing: 10) {
                Label(l10n.vendorListHeader, systemImage: "building.2.crop.circle.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)

                // Add Vendor Box
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        TextField(l10n.vendorNameField, text: $viewModel.newVendorName)
                            .textFieldStyle(.roundedBorder)
                        TextField(l10n.vendorCategoryField, text: $viewModel.newVendorCategory)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 150)
                    }

                    HStack(spacing: 8) {
                        TextField(l10n.vendorContactField, text: $viewModel.newVendorContact)
                            .textFieldStyle(.roundedBorder)

                        Button {
                            viewModel.addVendor()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text(l10n.saveVendorButton)
                            }
                            .font(.system(size: 11, weight: .semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                        .disabled(viewModel.newVendorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(10)
                .background(Color(NSColor.textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Search Bar
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField(l10n.searchVendorsPlaceholder, text: $viewModel.vendorSearchQuery)
                        .textFieldStyle(.plain)
                    if !viewModel.vendorSearchQuery.isEmpty {
                        Button {
                            viewModel.vendorSearchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color(NSColor.textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))

                // Vendor List
                if viewModel.filteredVendors.isEmpty {
                    Text(l10n.noVendorsFound)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 6) {
                        ForEach(viewModel.filteredVendors) { vendor in
                            HStack(spacing: 10) {
                                Image(systemName: "building.2.fill")
                                    .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))
                                    .font(.system(size: 13))

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
                                        .font(.system(size: 11))
                                        .foregroundColor(.red.opacity(0.8))
                                }
                                .buttonStyle(.plain)
                                .help(l10n.deleteButton)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color(NSColor.textBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Section 2: Ready-Made Services
            VStack(alignment: .leading, spacing: 10) {
                Label(l10n.serviceListHeader, systemImage: "sparkles.rectangle.stack.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)

                // Add Service Box
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        TextField(l10n.serviceNameField, text: $viewModel.newServiceName)
                            .textFieldStyle(.roundedBorder)
                        TextField(l10n.serviceSuggestedVendorField, text: $viewModel.newServiceSuggestedVendor)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 170)
                    }

                    HStack(spacing: 8) {
                        TextField(l10n.serviceDescriptionField, text: $viewModel.newServiceDescription)
                            .textFieldStyle(.roundedBorder)

                        Button {
                            viewModel.addExpenseService()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text(l10n.saveServiceButton)
                            }
                            .font(.system(size: 11, weight: .semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                        .disabled(viewModel.newServiceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(10)
                .background(Color(NSColor.textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Service List
                if viewModel.expenseServices.isEmpty {
                    Text(l10n.noServicesFound)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 6) {
                        ForEach(viewModel.expenseServices) { service in
                            HStack(spacing: 10) {
                                Image(systemName: service.iconName.isEmpty ? "briefcase.fill" : service.iconName)
                                    .foregroundColor(.orange)
                                    .font(.system(size: 13))

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
                                        .font(.system(size: 11))
                                        .foregroundColor(.red.opacity(0.8))
                                }
                                .buttonStyle(.plain)
                                .help(l10n.deleteButton)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color(NSColor.textBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Tab: Appearance & Language

    private var appearanceTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Theme selection (Hero Deck)
            VStack(alignment: .leading, spacing: 10) {
                Label(l10n.appearanceSection, systemImage: "circle.righthalf.filled")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)

                themeHeroDeck
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Language selection (Hero Deck)
            VStack(alignment: .leading, spacing: 10) {
                Label(l10n.languageSection, systemImage: "globe")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)

                languageHeroDeck

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

            // Currency selection (Hero Deck)
            VStack(alignment: .leading, spacing: 10) {
                Label(l10n.currencySection, systemImage: "coloncurrencysign.circle.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)

                currencyHeroDeck
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Theme Hero Deck

    private var themeHeroDeck: some View {
        HStack(spacing: 10) {
            ForEach(AppTheme.allCases) { theme in
                let isSelected = viewModel.theme == theme
                Button {
                    viewModel.theme = theme
                    settings.theme = theme
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: themeIcon(theme))
                            .font(.system(size: 13))
                            .foregroundColor(isSelected ? .accentColor : .secondary)
                        Text(theme.title(l10n: l10n))
                            .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? .primary : .secondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        isSelected
                        ? Color.accentColor.opacity(0.14)
                        : Color(NSColor.textBackgroundColor)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: isSelected ? 1.5 : 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func themeIcon(_ theme: AppTheme) -> String {
        switch theme {
        case .system: return "laptopcomputer"
        case .light: return "sun.max.fill"
        case .dark: return "moon.stars.fill"
        }
    }

    // MARK: - Language Hero Deck

    private var languageHeroDeck: some View {
        let columns = [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]
        return LazyVGrid(columns: columns, spacing: 10) {
            languageHeroCard(lang: .turkish, flag: "🇹🇷", title: "Türkçe", desc: l10n.langDescTR)
            languageHeroCard(lang: .english, flag: "🇬🇧", title: "English", desc: l10n.langDescEN)
            languageHeroCard(lang: .romanian, flag: "🇷🇴", title: "Română", desc: l10n.langDescRO)
            languageHeroCard(lang: .system, flag: "🌐", title: l10n.langSystem, desc: l10n.langDescSystem)
        }
    }

    private func languageHeroCard(lang: AppLanguage, flag: String, title: String, desc: String) -> some View {
        let isSelected = viewModel.language == lang
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                viewModel.language = lang
                settings.language = lang
                let resolved = L10n(lang).resolvedLanguage
                let newCurrency = AppCurrency.default(for: resolved)
                viewModel.currency = newCurrency
                settings.currency = newCurrency

                let sampleApts = [
                    SampleData.defaults(for: .english).apartmentName,
                    SampleData.defaults(for: .turkish).apartmentName,
                    SampleData.defaults(for: .romanian).apartmentName
                ]
                if sampleApts.contains(viewModel.apartmentName) || viewModel.apartmentName.isEmpty {
                    viewModel.loadSampleDefaults(for: lang)
                    _ = viewModel.save(to: settings)
                }
                viewModel.showRestartAlert = true
            }
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Text(flag)
                    .font(.system(size: 24))
                    .frame(width: 34, height: 34)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(isSelected ? .primary : .secondary)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                                .font(.system(size: 13))
                        }
                    }

                    Text(desc)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected
                ? Color.accentColor.opacity(0.12)
                : Color(NSColor.textBackgroundColor)
            )
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.18), lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
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

    // MARK: - Tab: Backup & Restore

    private var backupTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Hero Header
            HStack(spacing: 14) {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 3) {
                    Text(l10n.backupTitle)
                        .font(.system(size: 16, weight: .bold))
                    Text(l10n.backupSubtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Notice Box
            HStack(spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.accentColor)
                    .font(.title3)
                Text(l10n.backupNotice)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color.accentColor.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Feedback Message
            if let msg = viewModel.backupSuccessMessage {
                Label(msg, systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.callout.bold())
                    .padding(8)
            } else if let err = viewModel.backupErrorMessage {
                Label(err, systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.callout.bold())
                    .padding(8)
            }

            // Action Cards
            VStack(spacing: 12) {
                // Export Card
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(l10n.exportBackupButton)
                            .font(.system(size: 13, weight: .bold))
                        Text("\(viewModel.availableApartments.count) \(l10n.totalFlatsBadge) • \(ReceiptArchiveStore.shared.records.count) \(l10n.totalArchived)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button {
                        exportFullBackup()
                    } label: {
                        Label(l10n.exportBackupButton, systemImage: "square.and.arrow.up.fill")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }
                .padding(14)
                .background(Color(NSColor.textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                )

                // Import Card
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(l10n.importBackupButton)
                            .font(.system(size: 13, weight: .bold))
                        Text(l10n.backupSubtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button {
                        importFullBackup()
                    } label: {
                        Label(l10n.importBackupButton, systemImage: "square.and.arrow.down.fill")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                }
                .padding(14)
                .background(Color(NSColor.textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                )
            }
        }
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
        VStack(spacing: 16) {
            if let icon = NSApplication.shared.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 76, height: 76)
                    .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 3)
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
                        settings.showLicenseViewer = true
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
        .sheet(isPresented: $settings.showLicenseViewer) {
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
