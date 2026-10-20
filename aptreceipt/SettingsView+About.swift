import AppKit
import SwiftUI
import UniformTypeIdentifiers

extension SettingsView {
    // MARK: - Tab 5: About (Gözden geçirilmiş)

    var aboutTab: some View {
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
    }

    @ViewBuilder
    var updateStatusView: some View {
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
