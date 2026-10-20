import AppKit
import SwiftUI
import UniformTypeIdentifiers
@preconcurrency import Vision
import PDFKit

// MARK: - Number to Words Converter

struct NumberToWords {
    private static let turkishOnes = ["", "Bir", "İki", "Üç", "Dört", "Beş", "Altı", "Yedi", "Sekiz", "Dokuz"]
    private static let turkishTens = ["", "On", "Yirmi", "Otuz", "Kırk", "Elli", "Altmış", "Yetmiş", "Seksen", "Doksan"]

    private static let englishOnes = [
        "", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
        "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen",
        "Seventeen", "Eighteen", "Nineteen"
    ]
    private static let englishTens = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"]

    static func convert(_ amount: Double, language: AppLanguage, currency: AppCurrency = .turkishLira) -> String {
        let rounded = (amount * 100.0).rounded() / 100.0
        let integerPart = Int(floor(rounded))
        let fractionalPart = Int(((rounded - Double(integerPart)) * 100.0).rounded())

        switch language {
        case .turkish:
            let mainUnit: String
            let fracUnit: String
            switch currency {
            case .turkishLira:
                mainUnit = "Türk Lirası"
                fracUnit = "Kuruş"
            case .romanianLeu:
                mainUnit = "Rumen Leyi"
                fracUnit = "Bani"
            case .usDollar:
                mainUnit = "Amerikan Doları"
                fracUnit = "Sent"
            case .euro:
                mainUnit = "Euro"
                fracUnit = "Sent"
            case .britishPound:
                mainUnit = "İngiliz Sterlini"
                fracUnit = "Peni"
            }
            let lirasText = integerToTurkishWords(integerPart)
            let kurusText = integerToTurkishWords(fractionalPart)
            let lirasString = lirasText.isEmpty ? "Sıfır \(mainUnit)" : "\(lirasText) \(mainUnit)"
            let kurusString = kurusText.isEmpty ? "Sıfır \(fracUnit)" : "\(kurusText) \(fracUnit)"
            return "\(lirasString) \(kurusString)"

        case .romanian:
            let mainUnit: String
            let fracUnit: String
            switch currency {
            case .turkishLira:
                mainUnit = integerPart == 1 ? "Liră Turcească" : "Lire Turcești"
                fracUnit = fractionalPart == 1 ? "Kuruș" : "Kuruși"
            case .romanianLeu:
                mainUnit = integerPart == 1 ? "Leu" : "Lei"
                fracUnit = fractionalPart == 1 ? "Ban" : "Bani"
            case .usDollar:
                mainUnit = integerPart == 1 ? "Dolar SUA" : "Dolari SUA"
                fracUnit = fractionalPart == 1 ? "Cent" : "Cenți"
            case .euro:
                mainUnit = "Euro"
                fracUnit = fractionalPart == 1 ? "Cent" : "Cenți"
            case .britishPound:
                mainUnit = integerPart == 1 ? "Liră Sterlină" : "Lire Sterline"
                fracUnit = fractionalPart == 1 ? "Pence" : "Pence"
            }
            let leiText = integerToRomanianWords(integerPart)
            let baniText = integerToRomanianWords(fractionalPart)
            let leiString = leiText.isEmpty ? "Zero \(mainUnit)" : "\(leiText) \(mainUnit)"
            let baniString = baniText.isEmpty ? "Zero \(fracUnit)" : "\(baniText) \(fracUnit)"
            return "\(leiString) și \(baniString)"

        default:
            let mainUnit: String
            let fracUnit: String
            switch currency {
            case .turkishLira:
                mainUnit = integerPart == 1 ? "Turkish Lira" : "Turkish Liras"
                fracUnit = fractionalPart == 1 ? "Kurus" : "Kurus"
            case .romanianLeu:
                mainUnit = integerPart == 1 ? "Romanian Leu" : "Romanian Lei"
                fracUnit = fractionalPart == 1 ? "Ban" : "Bani"
            case .usDollar:
                mainUnit = integerPart == 1 ? "US Dollar" : "US Dollars"
                fracUnit = fractionalPart == 1 ? "Cent" : "Cents"
            case .euro:
                mainUnit = "Euro"
                fracUnit = fractionalPart == 1 ? "Cent" : "Cents"
            case .britishPound:
                mainUnit = integerPart == 1 ? "British Pound" : "British Pounds"
                fracUnit = fractionalPart == 1 ? "Penny" : "Pence"
            }
            let mainText = integerToEnglishWords(integerPart)
            let fracText = integerToEnglishWords(fractionalPart)
            let mainString = mainText.isEmpty ? "Zero \(mainUnit)" : "\(mainText) \(mainUnit)"
            let fracString = fracText.isEmpty ? "Zero \(fracUnit)" : "\(fracText) \(fracUnit)"
            return "\(mainString) and \(fracString)"
        }
    }

