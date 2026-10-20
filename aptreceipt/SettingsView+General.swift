import AppKit
import SwiftUI
import UniformTypeIdentifiers

extension SettingsView {
    // MARK: - Tab 1: General Settings

    var generalSettingsTab: some View {
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
    func formLabel(_ text: String) -> String {
        var label = text.trimmingCharacters(in: .whitespaces)
        while label.hasSuffix(":") {
            label.removeLast()
        }
        return label.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Building Profile (logo + live summary)

    var buildingProfileSection: some View {
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

    func heroStatChip(icon: String, label: String, color: Color) -> some View {
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

    var buildingDetailsSection: some View {
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

    var financialSection: some View {
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

    var lateFeeSection: some View {
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
                            Text(rate == viewModel.lateFeeCountryProfile.defaultRate ? "\(AppFormat.percent(rate, l10n: l10n)) (\(l10n.statutoryRateLabel))" : AppFormat.percent(rate, l10n: l10n))
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

    var scenarioSection: some View {
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

    func scenarioRow(flag: String, title: String, desc: String, lang: AppLanguage) -> some View {
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
}
