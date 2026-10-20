import AppKit
import SwiftUI
import UniformTypeIdentifiers

extension MainScreen {
    // Invoice Import Hero Card with Drag & Drop and Apple Vision OCR
    var invoiceImportHeroCard: some View {
        VStack(spacing: 6) {
            if viewModel.isScanningInvoice {
                HStack(spacing: 10) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(l10n.scanningInvoice)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(red: 0.22, green: 0.42, blue: 0.88).opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(red: 0.22, green: 0.42, blue: 0.88).opacity(0.25), lineWidth: 1)
                )
            } else if let path = viewModel.attachedInvoicePath {
                HStack(spacing: 10) {
                    Image(systemName: "doc.badge.arrow.up.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.green)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(l10n.attachedInvoice)
                                .font(.system(size: 11, weight: .bold))
                            Text(URL(fileURLWithPath: path).lastPathComponent)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        if let banner = viewModel.invoiceScanBanner {
                            Text(banner)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // View invoice button
                    Button {
                        InvoiceAttachmentManager.shared.openAttachment(at: path)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "eye.fill")
                            Text(l10n.viewInvoice)
                        }
                        .font(.system(size: 10, weight: .semibold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    // Remove invoice button
                    Button {
                        viewModel.removeAttachedInvoice()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(l10n.removeInvoice)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
            } else {
                Button {
                    chooseInvoiceFile()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "doc.viewfinder.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(l10n.importInvoice)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))
                            Text(l10n.dropInvoiceSubtitle)
                                .font(.system(size: 9.5))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "arrow.up.doc.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        isInvoiceDropTargeted
                        ? Color(red: 0.22, green: 0.42, blue: 0.88).opacity(0.15)
                        : Color(red: 0.22, green: 0.42, blue: 0.88).opacity(0.06)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                Color(red: 0.22, green: 0.42, blue: 0.88).opacity(isInvoiceDropTargeted ? 0.7 : 0.3),
                                style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                            )
                    )
                }
                .buttonStyle(.plain)
                .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isInvoiceDropTargeted) { providers in
                    guard let provider = providers.first else { return false }
                    _ = provider.loadObject(ofClass: URL.self) { url, _ in
                        if let validURL = url {
                            DispatchQueue.main.async {
                                viewModel.importInvoice(from: validURL, settings: settings)
                            }
                        }
                    }
                    return true
                }
            }
        }
    }

    func chooseInvoiceFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if #available(macOS 11.0, *) {
            panel.allowedContentTypes = [.pdf, .png, .jpeg, .tiff]
        }
        panel.prompt = l10n.importInvoice
        if panel.runModal() == .OK, let url = panel.url {
            viewModel.importInvoice(from: url, settings: settings)
        }
    }

    func expensePresetChip(title: String, icon: String, text: String) -> some View {
        Button {
            viewModel.applyPreset(notesText: text)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.1))
            .foregroundColor(.primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }
}
