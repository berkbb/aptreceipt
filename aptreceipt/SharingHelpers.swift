import AppKit
import CoreImage

// MARK: - CoreImage QR Code Generator

enum QRCodeGenerator {
    static func generate(from string: String, size: CGFloat = 64) -> NSImage? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        let data = string.data(using: .utf8)
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage else { return nil }

        let extent = output.extent
        guard extent.width > 0, extent.height > 0 else { return nil }
        let scale = size / extent.width
        let transformed = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let rep = NSCIImageRep(ciImage: transformed)
        let image = NSImage(size: NSSize(width: size, height: size))
        image.addRepresentation(rep)
        return image
    }
}

// MARK: - WhatsApp & Sharing Helper

enum WhatsAppShareHelper {
    static func shareURL(phone: String?, message: String) -> URL? {
        let digits = (phone ?? "").filter { $0.isNumber }
        let encoded = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if !digits.isEmpty {
            return URL(string: "https://wa.me/\(digits)?text=\(encoded)")
        } else {
            return URL(string: "https://wa.me/?text=\(encoded)")
        }
    }

    static func emailURL(recipientEmail: String = "", subject: String, body: String) -> URL? {
        let encSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "mailto:\(recipientEmail)?subject=\(encSubject)&body=\(encBody)")
    }

    static func receiptSummary(draft: ReceiptDraft, buildingName: String, l10n: L10n) -> String {
        let currencySymbol = draft.currency.symbol
        let formattedAmount = String(format: "%.2f", draft.amount)
        switch l10n.resolvedLanguage {
        case .turkish:
            let kindText = draft.kind == .managementExpense ? "işletme harcaması belgesi" : (draft.kind == .outcome ? "iade makbuzu" : "aidat tahsilat makbuzu")
            let flatText = draft.showApartmentNumber ? "Daire \(draft.apartmentNumber) -" : ""
            return """
            Sayın *\(draft.receiver)*,
            *\(buildingName)* yönetimi tarafından \(draft.monthYear) dönemi için #\(draft.sequenceNumber) numaralı \(kindText) düzenlenmiştir.

            📍 Muhatap: \(flatText) \(draft.receiver)
            💰 Tutar: \(currencySymbol) \(formattedAmount)
            📅 Tarih: \(draft.createdDate)
            📝 Açıklama: \(draft.notes)

            Bilgilerinize sunarız.
            Yönetici: \(draft.issuer)
            """
        case .romanian:
            let kindText = draft.kind == .managementExpense ? "cheltuială administrație" : (draft.kind == .outcome ? "dispoziție de plată" : "chitanță întreținere")
            let flatText = draft.showApartmentNumber ? "Ap. \(draft.apartmentNumber) -" : ""
            return """
            Stimate/Stimată *\(draft.receiver)*,
            Asociația *\(buildingName)* a emis \(kindText) cu seria #\(draft.sequenceNumber) pentru perioada \(draft.monthYear).

            📍 Beneficiar: \(flatText) \(draft.receiver)
            💰 Sumă: \(currencySymbol) \(formattedAmount)
            📅 Data: \(draft.createdDate)
            📝 Detalii: \(draft.notes)

            Cu stimă,
            Administrator: \(draft.issuer)
            """
        default:
            let kindText = draft.kind == .managementExpense ? "operating expense voucher" : (draft.kind == .outcome ? "resident refund receipt" : "dues collection receipt")
            let flatText = draft.showApartmentNumber ? "Unit \(draft.apartmentNumber) -" : ""
            return """
            Dear *\(draft.receiver)*,
            *\(buildingName)* management has issued receipt #\(draft.sequenceNumber) (\(kindText)) for the period of \(draft.monthYear).

            📍 Payee/Unit: \(flatText) \(draft.receiver)
            💰 Amount: \(currencySymbol) \(formattedAmount)
            📅 Date: \(draft.createdDate)
            📝 Notes: \(draft.notes)

            Best regards,
            Manager: \(draft.issuer)
            """
        }
    }
}
