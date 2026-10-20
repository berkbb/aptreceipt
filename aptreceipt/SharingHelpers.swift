import AppKit
import CoreImage

// MARK: - CoreImage QR Code Generator

enum QRCodeGenerator {
    /// Bitmap pixels per QR module: every module is a whole, sharp square in previews, PDFs and prints.
    private static let pixelsPerModule = 10
    /// White border around the code, in modules; scanners need this quiet zone to find the code.
    private static let quietZoneModules = 4
    private static let context = CIContext()

    /// A black-on-white QR code with its quiet zone, `pointsPerModule` points per module, so its size
    /// follows the amount of text. Correction level L keeps longer texts small enough for a receipt.
    static func generate(from string: String, pointsPerModule: CGFloat) -> NSImage? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(Data(string.utf8), forKey: "inputMessage")
        filter.setValue("L", forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage,
              let modules = context.createCGImage(output, from: output.extent),
              modules.width > 0, modules.height > 0 else { return nil }

        // One module per pixel in `modules`; enlarge by a whole factor without smoothing so no module blurs.
        let width = (modules.width + 2 * quietZoneModules) * pixelsPerModule
        let height = (modules.height + 2 * quietZoneModules) * pixelsPerModule
        guard let bitmap = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }
        bitmap.setFillColor(gray: 1, alpha: 1)
        bitmap.fill(CGRect(x: 0, y: 0, width: width, height: height))
        bitmap.interpolationQuality = .none
        let inset = CGFloat(quietZoneModules * pixelsPerModule)
        bitmap.draw(modules, in: CGRect(
            x: inset, y: inset,
            width: CGFloat(modules.width * pixelsPerModule), height: CGFloat(modules.height * pixelsPerModule)
        ))
        guard let image = bitmap.makeImage() else { return nil }
        let size = NSSize(
            width: CGFloat(modules.width + 2 * quietZoneModules) * pointsPerModule,
            height: CGFloat(modules.height + 2 * quietZoneModules) * pointsPerModule
        )
        return NSImage(cgImage: image, size: size)
    }
}

// MARK: - WhatsApp & Sharing Helper

