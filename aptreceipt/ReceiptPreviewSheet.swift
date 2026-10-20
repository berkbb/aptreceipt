import AppKit
import SwiftUI
import UniformTypeIdentifiers
@preconcurrency import Vision
import PDFKit

// MARK: - Receipt Preview Sheet

struct ReceiptPreviewSheet: View {
    let draft: ReceiptDraft
    @ObservedObject var settings: ReceiptSettingsStore
    @Environment(\.presentationMode) private var presentationMode
    @State private var successMessage: String?

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

            // Document Display Area (A4 595 x 842 points)
            ScrollView([.horizontal, .vertical]) {
                VStack {
                    ReceiptDocumentView(
                        draft: draft,
                        apartmentName: settings.apartmentName,
                        signatureImage: settings.signatureImage,
                        logoImage: settings.logoImage,
                        l10n: l10n
                    )
                    .frame(width: 595, height: 842)
                    .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 4)
                    .padding(30)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(NSColor.underPageBackgroundColor).opacity(0.85))

            Divider()

            // Footer Actions: two rows so every label fits at 760 pt in all three languages.
            VStack(spacing: 10) {
                // Share row
                HStack(spacing: 10) {
                    Button {
                        shareWhatsApp()
                    } label: {
                        Label(l10n.shareWhatsApp, systemImage: "message.fill")
                            .foregroundColor(.green)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        shareEmail()
                    } label: {
                        Label(l10n.shareEmail, systemImage: "envelope.fill")
                    }
                    .buttonStyle(.bordered)

                    // View Attached Invoice Button (If Available)
                    if let path = draft.invoiceAttachmentPath, !path.isEmpty {
                        Button {
                            InvoiceAttachmentManager.shared.openAttachment(at: path)
                        } label: {
                            Label(l10n.viewAttachedInvoice, systemImage: "doc.text.magnifyingglass")
                                .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))
                        }
                        .buttonStyle(.bordered)
                    }

                    Spacer(minLength: 8)

                    if let msg = successMessage {
                        Label(msg, systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.callout)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

                // Save row
                HStack(spacing: 10) {
                    Button(l10n.close) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.cancelAction)

                    Spacer()

                    Button {
                        saveReceiptImage()
                    } label: {
                        Label(l10n.saveAsJPEG, systemImage: "photo.fill")
                            .padding(.horizontal, 4)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        saveReceiptPDF()
                    } label: {
                        Label(l10n.saveAsPDF, systemImage: "doc.text.fill")
                            .padding(.horizontal, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .lineLimit(1)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 760, height: 800)
    }

    private func shareWhatsApp() {
        let phone = draft.apartmentNumber > 0 ? settings.ownerPhone(for: draft.apartmentNumber) : nil
        let msg = WhatsAppShareHelper.receiptSummary(draft: draft, buildingName: settings.apartmentName, l10n: l10n)
        let callingCode = WhatsAppShareHelper.defaultCallingCode(for: settings.currency)
        if let url = WhatsAppShareHelper.shareURL(phone: phone, message: msg, callingCode: callingCode) {
            NSWorkspace.shared.open(url)
        }
    }

    private func shareEmail() {
        let subject = "\(settings.apartmentName) - #\(draft.sequenceNumber) \(l10n.invoiceTypeLabel)"
        let body = WhatsAppShareHelper.receiptSummary(draft: draft, buildingName: settings.apartmentName, l10n: l10n)
        if let url = WhatsAppShareHelper.emailURL(subject: subject, body: body) {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - PDF Vector Export
    private func saveReceiptPDF() {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.showsTagField = false
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = buildExportFileName(
            draft: draft,
            apartmentName: settings.apartmentName,
            language: l10n.resolvedLanguage,
            ext: "pdf"
        )

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        let document = ReceiptDocumentView(
            draft: draft,
            apartmentName: settings.apartmentName,
            signatureImage: settings.signatureImage,
            logoImage: settings.logoImage,
            l10n: l10n
        )
        .frame(width: 595, height: 842)
        .environment(\.colorScheme, .light)

        let renderer = ImageRenderer(content: document)
        renderer.proposedSize = ProposedViewSize(width: 595, height: 842)

        var box = CGRect(origin: .zero, size: CGSize(width: 595, height: 842))
        guard let consumer = CGDataConsumer(url: url as CFURL),
              let pdfContext = CGContext(consumer: consumer, mediaBox: &box, nil) else {
            return
        }

        pdfContext.beginPDFPage(nil)
        renderer.render { size, context in
            context(pdfContext)
        }
        pdfContext.endPDFPage()
        pdfContext.closePDF()

        // If an invoice is attached, append it as Page 2+ for audit transparency
        if let invoicePath = draft.invoiceAttachmentPath,
           !invoicePath.isEmpty,
           FileManager.default.fileExists(atPath: invoicePath),
           let finalPDF = PDFDocument(url: url) {
            let invoiceURL = URL(fileURLWithPath: invoicePath)
            if invoiceURL.pathExtension.lowercased() == "pdf",
               let attachedDoc = PDFDocument(url: invoiceURL) {
                for i in 0..<attachedDoc.pageCount {
                    if let page = attachedDoc.page(at: i) {
                        finalPDF.insert(page, at: finalPDF.pageCount)
                    }
                }
                finalPDF.write(to: url)
            } else if let img = NSImage(contentsOf: invoiceURL) {
                if let validPage = PDFPage(image: img) {
                    finalPDF.insert(validPage, at: finalPDF.pageCount)
                    finalPDF.write(to: url)
                }
            }
        }

        successMessage = l10n.saveSuccessPDF
    }

    // MARK: - JPEG Bitmap Export
    private func saveReceiptImage() {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.showsTagField = false
        panel.allowedContentTypes = [.jpeg]
        panel.nameFieldStringValue = buildExportFileName(
            draft: draft,
            apartmentName: settings.apartmentName,
            language: l10n.resolvedLanguage,
            ext: "jpg"
        )

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        let document = ReceiptDocumentView(
            draft: draft,
            apartmentName: settings.apartmentName,
            signatureImage: settings.signatureImage,
            logoImage: settings.logoImage,
            l10n: l10n
        )
        .frame(width: 595, height: 842)
        .environment(\.colorScheme, .light)

        let renderer = ImageRenderer(content: document)
        renderer.scale = 2.0
        renderer.proposedSize = ProposedViewSize(width: 595, height: 842)

        if let image = renderer.nsImage {
            image.writeJPEG(toURL: url)
            successMessage = l10n.saveSuccessJPEG
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
