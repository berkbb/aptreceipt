import AppKit
import SwiftUI
import UniformTypeIdentifiers

extension SettingsView {
    // MARK: - Tab 2: Residents Directory (Hero Scroller List)

    var residentsTab: some View {
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

    func residentCard(flat: Int) -> some View {
        let nameBinding = viewModel.bindingForResident(at: flat)
        let phoneBinding = viewModel.bindingForResidentPhone(at: flat)
        let isAssigned = !nameBinding.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        return HStack(spacing: 12) {
            // Flat Badge
            VStack(spacing: 1) {
                Text(l10n.uppercased(l10n.flatPrefix))
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
}
