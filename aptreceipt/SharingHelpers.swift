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

    /// The rate in words ("yüzde 5", "5 percent", "5 la sută"). WhatsApp links must not carry a "%" sign: wa.me
    /// decodes the text more than once, which turned "%5,0" into broken characters.
    static func formatRate(_ rate: Double, l10n: L10n) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = l10n.locale
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return l10n.message("waRatePercent", formatter.string(from: NSNumber(value: rate)) ?? "\(rate)")
    }

    static func receiptSummary(draft: ReceiptDraft, buildingName: String, l10n: L10n) -> String {
        let building = buildingName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? l10n.defaultBuildingName : buildingName
        let total = formatAmount(draft.amount, currency: draft.currency, l10n: l10n)
        let hasLateFee = draft.isLateFeeApplied && draft.lateFeeAmount > 0
        let base = draft.baseAmount > 0 ? draft.baseAmount : Money.difference(draft.amount, draft.lateFeeAmount)
        let notes = draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let issuer = draft.issuer.trimmingCharacters(in: .whitespacesAndNewlines)
        let showFlat = draft.showApartmentNumber && draft.apartmentNumber > 0
        let kindKey: String
        switch draft.kind {
        case .income: kindKey = "waKindIncome"
        case .outcome: kindKey = "waKindOutcome"
        case .managementExpense: kindKey = "waKindManagement"
        }

        var lines = [
            l10n.message("waSummaryGreeting", draft.receiver),
            l10n.message("waSummaryIssued", building, draft.monthYear, "\(draft.sequenceNumber)", l10n.message(kindKey)),
            "",
            l10n.message("waPayee", showFlat ? l10n.message("waPayeeFlat", "\(draft.apartmentNumber)", draft.receiver) : draft.receiver),
            l10n.message("waAmount", total),
        ]
        if hasLateFee {
            lines.append(l10n.message("waDues", formatAmount(base, currency: draft.currency, l10n: l10n)))
            lines.append(l10n.message("waLateFee", formatAmount(draft.lateFeeAmount, currency: draft.currency, l10n: l10n)))
        }
        lines.append(l10n.message("waDate", draft.createdDate))
        if !notes.isEmpty { lines.append(l10n.message("waNotes", notes)) }
        lines.append("")
        lines.append(l10n.message("waClosing"))
        if !issuer.isEmpty { lines.append(l10n.message("waManager", issuer)) }
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
        let greeting = ownerName.isEmpty
            ? l10n.message("waReminderGreeting", "\(flat)")
            : l10n.message("waReminderGreetingNamed", ownerName, "\(flat)")

        if let duesText, let feeText, let totalText, let rateText {
            return l10n.message("waReminderWithFee", greeting, buildingName, period, duesText, rateText, feeText, totalText, manager)
        }
        if let duesText {
            return l10n.message("waReminderDues", greeting, buildingName, period, duesText, manager)
        }
        return l10n.message("waReminderNoDues", greeting, buildingName, period, manager)
    }
}