    private static func integerToTurkishWords(_ number: Int) -> String {
        if number == 0 { return "" }
        if number < 0 { return "Eksi " + integerToTurkishWords(abs(number)) }

        var result = ""
        var num = number

        let millions = num / 1_000_000
        if millions > 0 {
            result += integerToTurkishWords(millions) + " Milyon "
            num %= 1_000_000
        }

        let thousands = num / 1_000
        if thousands > 0 {
            if thousands == 1 {
                result += "Bin "
            } else {
                result += integerToTurkishWords(thousands) + " Bin "
            }
            num %= 1_000
        }

        let hundreds = num / 100
        if hundreds > 0 {
            if hundreds == 1 {
                result += "Yüz "
            } else {
                result += turkishOnes[hundreds] + " Yüz "
            }
            num %= 100
        }

        let tens = num / 10
        if tens > 0 {
            result += turkishTens[tens] + " "
            num %= 10
        }

        if num > 0 {
            result += turkishOnes[num] + " "
        }

        return result.trimmingCharacters(in: .whitespaces)
    }

    private static func integerToRomanianWords(_ number: Int) -> String {
        if number == 0 { return "" }
        if number < 0 { return "Minus " + integerToRomanianWords(abs(number)) }

        var result = ""
        var num = number

        let millions = num / 1_000_000
        if millions > 0 {
            if millions == 1 {
                result += "Un Milion "
            } else {
                result += integerToRomanianWords(millions) + " Milioane "
            }
            num %= 1_000_000
        }

        let thousands = num / 1_000
        if thousands > 0 {
            if thousands == 1 {
                result += "O Mie "
            } else if thousands == 2 {
                result += "Două Mii "
            } else {
                result += integerToRomanianWords(thousands) + " Mii "
            }
            num %= 1_000
        }

        let hundreds = num / 100
        if hundreds > 0 {
            if hundreds == 1 {
                result += "O Sută "
            } else if hundreds == 2 {
                result += "Două Sute "
            } else {
                let digitFems = ["", "Una", "Două", "Trei", "Patru", "Cinci", "Șase", "Șapte", "Opt", "Nouă"]
                let digit = (hundreds < digitFems.count) ? digitFems[hundreds] : "\(hundreds)"
                result += digit + " Sute "
            }
            num %= 100
        }

        if num >= 20 {
            let tens = num / 10
            let remainder = num % 10
            let tensNames = ["", "", "Douăzeci", "Treizeci", "Patruzeci", "Cincizeci", "Șaizeci", "Șaptezeci", "Optzeci", "Nouăzeci"]
            let digitMascs = ["", "Unu", "Doi", "Trei", "Patru", "Cinci", "Șase", "Șapte", "Opt", "Nouă"]
            if remainder > 0 {
                let digit = (remainder < digitMascs.count) ? digitMascs[remainder] : "\(remainder)"
                result += tensNames[tens] + " și " + digit + " "
            } else {
                result += tensNames[tens] + " "
            }
            num = 0
        } else if num >= 10 {
            let teens = [
                "Zece", "Unsprezece", "Doisprezece", "Treisprezece", "Paisprezece",
                "Cincisprezece", "Șaisprezece", "Șaptesprezece", "Optsprezece", "Nouăsprezece"
            ]
            result += teens[num - 10] + " "
            num = 0
        } else if num > 0 {
            let digitMascs = ["", "Unu", "Doi", "Trei", "Patru", "Cinci", "Șase", "Șapte", "Opt", "Nouă"]
            let digit = (num < digitMascs.count) ? digitMascs[num] : "\(num)"
            result += digit + " "
            num = 0
        }

        return result.trimmingCharacters(in: .whitespaces)
    }

