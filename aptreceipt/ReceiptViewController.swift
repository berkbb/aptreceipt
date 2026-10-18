import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Receipt Preview Sheet

struct ReceiptPreviewSheet: View {
    let draft: ReceiptDraft
    @ObservedObject var settings: ReceiptSettingsStore
    @Environment(\.presentationMode) private var presentationMode
    @State private var exportSuccess = false

    var body: some View {
        VStack(spacing: 0) {
            // Sheet Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Makbuz Önizleme")
                        .font(.headline)
                    Text("Oluşturulan makbuzu inceleyin ve cihazınıza kaydedin")
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
                    signatureImage: settings.signatureImage
                )
                .frame(width: 780, height: 540)
                .padding(24)
            }
            .background(Color(NSColor.underPageBackgroundColor).opacity(0.8))

            Divider()

            // Footer Actions
            HStack(spacing: 12) {
                if exportSuccess {
                    Label("Makbuz başarıyla kaydedildi!", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.callout)
                }

                Spacer()

                Button("Kapat") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)

                Button {
                    saveReceiptImage()
                } label: {
                    Label("JPEG Olarak Kaydet", systemImage: "arrow.down.doc.fill")
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
        panel.nameFieldStringValue = "makbuz_\(safeReceiver)_\(safeMonth).jpg"

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        let document = ReceiptDocumentView(
            draft: draft,
            apartmentName: settings.apartmentName,
            signatureImage: settings.signatureImage
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

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: NSNumber(value: draft.amount)) ?? "₺\(draft.amount)"
    }

    private var mainTitle: String {
        apartmentName.isEmpty ? "APARTMAN YÖNETİMİ" : apartmentName.uppercased()
    }

    private var receiptBadgeText: String {
        draft.kind == .income ? "TAHSİLAT MAKBUZU" : "GİDER / TEDİYE MAKBUZU"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Bar
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(mainTitle)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    Text(receiptBadgeText)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(draft.kind == .income ? Color(red: 0.1, green: 0.5, blue: 0.2) : Color(red: 0.8, green: 0.3, blue: 0.1))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("Makbuz No:")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text(String(format: "%04d", draft.sequenceNumber))
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                    }

                    HStack(spacing: 4) {
                        Text("Düzenleme:")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(draft.createdDate)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(.bottom, 14)

            // Double line divider
            Rectangle()
                .fill(Color.primary.opacity(0.8))
                .frame(height: 2)
            Rectangle()
                .fill(Color.primary.opacity(0.3))
                .frame(height: 1)
                .padding(.top, 2)
                .padding(.bottom, 16)

            // Metadata Grid
            VStack(spacing: 10) {
                HStack(alignment: .top) {
                    receiptField(label: "Ödeyen (Muhatap)", value: draft.receiver)
                    if draft.showApartmentNumber {
                        receiptField(label: "Daire No", value: "Daire \(draft.apartmentNumber)")
                    }
                }

                HStack(alignment: .top) {
                    receiptField(label: "Tahsil Eden (Yetkili)", value: draft.issuer)
                    receiptField(label: "Ait Olduğu Dönem", value: draft.monthYear)
                }
            }
            .padding(.bottom, 16)

            // Amount Highlight Box
            HStack {
                Text("Tahsil Edilen Tutar:")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                Text(formattedAmount)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(draft.kind == .income ? Color(red: 0.1, green: 0.5, blue: 0.2) : Color(red: 0.8, green: 0.3, blue: 0.1))
            }
            .padding(14)
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
            .padding(.bottom, 16)

            // Description Section
            VStack(alignment: .leading, spacing: 6) {
                Text("Açıklama:")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)

                Text(draft.notes)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color.secondary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Spacer(minLength: 12)

            // Footer Signature & Disclaimer
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Bu belge apartman yönetimi kayıtları uyarınca elektronik ortamda tanzim edilmiştir.")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    Text("Apartman Makbuzu v3.1.0 • berkbb")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary.opacity(0.8))
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    if let signatureImage {
                        Image(nsImage: signatureImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 60)
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 140, height: 44)
                    }

                    Rectangle()
                        .fill(Color.secondary.opacity(0.4))
                        .frame(width: 140, height: 1)

                    Text("Yetkili İmzası")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundColor(.black)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1.5)
        )
    }

    private func receiptField(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
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
