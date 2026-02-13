import AppKit
import SwiftUI

struct ReceiptPreviewSheet: View {
    let draft: ReceiptDraft
    @ObservedObject var settings: ReceiptSettingsStore
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        VStack(spacing: 16) {
            ReceiptDocumentView(draft: draft, apartmentName: settings.apartmentName, signatureImage: settings.signatureImage)
                .frame(width: 760, height: 520)
                .padding(16)
                .background(Color.gray.opacity(0.08))

            HStack {
                Spacer()
                Button("Kapat") {
                    presentationMode.wrappedValue.dismiss()
                }
                Button("JPEG Olarak Kaydet") {
                    saveReceiptImage()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private func saveReceiptImage() {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.showsTagField = false
        panel.allowedFileTypes = ["jpg"]
        panel.nameFieldStringValue = "\(draft.receiver.lowercased())_\(draft.monthYear.lowercased()).jpg"

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        let document = ReceiptDocumentView(
            draft: draft,
            apartmentName: settings.apartmentName,
            signatureImage: settings.signatureImage
        )
        .frame(width: 760, height: 520)

        let hosting = NSHostingView(rootView: document)
        hosting.frame = NSRect(x: 0, y: 0, width: 760, height: 520)
        hosting.layoutSubtreeIfNeeded()

        guard let rep = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds) else {
            return
        }

        hosting.cacheDisplay(in: hosting.bounds, to: rep)
        let image = NSImage(size: hosting.bounds.size)
        image.addRepresentation(rep)
        image.writeJPEG(toURL: url)
    }
}

struct ReceiptDocumentView: View {
    let draft: ReceiptDraft
    let apartmentName: String
    let signatureImage: NSImage?

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .current
        return formatter.string(from: NSNumber(value: draft.amount)) ?? "\(draft.amount)"
    }

    private var title: String {
        let base = apartmentName.isEmpty ? "Apartman" : apartmentName
        switch draft.kind {
        case .income:
            return "\(base) Gelir Makbuzu"
        case .outcome:
            return "\(base) Gider Makbuzu"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 26, weight: .bold))

            Divider()

            receiptRow(label: "Tahsil Eden", value: draft.issuer)
            receiptRow(label: "Ödeyen", value: draft.receiver)
            receiptRow(label: "Dönem", value: draft.monthYear)

            if draft.showApartmentNumber {
                receiptRow(label: "Daire", value: "\(draft.apartmentNumber)")
            }

            receiptRow(label: "Tutar", value: formattedAmount)
            receiptRow(label: "Sıra No", value: "\(draft.sequenceNumber)")
            receiptRow(label: "Tarih", value: draft.createdDate)

            VStack(alignment: .leading, spacing: 6) {
                Text("Açıklama")
                    .font(.headline)
                Text(draft.notes)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 8)

            if let signatureImage {
                VStack(alignment: .leading, spacing: 4) {
                    Text("İmza")
                        .font(.headline)
                    Image(nsImage: signatureImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 80)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundColor(.black)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        )
    }

    @ViewBuilder
    private func receiptRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.headline)
                .frame(width: 120, alignment: .leading)
            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

extension NSImage {
    func writeJPEG(toURL url: URL) {
        guard
            let data = tiffRepresentation,
            let rep = NSBitmapImageRep(data: data),
            let imageData = rep.representation(using: .jpeg, properties: [.compressionFactor: NSNumber(value: 1.0)])
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