    private static func integerToEnglishWords(_ number: Int) -> String {
        if number == 0 { return "" }
        if number < 0 { return "Minus " + integerToEnglishWords(abs(number)) }

        var result = ""
        var num = number

        let millions = num / 1_000_000
        if millions > 0 {
            result += integerToEnglishWords(millions) + " Million "
            num %= 1_000_000
        }

        let thousands = num / 1_000
        if thousands > 0 {
            result += integerToEnglishWords(thousands) + " Thousand "
            num %= 1_000
        }

        let hundreds = num / 100
        if hundreds > 0 {
            result += englishOnes[hundreds] + " Hundred "
            num %= 100
        }

        if num >= 20 {
            let tens = num / 10
            result += englishTens[tens] + " "
            num %= 10
        }

        if num > 0 && num < 20 {
            result += englishOnes[num] + " "
        }

        return result.trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - File Name Sanitizer & Builder

func buildExportFileName(draft: ReceiptDraft, apartmentName: String, language: AppLanguage, ext: String) -> String {
    let defaultApt: String
    let receiptType: String
    let flatPrefix: String

    switch language {
    case .turkish:
        defaultApt = "apartman"
        switch draft.kind {
        case .income: receiptType = "tahsilat_makbuzu"
        case .outcome: receiptType = "gider_makbuzu"
        case .managementExpense: receiptType = "yonetim_harcama_makbuzu"
        }
        flatPrefix = "daire"
    case .romanian:
        defaultApt = "asociatie_proprietari"
        switch draft.kind {
        case .income: receiptType = "chitanta_incasare"
        case .outcome: receiptType = "dispozitie_plata"
        case .managementExpense: receiptType = "dispozitie_plata_administratie"
        }
        flatPrefix = "ap"
    default:
        defaultApt = "building"
        switch draft.kind {
        case .income: receiptType = "income_receipt"
        case .outcome: receiptType = "expense_receipt"
        case .managementExpense: receiptType = "management_expense_receipt"
        }
        flatPrefix = "flat"
    }

    let cleanApartment = sanitizeForFileName(apartmentName.isEmpty ? defaultApt : apartmentName)
    var parts: [String] = [cleanApartment, receiptType]

    if draft.showApartmentNumber {
        parts.append("\(flatPrefix)_\(draft.apartmentNumber)")
    }

    let cleanReceiver = sanitizeForFileName(draft.receiver)
    if !cleanReceiver.isEmpty {
        parts.append(cleanReceiver)
    }

    let cleanPeriod = sanitizeForFileName(draft.monthYear)
    if !cleanPeriod.isEmpty {
        parts.append(cleanPeriod)
    }

    let baseName = parts.joined(separator: "_")
    return "\(baseName).\(ext.lowercased())"
}

func sanitizeForFileName(_ input: String) -> String {
    var text = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

    let diacriticMap: [Character: Character] = [
        "ç": "c", "ğ": "g", "ı": "i", "ö": "o", "ş": "s", "ü": "u",
        "Ç": "c", "Ğ": "g", "İ": "i", "Ö": "o", "Ş": "s", "Ü": "u",
        "ă": "a", "â": "a", "î": "i", "ș": "s", "ț": "t",
        "Ă": "a", "Â": "a", "Î": "i", "Ș": "s", "Ț": "t"
    ]
    text = String(text.map { diacriticMap[$0] ?? $0 })
    text = text.folding(options: .diacriticInsensitive, locale: .current)

    let allowed = CharacterSet.alphanumerics
    let chars = text.map { allowed.contains($0.unicodeScalars.first!) ? $0 : "_" }
    let cleaned = String(chars)

    let parts = cleaned.split(separator: "_").filter { !$0.isEmpty }
    return parts.joined(separator: "_")
}

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

// MARK: - A4 Invoice Document View (595 x 842 pt)

struct ReceiptDocumentView: View {
    let draft: ReceiptDraft
    let apartmentName: String
    let signatureImage: NSImage?
    var logoImage: NSImage? = nil
    let l10n: L10n

    // Strict Print Colors (Dark Mode Proof)
    private let textDark = Color(red: 0.08, green: 0.11, blue: 0.15)
    private let textSecondary = Color(red: 0.28, green: 0.33, blue: 0.40)
    private let textMuted = Color(red: 0.45, green: 0.50, blue: 0.58)
    private let borderDark = Color(red: 0.12, green: 0.18, blue: 0.28)
    private let borderSubtle = Color(red: 0.84, green: 0.88, blue: 0.92)
    private let cardBackground = Color(red: 0.97, green: 0.98, blue: 0.99)
    private let tableHeaderBg = Color(red: 0.12, green: 0.18, blue: 0.26)

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = l10n.locale
        formatter.currencySymbol = draft.currency.symbol
        formatter.currencyCode = draft.currency.code
        return formatter.string(from: NSNumber(value: draft.amount)) ?? "\(draft.currency.symbol) \(draft.amount)"
    }

    private var baseAmountFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = l10n.locale
        formatter.currencySymbol = draft.currency.symbol
        formatter.currencyCode = draft.currency.code
        let amt = draft.baseAmount > 0 ? draft.baseAmount : (draft.isLateFeeApplied ? max(0, draft.amount - draft.lateFeeAmount) : draft.amount)
        return formatter.string(from: NSNumber(value: amt)) ?? "\(draft.currency.symbol) \(amt)"
    }

