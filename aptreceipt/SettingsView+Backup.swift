import AppKit
import SwiftUI
import UniformTypeIdentifiers

extension SettingsView {
    // MARK: - Tab: Backup & Restore

    var backupTab: some View {
        Form {
            Section {
                LabeledContent(l10n.totalFlatsBadge, value: "\(viewModel.availableApartments.count)")
                LabeledContent(l10n.totalArchived, value: "\(ReceiptArchiveStore.shared.records.count)")

                // One row per action keeps both long labels fully readable.
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

            verificationKeySection
        }
        .formStyle(.grouped)
    }

    /// The verification key's recovery code, to write down, and restoring a key from one. Applies at once,
    /// like importing a backup, because it does not touch the settings draft.
    var verificationKeySection: some View {
        Section {
            Button {
                showsRecoveryCode.toggle()
            } label: {
                Label(showsRecoveryCode ? l10n.recoveryCodeHide : l10n.recoveryCodeShow, systemImage: showsRecoveryCode ? "eye.slash" : "key.fill")
            }
            .buttonStyle(.bordered)

            if showsRecoveryCode {
                let code = ReceiptVerificationKeyStore.shared.recoveryCode()
                Text(code)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Label(l10n.recoveryCodeWarning, systemImage: "exclamationmark.shield.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(code, forType: .string)
                        recoveryCodeMessage = (l10n.recoveryCodeCopied, false)
                    } label: {
                        Label(l10n.recoveryCodeCopy, systemImage: "doc.on.doc")
                    }
                }
            }

            HStack {
                TextField(l10n.recoveryCodeRestoreTitle, text: $recoveryCodeInput)
                    .font(.system(size: 12, design: .monospaced))
                Button(l10n.recoveryCodeRestoreButton) {
                    if ReceiptVerificationKeyStore.shared.restore(recoveryCode: recoveryCodeInput) {
                        recoveryCodeInput = ""
                        recoveryCodeMessage = (l10n.recoveryCodeRestored, false)
                    } else {
                        recoveryCodeMessage = (l10n.recoveryCodeInvalid, true)
                    }
                }
                .disabled(recoveryCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if let message = recoveryCodeMessage {
                Label(message.text, systemImage: message.isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .foregroundColor(message.isError ? .red : .green)
                    .font(.callout.bold())
                    .fixedSize(horizontal: false, vertical: true)
            }
        } header: {
            Text(l10n.verificationKeyTitle)
        } footer: {
            Text(l10n.verificationKeyFooter)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    func exportFullBackup() {
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

    func importFullBackup() {
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
}
