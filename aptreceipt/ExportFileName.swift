import Foundation

// MARK: - File Name Sanitizer & Builder

func buildExportFileName(draft: ReceiptDraft, apartmentName: String, language: AppLanguage, ext: String) -> String {
    let l10n = L10n(language)
    let defaultApt = l10n.exportFileBuilding
    let flatPrefix = l10n.exportFileFlat
    let receiptType: String
    switch draft.kind {
    case .income: receiptType = l10n.exportFileIncome
    case .outcome: receiptType = l10n.exportFileOutcome
    case .managementExpense: receiptType = l10n.exportFileManagement
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