    private var lateFeeAmountFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = l10n.locale
        formatter.currencySymbol = draft.currency.symbol
        formatter.currencyCode = draft.currency.code
        return formatter.string(from: NSNumber(value: draft.lateFeeAmount)) ?? "\(draft.currency.symbol) \(draft.lateFeeAmount)"
    }

    private var mainTitle: String {
        apartmentName.isEmpty ? l10n.defaultBuildingName : apartmentName.uppercased()
    }

    private var receiptBadgeText: String {
        switch draft.kind {
        case .income: return l10n.incomeBadge
        case .outcome: return l10n.outcomeBadge
        case .managementExpense: return l10n.managementExpenseBadge
        }
    }

    private var documentSerialFormatted: String {
        let prefix: String
        switch l10n.resolvedLanguage {
        case .turkish:
            switch draft.kind {
            case .income: prefix = "TAH"
            case .outcome: prefix = "GID"
            case .managementExpense: prefix = "HAR"
            }
        case .romanian:
            switch draft.kind {
            case .income: prefix = "INC"
            case .outcome: prefix = "DIS"
            case .managementExpense: prefix = "ADM"
            }
        default:
            switch draft.kind {
            case .income: prefix = "REC"
            case .outcome: prefix = "EXP"
            case .managementExpense: prefix = "MGT"
            }
        }
        return String(format: "%@-%04d", prefix, draft.sequenceNumber)
    }

    private var amountInWords: String {
        NumberToWords.convert(draft.amount, language: l10n.resolvedLanguage, currency: draft.currency)
    }

    private var itemDescriptionText: String {
        if !draft.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && draft.notes != "-" {
            return draft.notes
        }
        switch draft.kind {
        case .income: return l10n.defaultItemNameIncome
        case .outcome: return l10n.defaultItemNameExpense
        case .managementExpense: return l10n.defaultItemNameManagementExpense
        }
    }

    private var badgeColor: Color {
        switch draft.kind {
        case .income: return Color(red: 0.10, green: 0.50, blue: 0.25)
        case .outcome: return Color(red: 0.78, green: 0.30, blue: 0.12)
        case .managementExpense: return Color(red: 0.18, green: 0.35, blue: 0.78)
        }
    }

    private var badgeBackground: Color {
        switch draft.kind {
        case .income: return Color(red: 0.92, green: 0.97, blue: 0.93)
        case .outcome: return Color(red: 0.99, green: 0.94, blue: 0.92)
        case .managementExpense: return Color(red: 0.92, green: 0.94, blue: 0.99)
        }
    }

    private var qrVerificationPayload: String {
        "AptReceipt | \(mainTitle) | \(documentSerialFormatted) | \(draft.createdDate) | \(draft.receiver) | \(formattedAmount) | \(draft.issuer)"
    }

    private var documentType: String {
        switch draft.kind {
        case .income: return l10n.incomeDocumentType
        case .outcome: return l10n.expenseDocumentType
        case .managementExpense: return l10n.managementExpenseDocumentType
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: 1. Official Header
            HStack(alignment: .top, spacing: 14) {
                if let logo = logoImage {
                    Image(nsImage: logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(borderSubtle, lineWidth: 1)
                        )
                } else {
                    Default2DBuildingLogo(size: 52)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(mainTitle)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(textDark)
                        .tracking(0.5)

                    Text(l10n.invoiceSubHeader)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(textMuted)

                    HStack(spacing: 6) {
                        Text(receiptBadgeText)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(badgeColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(badgeBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(badgeColor.opacity(0.3), lineWidth: 1)
                            )

                        Text("•")
                            .foregroundColor(textMuted)

                        Text(draft.monthYear)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(textDark)
                    }
                    .padding(.top, 2)
                }

                Spacer()

                // Official Serial and Date Box
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(l10n.serialLabel + ":")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(textMuted)
                        Text(documentSerialFormatted)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(textDark)
                    }

                    HStack(spacing: 4) {
                        Text(l10n.issueDate)
                            .font(.system(size: 10))
                            .foregroundColor(textMuted)
                        Text(draft.createdDate)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(textDark)
                    }

                    HStack(spacing: 4) {
                        Text(l10n.invoiceTypeLabel + ":")
                            .font(.system(size: 10))
                            .foregroundColor(textMuted)
                        Text(documentType)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(textSecondary)
                    }
                }
            }
            .padding(.bottom, 12)

            // Double Rule
            Rectangle()
                .fill(borderDark)
                .frame(height: 2)
            Rectangle()
                .fill(borderDark.opacity(0.25))
                .frame(height: 0.8)
                .padding(.top, 2)
                .padding(.bottom, 16)

            // MARK: 2. Dual Party Cards (Management & Resident)
            HStack(spacing: 12) {
                // Left: Issuer Card
                VStack(alignment: .leading, spacing: 5) {
                    Text(l10n.managerSectionTitle)
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(textMuted)
                        .tracking(0.5)

                    Divider()

                    infoRow(label: l10n.invoiceBuildingLabel, value: mainTitle)
                    infoRow(label: l10n.invoiceManagerLabel, value: draft.issuer)
                    infoRow(label: l10n.invoiceTypeLabel + ":", value: documentType)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(borderSubtle, lineWidth: 1)
                )

                // Right: Payer / Resident Card
                VStack(alignment: .leading, spacing: 5) {
                    Text(draft.kind == .managementExpense ? l10n.vendorSectionTitle : l10n.payerSectionTitle)
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(textMuted)
                        .tracking(0.5)

                    Divider()

                    let receiverTitle = draft.kind == .income ? l10n.invoicePayerResidentLabel : l10n.invoiceVendorLabel
                    infoRow(label: receiverTitle, value: draft.receiver)
                    if draft.kind != .managementExpense {
                        let flatText = (draft.showApartmentNumber && draft.apartmentNumber > 0) ? "\(l10n.flatPrefix) \(draft.apartmentNumber)" : l10n.commonAreaLabel
                        infoRow(label: l10n.invoiceUnitLabel, value: flatText)
                    }
                    infoRow(label: l10n.period, value: draft.monthYear)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(borderSubtle, lineWidth: 1)
                )
            }
            .padding(.bottom, 16)

            // MARK: 3. Itemized Invoice Table
            VStack(spacing: 0) {
                // Table Header
                HStack(spacing: 0) {
                    Text(l10n.itemNo)
                        .font(.system(size: 9.5, weight: .bold))
                        .frame(width: 36, alignment: .center)
                    Divider().frame(height: 14)
                    Text(l10n.itemDescription)
                        .font(.system(size: 9.5, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 8)
                    Divider().frame(height: 14)
                    Text(l10n.itemPeriod)
                        .font(.system(size: 9.5, weight: .bold))
                        .frame(width: 80, alignment: .center)
                    Divider().frame(height: 14)
                    Text(l10n.itemUnit)
                        .font(.system(size: 9.5, weight: .bold))
                        .frame(width: 60, alignment: .center)
                    Divider().frame(height: 14)
                    Text(l10n.itemAmount)
                        .font(.system(size: 9.5, weight: .bold))
                        .frame(width: 95, alignment: .trailing)
                        .padding(.trailing, 8)
                }
                .foregroundColor(.white)
                .padding(.vertical, 7)
                .background(tableHeaderBg)
                .clipShape(RoundedRectangle(cornerRadius: 4))

                // Table Rows
                if draft.lateFeeAmount > 0 {
                    // Row 01: Base Dues
                    HStack(spacing: 0) {
                        Text("01")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(textDark)
                            .frame(width: 36, alignment: .center)

                        Text(itemDescriptionText)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(textDark)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)

                        Text(draft.monthYear)
                            .font(.system(size: 9.5))
                            .foregroundColor(textSecondary)
                            .frame(width: 80, alignment: .center)

                        Text(l10n.unitMonth)
                            .font(.system(size: 9.5))
                            .foregroundColor(textSecondary)
                            .frame(width: 60, alignment: .center)

                        Text(baseAmountFormatted)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(textDark)
                            .frame(width: 95, alignment: .trailing)
                            .padding(.trailing, 8)
                    }
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .overlay(
                        Rectangle()
                            .fill(borderSubtle)
                            .frame(height: 1),
                        alignment: .bottom
                    )

                    // Row 02: KMK Md. 20 Late Fee
                    HStack(spacing: 0) {
                        Text("02")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(textDark)
                            .frame(width: 36, alignment: .center)

                        Text(l10n.lateFeeItemName(rate: draft.lateFeeRate, months: draft.lateMonths))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(red: 0.82, green: 0.42, blue: 0.12))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)

                        Text(draft.monthYear)
                            .font(.system(size: 9.5))
                            .foregroundColor(textSecondary)
                            .frame(width: 80, alignment: .center)

                        Text("\(draft.lateMonths) \(draft.lateMonths > 1 ? l10n.monthsUnit : l10n.monthUnit)")
                            .font(.system(size: 9.5))
                            .foregroundColor(textSecondary)
                            .frame(width: 60, alignment: .center)

                        Text("+" + lateFeeAmountFormatted)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.82, green: 0.42, blue: 0.12))
                            .frame(width: 95, alignment: .trailing)
                            .padding(.trailing, 8)
                    }
                    .padding(.vertical, 8)
                    .background(Color(red: 0.99, green: 0.97, blue: 0.94))
                    .overlay(
                        Rectangle()
                            .fill(borderSubtle)
                            .frame(height: 1),
                        alignment: .bottom
                    )
                } else {
                    HStack(spacing: 0) {
                        Text("01")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(textDark)
                            .frame(width: 36, alignment: .center)

                        Text(itemDescriptionText)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(textDark)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)

                        Text(draft.monthYear)
                            .font(.system(size: 9.5))
                            .foregroundColor(textSecondary)
                            .frame(width: 80, alignment: .center)

                        Text(l10n.unitMonth)
                            .font(.system(size: 9.5))
                            .foregroundColor(textSecondary)
                            .frame(width: 60, alignment: .center)

                        Text(formattedAmount)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(textDark)
                            .frame(width: 95, alignment: .trailing)
                            .padding(.trailing, 8)
                    }
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .overlay(
                        Rectangle()
                            .fill(borderSubtle)
                            .frame(height: 1),
                        alignment: .bottom
                    )
                }
            }
            .padding(.bottom, 16)

            // MARK: 4. Calculation & Totals Section
            HStack(alignment: .top, spacing: 14) {
                // Left: In Words and Legal Notices
                VStack(alignment: .leading, spacing: 8) {
                    // Yalnız (In Words) Box
                    VStack(alignment: .leading, spacing: 3) {
                        Text(l10n.inWordsPrefix)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(textMuted)

                        Text("# \(amountInWords) #")
                            .font(.system(size: 10, weight: .semibold, design: .serif))
                            .foregroundColor(textDark)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.98, green: 0.98, blue: 0.99))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(borderSubtle, lineWidth: 1)
                    )

                    // Statutory Exemption Text
                    Text(l10n.statutoryTaxNotice)
                        .font(.system(size: 8.5))
                        .foregroundColor(textMuted)

                    Text(l10n.legalStatutoryNotice)
                        .font(.system(size: 8.5))
                        .foregroundColor(textMuted)

                    if draft.lateFeeAmount > 0 {
                        let footnote = draft.lateFeeFootnote ?? ReceiptSettingsStore.shared.effectiveLateFeeFootnote()
                        Text(footnote)
                            .font(.system(size: 8.5, weight: .semibold))
                            .foregroundColor(Color(red: 0.82, green: 0.42, blue: 0.12))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right: Financial Totals Box
                VStack(spacing: 5) {
                    if draft.lateFeeAmount > 0 {
                        HStack {
                            Text(l10n.baseDuesAmount)
                                .font(.system(size: 9.5, weight: .medium))
                                .foregroundColor(textSecondary)
                            Spacer()
                            Text(baseAmountFormatted)
                                .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                                .foregroundColor(textDark)
                        }

                        HStack {
                            Text(l10n.lateFeeCalculated)
                                .font(.system(size: 9.5, weight: .medium))
                                .foregroundColor(Color(red: 0.82, green: 0.42, blue: 0.12))
                            Spacer()
                            Text("+" + lateFeeAmountFormatted)
                                .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(red: 0.82, green: 0.42, blue: 0.12))
                        }
                    } else {
                        HStack {
                            Text(l10n.subtotal)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(textSecondary)
                            Spacer()
                            Text(formattedAmount)
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(textDark)
                        }
                    }

                    HStack {
                        Text(l10n.vatTax)
                            .font(.system(size: 9.5))
                            .foregroundColor(textMuted)
                        Spacer()
                        Text(l10n.vatExempt)
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundColor(textSecondary)
                    }

                    Divider().padding(.vertical, 2)

                    HStack {
                        Text(l10n.grandTotal)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(textDark)
                        Spacer()
                        Text(formattedAmount)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(badgeColor)
                    }
                    .padding(8)
                    .background(badgeBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(badgeColor.opacity(0.35), lineWidth: 1)
                    )
                }
                .frame(width: 220)
                .padding(10)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(borderSubtle, lineWidth: 1)
                )
            }
            .padding(.bottom, 20)

            Spacer(minLength: 20)

            // MARK: 5. Footer & Authorized Signature
            HStack(alignment: .bottom, spacing: 14) {
                // QR Verification Code
                if let qrImage = QRCodeGenerator.generate(from: qrVerificationPayload, size: 52) {
                    Image(nsImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(borderSubtle, lineWidth: 1)
                        )
                }

                // Electronic verification and tracking footer
                VStack(alignment: .leading, spacing: 3) {
                    Text(l10n.qrVerificationNotice)
                        .font(.system(size: 8))
                        .foregroundColor(textMuted)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        Text(documentSerialFormatted)
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                            .foregroundColor(textDark)
                        Text("•")
                            .foregroundColor(textMuted)
                        Text(draft.createdDate)
                            .font(.system(size: 8.5))
                            .foregroundColor(textMuted)
                    }

                    Text("\(l10n.appTitle) v3.3.0 • \(l10n.publisher)")
                        .font(.system(size: 8))
                        .foregroundColor(textMuted.opacity(0.8))
                }

                Spacer()

                // Stamp & Signature Box
                VStack(alignment: .center, spacing: 4) {
                    Text(l10n.signatureStamp)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(textSecondary)
                        .tracking(0.5)

                    if let signatureImage {
                        Image(nsImage: signatureImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 52)
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 140, height: 42)
                    }

                    Rectangle()
                        .fill(borderDark.opacity(0.4))
                        .frame(width: 150, height: 1)

                    Text(draft.issuer)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(textDark)
                }
                .frame(width: 160)
                .padding(8)
                .background(cardBackground.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(borderSubtle, lineWidth: 1)
                )
            }
        }
        .padding(36)
        .frame(width: 595, height: 842)
        .background(Color.white)
        .overlay(
            Rectangle()
                .stroke(borderSubtle, lineWidth: 1)
        )
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(label)
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundColor(textMuted)
                .frame(width: 86, alignment: .leading)

            Text(value)
                .font(.system(size: 10, weight: .bold))
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

