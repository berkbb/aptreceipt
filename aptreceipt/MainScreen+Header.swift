import AppKit
import SwiftUI
import UniformTypeIdentifiers

extension MainScreen {
    // MARK: - Header Bar

    var headerBar: some View {
        HStack(spacing: 12) {
            if let logo = settings.logoImage {
                Image(nsImage: logo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
            } else if let icon = NSApplication.shared.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .shadow(color: Color.black.opacity(0.12), radius: 3, x: 0, y: 1)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(l10n.appTitle)
                        .font(.system(size: 18, weight: .bold))
                    if !settings.apartmentName.isEmpty {
                        Text(settings.apartmentName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                Text(l10n.appSubtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Financial Report & Cash Balance Button
            Button {
                viewModel.isPresentingFinancialReport = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))
                    Text(l10n.financialSummaryTab)
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .help(l10n.financialReportTitle)

            // Batch Dues Button
            Button {
                viewModel.isPresentingBatchDues = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.orange)
                    Text(l10n.batchDuesTitle)
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .help(l10n.batchDuesSubtitle)

            // Archive Button
            Button {
                viewModel.isPresentingArchive = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "archivebox.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text(l10n.archiveButton)
                        .font(.system(size: 12, weight: .medium))
                    if !ReceiptArchiveStore.shared.records.isEmpty {
                        Text("\(ReceiptArchiveStore.shared.records.count)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .help(l10n.archiveTitle)

            // Settings Button
            Button {
                openSettingsWindow()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(2)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .help(l10n.preferences)
            .accessibilityLabel(l10n.preferences)
            .keyboardShortcut(",", modifiers: .command)
        }
    }

    func openSettingsWindow() {
        SettingsWindowManager.shared.show(settings: settings)
    }
}
