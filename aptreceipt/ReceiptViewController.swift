import AppKit
import SwiftUI
import UniformTypeIdentifiers

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
        receiptType = draft.kind == .income ? "tahsilat_makbuzu" : "gider_makbuzu"
        flatPrefix = "daire"
    case .romanian:
        defaultApt = "asociatie_proprietari"
        receiptType = draft.kind == .income ? "chitanta_incasare" : "dispozitie_plata"
        flatPrefix = "ap"
    default:
        defaultApt = "building"
        receiptType = draft.kind == .income ? "income_receipt" : "expense_receipt"
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

private func sanitizeForFileName(_ input: String) -> String {
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

            // Footer Actions
            HStack(spacing: 12) {
                if let msg = successMessage {
                    Label(msg, systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.callout)
                }

                Spacer()

                Button(l10n.close) {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)

                // Save as JPEG Button
                Button {
                    saveReceiptImage()
                } label: {
                    Label(l10n.saveAsJPEG, systemImage: "photo.fill")
                        .padding(.horizontal, 4)
                }
                .buttonStyle(.bordered)

                // Save as PDF Button (Primary)
                Button {
                    saveReceiptPDF()
                } label: {
                    Label(l10n.saveAsPDF, systemImage: "doc.text.fill")
                        .padding(.horizontal, 6)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 720, height: 800)
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

    private var mainTitle: String {
        apartmentName.isEmpty ? l10n.defaultBuildingName : apartmentName.uppercased()
    }

    private var receiptBadgeText: String {
        draft.kind == .income ? l10n.incomeBadge : l10n.outcomeBadge
    }

    private var documentSerialFormatted: String {
        let prefix: String
        switch l10n.resolvedLanguage {
        case .turkish:
            prefix = draft.kind == .income ? "TAH" : "GID"
        case .romanian:
            prefix = draft.kind == .income ? "INC" : "DIS"
        default:
            prefix = draft.kind == .income ? "REC" : "EXP"
        }
        return String(format: "%@-%04d", prefix, draft.sequenceNumber)
    }

    private var amountInWords: String {
        NumberToWords.convert(draft.amount, language: l10n.resolvedLanguage, currency: draft.currency)
    }

    private var itemDescriptionText: String {
        if !draft.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return draft.notes
        }
        return draft.kind == .income ? l10n.defaultItemNameIncome : l10n.defaultItemNameExpense
    }

    private var badgeColor: Color {
        draft.kind == .income ? Color(red: 0.10, green: 0.50, blue: 0.25) : Color(red: 0.78, green: 0.30, blue: 0.12)
    }

    private var badgeBackground: Color {
        draft.kind == .income ? Color(red: 0.92, green: 0.97, blue: 0.93) : Color(red: 0.99, green: 0.94, blue: 0.92)
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
                        Text(draft.kind == .income ? l10n.incomeDocumentType : l10n.expenseDocumentType)
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
                    infoRow(label: l10n.invoiceTypeLabel + ":", value: draft.kind == .income ? l10n.incomeDocumentType : l10n.expenseDocumentType)
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
                    Text(l10n.payerSectionTitle)
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(textMuted)
                        .tracking(0.5)

                    Divider()

                    let receiverTitle = draft.kind == .income ? l10n.invoicePayerResidentLabel : l10n.invoiceVendorLabel
                    infoRow(label: receiverTitle, value: draft.receiver)
                    let flatText = draft.showApartmentNumber ? "\(l10n.flatPrefix) \(draft.apartmentNumber)" : l10n.commonAreaLabel
                    infoRow(label: l10n.invoiceUnitLabel, value: flatText)
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

                // Table Row
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
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right: Financial Totals Box
                VStack(spacing: 5) {
                    HStack {
                        Text(l10n.subtotal)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(textSecondary)
                        Spacer()
                        Text(formattedAmount)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(textDark)
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
            HStack(alignment: .bottom) {
                // Electronic verification and tracking footer
                VStack(alignment: .leading, spacing: 4) {
                    Text(l10n.electronicDisclaimer)
                        .font(.system(size: 8.5))
                        .foregroundColor(textMuted)

                    HStack(spacing: 6) {
                        Text("|||||||||||||||||||||||||||||||||||||||||||||")
                            .font(.system(size: 9, weight: .ultraLight, design: .monospaced))
                            .foregroundColor(textDark.opacity(0.4))

                        Text(documentSerialFormatted)
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                            .foregroundColor(textMuted)
                    }

                    Text("\(l10n.appTitle) v3.2.0 • \(l10n.publisher)")
                        .font(.system(size: 8.5))
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