// MARK: - Parsed Invoice Result

struct ParsedInvoiceResult {
    var vendorName: String?
    var amount: Double?
    var invoiceDate: Date?
    var invoiceNumber: String?
    var rawText: String = ""
}

// MARK: - Invoice OCR Parser (Apple Vision & PDFKit)

final class InvoiceOCRParser {

    static func parse(fileURL: URL, knownVendors: [String] = []) async -> ParsedInvoiceResult {
        let ext = fileURL.pathExtension.lowercased()
        var fullText = ""

        if ext == "pdf" {
            fullText = await extractTextFromPDF(url: fileURL)
        } else {
            fullText = await extractTextFromImage(url: fileURL)
        }

        return analyzeText(fullText, knownVendors: knownVendors)
    }

    private static func extractTextFromPDF(url: URL) async -> String {
        guard let doc = PDFDocument(url: url) else { return "" }
        var aggregated = ""

        for i in 0..<min(doc.pageCount, 3) {
            guard let page = doc.page(at: i) else { continue }
            if let str = page.string, str.trimmingCharacters(in: .whitespacesAndNewlines).count > 40 {
                aggregated += str + "\n"
            } else {
                let pageBounds = page.bounds(for: .mediaBox)
                let renderer = page.thumbnail(of: CGSize(width: max(pageBounds.width, 1200), height: max(pageBounds.height, 1600)), for: .mediaBox)
                if let cgImage = renderer.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                    let pageText = await recognizeTextInCGImage(cgImage)
                    aggregated += pageText + "\n"
                }
            }
        }

