import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Receipt Preview Sheet

struct ReceiptPreviewSheet: View {
    let draft: ReceiptDraft
    @ObservedObject var settings: ReceiptSettingsStore
    @Environment(\.presentationMode) private var presentationMode
    @State private var exportSuccess = false

    private var l10n: L10n { settings.l10n }

    var body: some View {
        VStack(spacing: 0) {
            // Sheet Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(l10n.previewTitle)
                        .font(.headline)
                    Text(l10n.previewSubtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Document Display Area
            ScrollView([.horizontal, .vertical]) {
                ReceiptDocumentView(
                    draft: draft,
                    apartmentName: settings.apartmentName,
                    signatureImage: settings.signatureImage,
                    l10n: l10n
                )
                .frame(width: 780, height: 540)
                .padding(24)
            }
            .background(Color(NSColor.underPageBackgroundColor).opacity(0.8))

            Divider()

            // Footer Actions
            HStack(spacing: 12) {
                if exportSuccess {
                    Label(l10n.saveSuccess, systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.callout)
                }

                Spacer()

                Button(l10n.close) {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)

                Button {
                    saveReceiptImage()
                } label: {
                    Label(l10n.saveAsJPEG, systemImage: "arrow.down.doc.fill")
                        .padding(.horizontal, 4)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 860, height: 680)
    }

    private func saveReceiptImage() {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.showsTagField = false
        panel.allowedContentTypes = [.jpeg]
        let safeReceiver = draft.receiver
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: " ", with: "_")
            .lowercased()
        let safeMonth = draft.monthYear
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: " ", with: "_")
            .lowercased()
        panel.nameFieldStringValue = "receipt_\(safeReceiver)_\(safeMonth).jpg"

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        let document = ReceiptDocumentView(
            draft: draft,
            apartmentName: settings.apartmentName,
            signatureImage: settings.signatureImage,
            l10n: l10n
        )
        .frame(width: 780, height: 540)

        let hosting = NSHostingView(rootView: document)
        hosting.frame = NSRect(x: 0, y: 0, width: 780, height: 540)
        hosting.layoutSubtreeIfNeeded()

        guard let rep = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds) else {
            return
        }

        hosting.cacheDisplay(in: hosting.bounds, to: rep)
        let image = NSImage(size: hosting.bounds.size)
        image.addRepresentation(rep)
        image.writeJPEG(toURL: url)
        exportSuccess = true
    }
}

// MARK: - Receipt Document View

struct ReceiptDocumentView: View {
    let draft: ReceiptDraft
    let apartmentName: String
    let signatureImage: NSImage?
    let l10n: L10n

    // Fixed print colors (independent of Dark Mode)
    private let textDark = Color(red: 0.10, green: 0.12, blue: 0.16)
    private let textMuted = Color(red: 0.42, green: 0.46, blue: 0.52)
    private let textSecondary = Color(red: 0.28, green: 0.32, blue: 0.38)
    private let borderNavy = Color(red: 0.16, green: 0.24, blue: 0.36)

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = l10n.locale
        return formatter.string(from: NSNumber(value: draft.amount)) ?? "₺\(draft.amount)"
    }

    private var mainTitle: String {
        apartmentName.isEmpty ? l10n.defaultBuildingName : apartmentName.uppercased()
    }

    private var receiptBadgeText: String {
        draft.kind == .income ? l10n.incomeBadge : l10n.outcomeBadge
    }

    private var badgeColor: Color {
        draft.kind == .income ? Color(red: 0.12, green: 0.52, blue: 0.24) : Color(red: 0.82, green: 0.34, blue: 0.12)
    }

    private var badgeBackground: Color {
        draft.kind == .income ? Color(red: 0.92, green: 0.97, blue: 0.93) : Color(red: 0.99, green: 0.94, blue: 0.92)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Bar
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(mainTitle)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(textDark)
                    Text(receiptBadgeText)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(badgeColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(badgeBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(l10n.receiptNo)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(textMuted)
                        Text(String(format: "#%04d", draft.sequenceNumber))
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(textDark)
                    }

                    HStack(spacing: 4) {
                        Text(l10n.issueDate)
                            .font(.system(size: 11))
                            .foregroundColor(textMuted)
                        Text(draft.createdDate)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(textDark)
                    }
                }
            }
            .padding(.bottom, 12)

            // Double header rule
            Rectangle()
                .fill(borderNavy)
                .frame(height: 2.5)
            Rectangle()
                .fill(borderNavy.opacity(0.35))
                .frame(height: 1)
                .padding(.top, 2)
                .padding(.bottom, 16)

            // Metadata Grid
            VStack(spacing: 12) {
                HStack(alignment: .top) {
                    receiptField(label: l10n.receiverLabel, value: draft.receiver)
                    if draft.showApartmentNumber {
                        receiptField(label: l10n.flatNumber, value: "\(l10n.flatPrefix) \(draft.apartmentNumber)")
                    } else {
                        receiptField(label: l10n.flatNumber, value: "—")
                    }
                }

                HStack(alignment: .top) {
                    receiptField(label: l10n.issuerLabel, value: draft.issuer)
                    receiptField(label: l10n.period, value: draft.monthYear)
                }
            }
            .padding(.bottom, 16)

            // Amount Highlight Box
            HStack {
                Text(l10n.totalCollected)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(textDark)

                Spacer()

                Text(formattedAmount)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(badgeColor)
            }
            .padding(14)
            .background(badgeBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(badgeColor.opacity(0.4), lineWidth: 1.5)
            )
            .padding(.bottom, 14)

            // Description Box
            VStack(alignment: .leading, spacing: 6) {
                Text(l10n.descriptionHeader)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(textMuted)

                Text(draft.notes.isEmpty ? "-" : draft.notes)
                    .font(.system(size: 12))
                    .foregroundColor(textDark)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color(red: 0.96, green: 0.97, blue: 0.98))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(red: 0.88, green: 0.90, blue: 0.93), lineWidth: 1)
                    )
            }

            Spacer(minLength: 12)

            // Footer Signature & Disclaimer
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(l10n.electronicDisclaimer)
                        .font(.system(size: 9))
                        .foregroundColor(textMuted)
                    Text("\(l10n.appTitle) v3.2.0 • \(l10n.publisher)")
                        .font(.system(size: 9))
                        .foregroundColor(textMuted.opacity(0.8))
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    if let signatureImage {
                        Image(nsImage: signatureImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 54)
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 130, height: 40)
                    }

                    Rectangle()
                        .fill(textMuted.opacity(0.5))
                        .frame(width: 140, height: 1)

                    Text(l10n.authorizedSignature)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(textSecondary)
                }
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(red: 0.82, green: 0.86, blue: 0.92), lineWidth: 1.5)
        )
    }

    private func receiptField(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(textMuted)
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(textDark)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - NSImage Extension

extension NSImage {
    func writeJPEG(toURL url: URL) {
        guard
            let data = tiffRepresentation,
            let rep = NSBitmapImageRep(data: data),
            let imageData = rep.representation(using: .jpeg, properties: [.compressionFactor: NSNumber(value: 0.95)])
        else {
            return
        }

        do {
            try imageData.write(to: url)
        } catch {
            return
        }
    }
}
