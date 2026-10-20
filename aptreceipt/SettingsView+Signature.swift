import AppKit
import SwiftUI
import UniformTypeIdentifiers

extension SettingsView {
    // MARK: - Tab 4: Signature

    var signatureTab: some View {
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
}