        return aggregated
    }

    private static func extractTextFromImage(url: URL) async -> String {
        guard let image = NSImage(contentsOf: url),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return ""
        }
        return await recognizeTextInCGImage(cgImage)
    }

    private static func recognizeTextInCGImage(_ cgImage: CGImage) async -> String {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                continuation.resume(returning: text)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            if #available(macOS 13.0, *) {
                request.recognitionLanguages = ["tr-TR", "en-US", "ro-RO"]
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(returning: "")
                }
            }
        }
    }

    static func analyzeText(_ rawText: String, knownVendors: [String]) -> ParsedInvoiceResult {
        var result = ParsedInvoiceResult(rawText: rawText)
        let lines = rawText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // 1. Match known vendors first
        for vendor in knownVendors {
            let lowerVendor = vendor.lowercased()
            if rawText.lowercased().contains(lowerVendor) {
                result.vendorName = vendor
                break
            }
        }

        // Company indicators
        if result.vendorName == nil {
            let companyIndicators = [
                "A.Ş", "A.S.", "LTD", "ŞTİ", "STI", "TİC", "TIC", "SAN",
                "S.R.L", "SRL", "INC", "LLC", "LIMITED", "ANONIM", "ANONİM",
                "HİZMETLERİ", "HIZMETLERI", "SERVİSİ", "SERVISI", "ONARIM", "BAKIM",
                "ELEKTRİK", "ELEKTRIK", "ASANSÖR", "ASANSOR", "YÖNETİM", "TEMİZLİK"
            ]

            for line in lines.prefix(15) {
                let upperLine = line.uppercased()
                if companyIndicators.contains(where: { upperLine.contains($0) }) {
                    let cleaned = line.replacingOccurrences(of: #"(?i)vergi no.*"#, with: "", options: .regularExpression)
                        .replacingOccurrences(of: #"(?i)vkn.*"#, with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if cleaned.count >= 4 && cleaned.count <= 60 {
                        result.vendorName = cleaned
                        break
                    }
                }
            }

            if result.vendorName == nil {
                let ignoreKeywords = ["FATURA", "E-FATURA", "E-ARŞİV", "INVOICE", "FACTURA", "RECEIPT", "SAYIN", "TARİH", "DATE"]
                for line in lines.prefix(6) {
                    let upper = line.uppercased()
                    if !ignoreKeywords.contains(where: { upper.contains($0) }) && line.count >= 5 && line.count <= 50 {
                        result.vendorName = line
                        break
                    }
                }
            }
        }

        // 2. Extract Amount
        let totalKeywords = [
            "TOPLAM", "GENEL TOPLAM", "ÖDENECEK", "ODENECEK", "TUTAR", "KDV DAHİL",
            "KDV DAHIL", "VERGİLER DAHİL", "FİŞ TUTARI", "FATURA TUTARI", "ARA TOPLAM",
            "TOTAL", "GRAND TOTAL", "AMOUNT DUE", "TOTAL DUE", "SUMA", "TOTAL DE PLATA"
        ]

        var foundAmount: Double? = nil
        var highestCandidate: Double = 0.0

        for (idx, line) in lines.enumerated() {
            let upper = line.uppercased()
            let hasTotalKeyword = totalKeywords.contains { upper.contains($0) }
            let extractedNumbers = extractNumbers(from: line)

            if hasTotalKeyword {
                if let lastNum = extractedNumbers.last, lastNum > 0 {
                    foundAmount = lastNum
                    break
                }
                if extractedNumbers.isEmpty && idx + 1 < lines.count {
                    let nextNumbers = extractNumbers(from: lines[idx + 1])
                    if let firstNum = nextNumbers.first, firstNum > 0 {
                        foundAmount = firstNum
                        break
                    }
                }
            }

            for num in extractedNumbers {
                if num > highestCandidate && num < 10_000_000.0 {
                    highestCandidate = num
                }
            }
        }

        result.amount = foundAmount ?? (highestCandidate > 0 ? highestCandidate : nil)

        // 3. Extract Date
        let datePatterns = [
            #"\b(\d{1,2})[./\-](\d{1,2})[./\-](\d{4})\b"#,
            #"\b(\d{4})[./\-](\d{1,2})[./\-](\d{1,2})\b"#
        ]

        let dateKeywords = ["TARİH", "TARIH", "DÜZENLEME", "DATE", "DATA"]
        for line in lines {
            let upper = line.uppercased()
            let isDateLine = dateKeywords.contains { upper.contains($0) }

            for pattern in datePatterns {
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    let nsString = line as NSString
                    let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsString.length))
                    if let match = matches.first {
                        let dateStr = nsString.substring(with: match.range)
                        if let parsed = parseDateString(dateStr) {
                            result.invoiceDate = parsed
                            break
                        }
                    }
                }
            }
            if result.invoiceDate != nil && isDateLine {
                break
            }
        }

        // 4. Extract Invoice / Receipt Number
        let invPatterns = [
            #"(?i)(?:fatura|fiş|belge|invoice|factura)\s*(?:no|numarası|nr|number|#)?\s*[:.\-]?\s*([A-Za-z0-9\-]{6,20})"#,
            #"\b([A-Z]{3}20\d{10,13})\b"#
        ]

        for pattern in invPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let nsString = rawText as NSString
                if let match = regex.firstMatch(in: rawText, range: NSRange(location: 0, length: nsString.length)) {
                    if match.numberOfRanges > 1 {
                        let codeRange = match.range(at: 1)
                        if codeRange.location != NSNotFound {
                            result.invoiceNumber = nsString.substring(with: codeRange)
                            break
                        }
                    }
                }
            }
        }

        return result
    }

    private static func extractNumbers(from text: String) -> [Double] {
        var results: [Double] = []
        let pattern = #"[0-9]{1,3}(?:[.,\s][0-9]{3})*(?:[.,][0-9]{2})|[0-9]+(?:[.,][0-9]{2})"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return results }

        let nsString = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))

        for match in matches {
            var raw = nsString.substring(with: match.range)
            raw = raw.replacingOccurrences(of: " ", with: "")

            if raw.contains(".") && raw.contains(",") {
                let lastDot = raw.lastIndex(of: ".")!
                let lastComma = raw.lastIndex(of: ",")!
                if lastComma > lastDot {
                    raw = raw.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
                } else {
                    raw = raw.replacingOccurrences(of: ",", with: "")
                }
            } else if raw.contains(",") {
                raw = raw.replacingOccurrences(of: ",", with: ".")
            }

            if let d = Double(raw), d > 0 {
                results.append(d)
            }
        }

        return results
    }

    private static func parseDateString(_ str: String) -> Date? {
        let formats = ["dd.MM.yyyy", "dd/MM/yyyy", "dd-MM-yyyy", "yyyy-MM-dd", "yyyy.MM.dd"]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for fmt in formats {
            formatter.dateFormat = fmt
            if let date = formatter.date(from: str) {
                return date
            }
        }
        return nil
    }
}

// MARK: - Invoice Attachment Storage Manager

final class InvoiceAttachmentManager {
    static let shared = InvoiceAttachmentManager()

    var directoryURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let invoicesDir = appSupport.appendingPathComponent("aptreceipt/invoices", isDirectory: true)
        try? FileManager.default.createDirectory(at: invoicesDir, withIntermediateDirectories: true)
        return invoicesDir
    }

    func saveAttachment(from sourceURL: URL) -> String? {
        let ext = sourceURL.pathExtension.isEmpty ? "pdf" : sourceURL.pathExtension
        let newFileName = "\(UUID().uuidString).\(ext)"
        let destinationURL = directoryURL.appendingPathComponent(newFileName)

        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try? FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            return destinationURL.path
        } catch {
            print("Failed to save invoice attachment: \(error)")
            return nil
        }
    }

    func openAttachment(at path: String) {
        let fileURL = URL(fileURLWithPath: path)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            NSWorkspace.shared.open(fileURL)
        }
    }

    func removeAttachment(at path: String) {
        let fileURL = URL(fileURLWithPath: path)
        try? FileManager.default.removeItem(at: fileURL)
    }
}