enum WhatsAppShareHelper {
    /// Characters that must be escaped inside a query value. `.urlQueryAllowed` keeps `&`, `+`, `=` and `?`,
    /// which would cut the message short (`&`) or turn into spaces (`+`).
    private static let queryValueAllowed = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "&+=?#/"))

    static func encodeQueryValue(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: queryValueAllowed) ?? ""
    }

    /// Calling code used to complete local numbers ("0532 …") for wa.me, from the building's currency.
    static func defaultCallingCode(for currency: AppCurrency) -> String? {
        switch currency {
        case .turkishLira: return "90"
        case .romanianLeu: return "40"
        default: return nil
        }
    }

    /// wa.me needs the full international number as digits only, without "+", "00" or a trunk "0".
    /// Numbers that are already international are kept; local Turkish/Romanian numbers get their calling code.
    static func whatsAppNumber(_ phone: String?, callingCode: String?) -> String {
        let trimmed = (phone ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        var digits = String(trimmed.unicodeScalars.filter { CharacterSet(charactersIn: "0123456789").contains($0) })
        guard !digits.isEmpty else { return "" }
        if trimmed.hasPrefix("+") { return digits }
        if digits.hasPrefix("00") { return String(digits.dropFirst(2)) }
        guard let callingCode else { return digits }

        let nationalLength = callingCode == "90" ? 10 : (callingCode == "40" ? 9 : 0)
        if digits.hasPrefix(callingCode), digits.count == callingCode.count + nationalLength { return digits }
        if digits.hasPrefix("0") { digits.removeFirst() }
        return digits.count == nationalLength ? callingCode + digits : digits
    }

    static func shareURL(phone: String?, message: String, callingCode: String? = nil) -> URL? {
        let number = whatsAppNumber(phone, callingCode: callingCode)
        let encoded = encodeQueryValue(message)
        if !number.isEmpty {
            return URL(string: "https://wa.me/\(number)?text=\(encoded)")
        } else {
            return URL(string: "https://wa.me/?text=\(encoded)")
        }
    }

    static func emailURL(recipientEmail: String = "", subject: String, body: String) -> URL? {
        let encSubject = encodeQueryValue(subject)
        let encBody = encodeQueryValue(plainText(body))
        return URL(string: "mailto:\(recipientEmail)?subject=\(encSubject)&body=\(encBody)")
    }

    /// WhatsApp shows `*text*` as bold; elsewhere (email) the asterisks would appear literally.
    static func plainText(_ message: String) -> String {
        message.replacingOccurrences(of: "*", with: "")
    }

    /// Same currency format as the printed receipt (locale grouping and decimals, symbol placement).
    static func formatAmount(_ value: Double, currency: AppCurrency, l10n: L10n) -> String {
        AppFormat.currency(value, currency, l10n: l10n)
    }

    static func formatRate(_ rate: Double, l10n: L10n) -> String {
        AppFormat.percent(rate, l10n: l10n, maximumFractionDigits: 2)
    }

    static func receiptSummary(draft: ReceiptDraft, buildingName: String, l10n: L10n) -> String {
        let building = buildingName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? l10n.defaultBuildingName : buildingName
        let total = formatAmount(draft.amount, currency: draft.currency, l10n: l10n)
        let hasLateFee = draft.isLateFeeApplied && draft.lateFeeAmount > 0
        let base = draft.baseAmount > 0 ? draft.baseAmount : Money.difference(draft.amount, draft.lateFeeAmount)
        let notes = draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let issuer = draft.issuer.trimmingCharacters(in: .whitespacesAndNewlines)
        let showFlat = draft.showApartmentNumber && draft.apartmentNumber > 0

        var lines: [String] = []
        switch l10n.resolvedLanguage {
        case .turkish:
            let kindText = draft.kind == .managementExpense ? "işletme harcaması belgesi" : (draft.kind == .outcome ? "iade makbuzu" : "aidat tahsilat makbuzu")
            lines.append("Sayın *\(draft.receiver)*,")
            lines.append("*\(building)* yönetimi tarafından \(draft.monthYear) dönemi için #\(draft.sequenceNumber) numaralı \(kindText) düzenlenmiştir.")
            lines.append("")
            lines.append("📍 Muhatap: \(showFlat ? "Daire \(draft.apartmentNumber) - " : "")\(draft.receiver)")
            lines.append("💰 Tutar: \(total)")
            if hasLateFee {
                lines.append("    Aidat: \(formatAmount(base, currency: draft.currency, l10n: l10n))")
                lines.append("    Gecikme tazminatı: \(formatAmount(draft.lateFeeAmount, currency: draft.currency, l10n: l10n))")
            }
            lines.append("📅 Tarih: \(draft.createdDate)")
            if !notes.isEmpty { lines.append("📝 Açıklama: \(notes)") }
            lines.append("")
            lines.append("Bilgilerinize sunarız.")
            if !issuer.isEmpty { lines.append("Yönetici: \(issuer)") }
        case .romanian:
            let kindText = draft.kind == .managementExpense ? "cheltuială administrație" : (draft.kind == .outcome ? "dispoziție de plată" : "chitanță întreținere")
            lines.append("Stimate/Stimată *\(draft.receiver)*,")
            lines.append("Asociația *\(building)* a emis \(kindText) cu seria #\(draft.sequenceNumber) pentru perioada \(draft.monthYear).")
            lines.append("")
            lines.append("📍 Beneficiar: \(showFlat ? "Ap. \(draft.apartmentNumber) - " : "")\(draft.receiver)")
            lines.append("💰 Sumă: \(total)")
            if hasLateFee {
                lines.append("    Întreținere: \(formatAmount(base, currency: draft.currency, l10n: l10n))")
                lines.append("    Penalități de întârziere: \(formatAmount(draft.lateFeeAmount, currency: draft.currency, l10n: l10n))")
            }
            lines.append("📅 Data: \(draft.createdDate)")
            if !notes.isEmpty { lines.append("📝 Detalii: \(notes)") }
            lines.append("")
            lines.append("Cu stimă,")
            if !issuer.isEmpty { lines.append("Administrator: \(issuer)") }
        default:
            let kindText = draft.kind == .managementExpense ? "operating expense voucher" : (draft.kind == .outcome ? "resident refund receipt" : "dues collection receipt")
            lines.append("Dear *\(draft.receiver)*,")
            lines.append("*\(building)* management has issued receipt #\(draft.sequenceNumber) (\(kindText)) for the period of \(draft.monthYear).")
            lines.append("")
            lines.append("📍 Payee/Unit: \(showFlat ? "Unit \(draft.apartmentNumber) - " : "")\(draft.receiver)")
            lines.append("💰 Amount: \(total)")
            if hasLateFee {
                lines.append("    Dues: \(formatAmount(base, currency: draft.currency, l10n: l10n))")
                lines.append("    Late fee: \(formatAmount(draft.lateFeeAmount, currency: draft.currency, l10n: l10n))")
            }
            lines.append("📅 Date: \(draft.createdDate)")
            if !notes.isEmpty { lines.append("📝 Notes: \(notes)") }
            lines.append("")
            lines.append("Best regards,")
            if !issuer.isEmpty { lines.append("Manager: \(issuer)") }
        }
        return lines.joined(separator: "\n")
    }

    /// Payment reminder for an unpaid flat. Uses the owner's name when known; amounts follow the receipt format.
    static func paymentReminder(
        flat: Int,
        owner: String,
        period: String,
        dues: Double?,
        currency: AppCurrency,
        lateFeeRate: Double?,
        lateMonths: Int = 1,
        buildingName: String,
        manager: String,
        l10n: L10n
    ) -> String {
        let ownerName = owner.trimmingCharacters(in: .whitespacesAndNewlines)
        let duesText = dues.map { formatAmount($0, currency: currency, l10n: l10n) }
        let fee = (dues != nil && lateFeeRate != nil && lateMonths > 0) ? LateFeeCalculator.fee(base: dues!, monthlyRate: lateFeeRate!, months: lateMonths) : nil
        let feeText = fee.map { formatAmount($0, currency: currency, l10n: l10n) }
        let totalText = (dues != nil && fee != nil) ? formatAmount(LateFeeCalculator.grandTotal(base: dues!, lateFee: fee!), currency: currency, l10n: l10n) : nil
        let rateText = lateFeeRate.map { formatRate($0, l10n: l10n) }

        switch l10n.resolvedLanguage {
        case .turkish:
            let greeting = ownerName.isEmpty ? "Sayın Komşumuz (Daire \(flat))" : "Sayın *\(ownerName)* (Daire \(flat))"
            var body = "\(greeting), \(buildingName) \(period) dönemi"
            if let duesText { body += " \(duesText)" }
            if let feeText, let totalText, let rateText {
                body += " aidat ve aylık \(rateText) gecikme tazminatı (\(feeText)) ile birlikte toplam \(totalText) ödemeniz"
            } else {
                body += " aidat ödemeniz"
            }
            return body + " henüz kaydımıza geçmemiştir. Bilginize sunar, iyi günler dileriz. - \(manager)"
        case .romanian:
            let greeting = ownerName.isEmpty ? "Stimate Vecin (Ap. \(flat))" : "Stimate/Stimată *\(ownerName)* (Ap. \(flat))"
            var body = "\(greeting), plata întreținerii pentru perioada \(period) la \(buildingName)"
            if let duesText { body += " în valoare de \(duesText)" }
            if let feeText, let totalText, let rateText {
                body += ", plus penalități de întârziere (\(rateText): \(feeText)), total \(totalText),"
            }
            return body + " este în așteptare. Vă mulțumim! - \(manager)"
        default:
            let greeting = ownerName.isEmpty ? "Dear Resident (Flat \(flat))" : "Dear *\(ownerName)* (Flat \(flat))"
            var body = "\(greeting), dues payment for \(period) at \(buildingName)"
            if let duesText { body += " in the amount of \(duesText)" }
            if let feeText, let totalText, let rateText {
                body += ", plus a late fee (\(rateText): \(feeText)), total \(totalText),"
            }
            return body + " is currently pending. Thank you! - \(manager)"
        }
    }
}
