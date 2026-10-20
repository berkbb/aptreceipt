import CryptoKit
import Foundation

// MARK: - Receipt Verification Code

/// Short code printed in the receipt QR text. It is an HMAC of that text with this installation's secret,
/// so AptReceipt can tell offline whether a scanned receipt was issued here and is unchanged.
enum ReceiptVerificationCode {
    /// Crockford Base32: no I, L, O or U, so a code that is read aloud or typed stays unambiguous.
    private static let alphabet = Array("0123456789ABCDEFGHJKMNPQRSTVWXYZ")
    private static let domain = Data("AptReceipt receipt code v1\n".utf8)
    /// 10 bytes of the HMAC: 80 bits, written as 16 characters in four groups.
    private static let codeByteCount = 10

    /// The text the code covers: line endings, surrounding spaces, empty lines and Unicode composition
    /// do not change it, so the same receipt gives the same code however the QR text was read.
    static func normalizedText(_ text: String) -> String {
        text.precomposedStringWithCanonicalMapping
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    /// Code for `text`, e.g. `K7QM-2XPA-9TRB-4HWD`.
    static func code(for text: String, key: SymmetricKey) -> String {
        let mac = HMAC<SHA256>.authenticationCode(for: domain + Data(normalizedText(text).utf8), using: key)
        let characters = base32(Array(mac.prefix(codeByteCount)))
        return stride(from: 0, to: characters.count, by: 4)
            .map { String(characters[$0..<min($0 + 4, characters.count)]) }
            .joined(separator: "-")
    }

    /// A typed or scanned code in canonical form. Accepts lower case, spaces, missing dashes, and O for 0 or I/L for 1.
    static func canonicalCode(_ typed: String) -> String? {
        var characters: [Character] = []
        for character in typed.uppercased() where character != "-" && !character.isWhitespace {
            switch character {
            case "O": characters.append("0")
            case "I", "L": characters.append("1")
            default:
                guard alphabet.contains(character) else { return nil }
                characters.append(character)
            }
        }
        guard characters.count == codeByteCount * 8 / 5 else { return nil }
        return stride(from: 0, to: characters.count, by: 4)
            .map { String(characters[$0..<$0 + 4]) }
            .joined(separator: "-")
    }

    /// Index of the key in `keys` that produced `code` for `text`, or `nil` when none did.
    static func matchingKeyIndex(code: String, text: String, keys: [SymmetricKey]) -> Int? {
        guard let typed = canonicalCode(code) else { return nil }
        return keys.firstIndex { constantTimeEqual(Self.code(for: text, key: $0), typed) }
    }

    /// Crockford Base32 decoding; accepts lower case, and O for 0 or I/L for 1. Trailing padding bits are dropped.
    static func base32Decode(_ text: String) -> [UInt8]? {
        var bytes: [UInt8] = []
        var buffer = 0
        var bitCount = 0
        for character in text.uppercased() {
            let normalized: Character = character == "O" ? "0" : (character == "I" || character == "L" ? "1" : character)
            guard let value = alphabet.firstIndex(of: normalized) else { return nil }
            buffer = ((buffer << 5) | value) & 0xFFFF
            bitCount += 5
            if bitCount >= 8 {
                bitCount -= 8
                bytes.append(UInt8((buffer >> bitCount) & 0xFF))
            }
        }
        return bytes
    }

    static func base32(_ bytes: [UInt8]) -> [Character] {
        var result: [Character] = []
        var buffer = 0
        var bitCount = 0
        for byte in bytes {
            buffer = (buffer << 8) | Int(byte)
            bitCount += 8
            while bitCount >= 5 {
                bitCount -= 5
                result.append(alphabet[(buffer >> bitCount) & 31])
            }
        }
        if bitCount > 0 {
            result.append(alphabet[(buffer << (5 - bitCount)) & 31])
        }
        return result
    }

    private static func constantTimeEqual(_ lhs: String, _ rhs: String) -> Bool {
        let a = Array(lhs.utf8), b = Array(rhs.utf8)
        guard a.count == b.count else { return false }
        return zip(a, b).reduce(0) { $0 | ($1.0 ^ $1.1) } == 0
    }
}

// MARK: - Verification Key Store

/// This installation's secrets for receipt verification codes. The first key signs new receipts; older keys
/// (for example this Mac's own key after restoring another Mac's backup) still verify the receipts they made.
@MainActor
final class ReceiptVerificationKeyStore {
    /// The app's keys. During a screenshot run they live in memory only (`ScreenshotMode`).
    static let shared = ReceiptVerificationKeyStore(fileURL: ScreenshotMode.verificationKeyFileURL())

    static let keyByteCount = 32

    /// File the keys are saved to; `nil` keeps them in memory only (tests and screenshot runs).
    let fileURL: URL?
    private var keyData: [Data] = []

    /// The keys file in Application Support, next to the receipt archive. Not the Keychain: ad-hoc signed
    /// builds change their code signature with every release, and the Keychain would ask for the password.
    nonisolated static var defaultFileURL: URL {
        ReceiptArchiveStore.defaultFileURL
            .deletingLastPathComponent()
            .appendingPathComponent("receipt-verification-keys")
    }

    init(fileURL: URL?) {
        self.fileURL = fileURL
        load()
    }

    /// Key for new receipt codes, created and saved on first use.
    var currentKey: SymmetricKey {
        if keyData.isEmpty {
            keyData = [SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }]
            save()
        }
        return SymmetricKey(data: keyData[0])
    }

    /// Every key that may have made a code, the current one first.
    var allKeys: [SymmetricKey] {
        _ = currentKey
        return keyData.map { SymmetricKey(data: $0) }
    }

    /// Raw keys for the system backup, the current one first.
    func exportedKeys() -> [Data] {
        _ = currentKey
        return keyData
    }

    /// Restores keys from a backup: they come first, so the restored Mac keeps issuing codes with the
    /// backup's current key, and this Mac's keys stay after them so its receipts still verify.
    func restore(_ keys: [Data]) {
        let valid = keys.filter { $0.count == Self.keyByteCount }
        guard !valid.isEmpty else { return }
        var merged: [Data] = []
        for key in valid + keyData where !merged.contains(key) {
            merged.append(key)
        }
        keyData = merged
        save()
    }

    private func load() {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return }
        guard !data.isEmpty, data.count % Self.keyByteCount == 0 else {
            // Never overwrite an unreadable keys file: keep it aside and start a new one.
            let aside = fileURL.appendingPathExtension("unreadable-\(Int(Date().timeIntervalSince1970))")
            try? FileManager.default.moveItem(at: fileURL, to: aside)
            print("ReceiptVerificationKeyStore: unreadable keys file moved to \(aside.lastPathComponent)")
            return
        }
        keyData = stride(from: 0, to: data.count, by: Self.keyByteCount).map {
            data.subdata(in: $0..<$0 + Self.keyByteCount)
        }
    }

    private func save() {
        guard let fileURL else { return }
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try keyData.reduce(Data(), +).write(to: fileURL, options: .atomic)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
        } catch {
            print("ReceiptVerificationKeyStore: save error \(error)")
        }
    }
}

// MARK: - Receipt Serial

/// The printed receipt number, e.g. `TAH-1042`: a prefix per receipt kind and language, then the sequence number.
enum ReceiptSerial {
    static func prefix(for kind: ReceiptKind, language: AppLanguage) -> String {
        switch language {
        case .turkish:
            switch kind {
            case .income: return "TAH"
            case .outcome: return "GID"
            case .managementExpense: return "HAR"
            }
        case .romanian:
            switch kind {
            case .income: return "INC"
            case .outcome: return "DIS"
            case .managementExpense: return "ADM"
            }
        case .english, .system:
            switch kind {
            case .income: return "REC"
            case .outcome: return "EXP"
            case .managementExpense: return "MGT"
            }
        }
    }

    static func formatted(kind: ReceiptKind, language: AppLanguage, sequenceNumber: Int) -> String {
        String(format: "%@-%04d", prefix(for: kind, language: language), sequenceNumber)
    }

    /// Kind, language and sequence number of the first receipt number found in `text`.
    static func parse(_ text: String) -> (kind: ReceiptKind, language: AppLanguage, sequenceNumber: Int)? {
        guard let match = text.range(of: #"\b[A-Z]{3}-\d{4,}\b"#, options: .regularExpression) else { return nil }
        let parts = text[match].split(separator: "-")
        guard parts.count == 2, let number = Int(parts[1]) else { return nil }
        for language in [AppLanguage.turkish, .english, .romanian] {
            for kind in ReceiptKind.allCases where prefix(for: kind, language: language) == parts[0] {
                return (kind, language, number)
            }
        }
        return nil
    }
}

// MARK: - Scanned Receipt Verification

/// What a scanned receipt QR text says, checked offline against this installation's keys.
struct ScannedReceiptVerification {
    enum Status: Equatable {
        /// The code was made for exactly these lines by one of this installation's keys (0 = the current key).
        case genuine(keyIndex: Int)
        /// An AptReceipt receipt whose code is missing or does not match: changed, or issued elsewhere.
        case notVerified
        /// A receipt printed before verification codes (`AptReceipt | … | …`): shown, not verified.
        case olderWithoutCode
    }

    let status: Status
    /// The receipt lines as printed, without the code line.
    let lines: [String]
    /// The code as printed, in canonical form.
    let code: String?
    let kind: ReceiptKind?
    let language: AppLanguage?
    let sequenceNumber: Int?

    private static let brand = "AptReceipt"

    /// `nil` when the text is not an AptReceipt receipt QR code. Accepts the sealed code (scanned, or copied
    /// into a message with other text around it) and the text QR codes of earlier versions.
    init?(scannedText text: String, keys: [SymmetricKey]) {
        if let sealed = ReceiptQRBlock.find(in: text) {
            let visibleText = text.replacingOccurrences(of: sealed, with: "")
            let visible = ReceiptSerial.parse(visibleText)
            if let opened = ReceiptQRBlock.open(sealed, keys: keys),
               visible.map({ $0.kind == opened.block.kind && $0.sequenceNumber == opened.block.sequenceNumber }) ?? true {
                self.status = .genuine(keyIndex: opened.keyIndex)
                self.lines = opened.block.printedLines
                self.kind = opened.block.kind
                self.language = opened.block.language
                self.sequenceNumber = opened.block.sequenceNumber
            } else {
                // Sealed with another key, changed, or next to an edited receipt number: nothing can be shown.
                self.status = .notVerified
                let header = ReceiptVerificationCode.normalizedText(visibleText).components(separatedBy: "\n")
                    .first { $0.hasPrefix(Self.brand) }
                self.lines = [header ?? Self.brand]
                self.kind = visible?.kind
                self.language = visible?.language
                self.sequenceNumber = visible?.sequenceNumber
            }
            self.code = nil
            return
        }

        var lines = ReceiptVerificationCode.normalizedText(text).components(separatedBy: "\n")
        if lines.count == 1, lines[0].hasPrefix(Self.brand + " | ") {
            // Receipts printed before 3.6: one line, fields separated by " | ".
            self.lines = lines[0].components(separatedBy: " | ").dropFirst().map { $0 }
            self.status = .olderWithoutCode
            self.code = nil
        } else {
            guard lines.first == Self.brand, lines.count >= 3 else { return nil }
            // Exactly as printed, so a name such as "Abcd Efgh Ijkl Mnop" is never taken for a code.
            let codePattern = #":\s*[0-9A-Z]{4}-[0-9A-Z]{4}-[0-9A-Z]{4}-[0-9A-Z]{4}$"#
            if let last = lines.last,
               let range = last.range(of: codePattern, options: .regularExpression),
               let code = ReceiptVerificationCode.canonicalCode(String(last[range].dropFirst())) {
                lines.removeLast()
                let index = ReceiptVerificationCode.matchingKeyIndex(code: code, text: lines.joined(separator: "\n"), keys: keys)
                self.status = index.map { .genuine(keyIndex: $0) } ?? .notVerified
                self.code = code
            } else {
                self.status = .notVerified
                self.code = nil
            }
            self.lines = lines
        }
        let serial = self.lines.lazy.compactMap(ReceiptSerial.parse).first
        self.kind = serial?.kind
        self.language = serial?.language
        self.sequenceNumber = serial?.sequenceNumber
    }

    /// The value part of a line (`Label: value` → `value`), which stays the same when labels are reworded.
    static func value(of line: String) -> String {
        guard let separator = line.range(of: ": ") else { return line }
        return String(line[separator.upperBound...])
    }
}

/// How a scanned receipt compares with the archive.
enum ReceiptArchiveComparison: Equatable {
    /// The archive has a receipt with this number and kind, and every printed value matches it.
    case matches
    /// The closest archived receipt with this number and kind differs in these printed lines.
    case differs(lines: [String])
    /// No archived receipt has this number and kind (deleted, or issued on another Mac).
    case missing

    /// Rebuilds each candidate's QR lines in the scanned receipt's language and compares the values, so
    /// reworded labels in a later version do not count as differences.
    static func compare(_ scan: ScannedReceiptVerification, with records: [ReceiptRecord], apartmentName: String) -> ReceiptArchiveComparison {
        guard let kind = scan.kind, let language = scan.language, let number = scan.sequenceNumber else { return .missing }
        let candidates = records.filter { $0.sequenceNumber == number && $0.kind == kind }
        guard !candidates.isEmpty else { return .missing }
        guard scan.status != .olderWithoutCode else { return .matches }

        let differences = candidates.map { record -> [String] in
            let rebuilt = ReceiptPrintedText(draft: record.toDraft(), apartmentName: apartmentName, l10n: L10n(language)).lines
            let values = Set(rebuilt.map(ScannedReceiptVerification.value(of:)))
            return scan.lines.filter { !values.contains(ScannedReceiptVerification.value(of: $0)) }
        }
        let closest = differences.min { $0.count < $1.count } ?? []
        return closest.isEmpty ? .matches : .differs(lines: closest)
    }
}

// MARK: - Printed Receipt Text

/// A receipt's printed title, number, amounts and labeled lines, shared by the paper (`ReceiptDocumentView`)
/// and the Verify Receipt window, so both always show the same values.
struct ReceiptPrintedText {
    /// Longest building, payer or manager name carried by the QR code, so it stays scannable.
    static let nameLimit = 40

    let draft: ReceiptDraft
    let apartmentName: String
    let l10n: L10n

    var mainTitle: String {
        apartmentName.isEmpty ? l10n.defaultBuildingName : l10n.uppercased(apartmentName)
    }

    var documentType: String {
        switch draft.kind {
        case .income: return l10n.incomeDocumentType
        case .outcome: return l10n.expenseDocumentType
        case .managementExpense: return l10n.managementExpenseDocumentType
        }
    }

    var serial: String {
        ReceiptSerial.formatted(kind: draft.kind, language: l10n.resolvedLanguage, sequenceNumber: draft.sequenceNumber)
    }

    var totalAmount: String { currency(draft.amount) }

    var baseAmount: String {
        currency(draft.baseAmount > 0 ? draft.baseAmount : (draft.isLateFeeApplied ? Money.difference(draft.amount, draft.lateFeeAmount) : draft.amount))
    }

    var lateFeeAmount: String { currency(draft.lateFeeAmount) }

    /// The receipt as labeled lines in its language, with the printed labels and amounts.
    var lines: [String] {
        let receiverLabel = draft.kind == .income ? l10n.invoicePayerResidentLabel : l10n.invoiceVendorLabel
        var lines = [
            "AptReceipt",
            Self.capped(mainTitle),
            "\(documentType) · \(serial)",
            Self.labeled(l10n.issueDate, draft.createdDate),
            Self.labeled(l10n.period, draft.monthYear),
            Self.labeled(receiverLabel, Self.capped(draft.receiver)),
        ]
        if draft.kind != .managementExpense, draft.showApartmentNumber, draft.apartmentNumber > 0 {
            lines.append("\(l10n.flatPrefix) \(draft.apartmentNumber)")
        }
        if draft.lateFeeAmount > 0 {
            lines.append(Self.labeled(l10n.baseDuesAmount, baseAmount))
            lines.append(Self.labeled(l10n.lateFeeCalculated, "+" + lateFeeAmount))
        }
        lines.append(Self.labeled(l10n.grandTotal, totalAmount))
        lines.append(Self.labeled(l10n.invoiceManagerLabel, Self.capped(draft.issuer)))
        return lines
    }

    static func capped(_ text: String) -> String {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.count > nameLimit ? String(text.prefix(nameLimit - 1)) + "…" : text
    }

    private static func labeled(_ label: String, _ value: String) -> String {
        let label = label.trimmingCharacters(in: .whitespaces)
        return (label.hasSuffix(":") ? label : label + ":") + " " + value
    }

    private func currency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = l10n.locale
        formatter.currencySymbol = draft.currency.symbol
        formatter.currencyCode = draft.currency.code
        return formatter.string(from: NSNumber(value: value)) ?? "\(draft.currency.symbol) \(value)"
    }
}

// MARK: - Sealed Receipt Block

/// The receipt's details sealed with this installation's key (ChaCha20-Poly1305): only AptReceipt with that
/// key can open the block, and any change to it makes opening fail. A phone that scans the QR code sees only
/// this block, so copying, sending or searching it reveals nothing personal.
struct ReceiptQRBlock: Equatable {
    static let prefix = "AR1."
    private static let formatVersion: UInt8 = 1
    private static let context = Data("AptReceipt receipt block v1".utf8)
    private static let nonceContext = Data("AptReceipt receipt block nonce v1".utf8)
    /// Fixed orders for the flags byte; never reorder (printed receipts must keep opening).
    private static let kinds: [ReceiptKind] = [.income, .outcome, .managementExpense]
    private static let languages: [AppLanguage] = [.english, .turkish, .romanian]

    struct LateFee: Equatable {
        var baseCents: Int
        var feeCents: Int
        var rateHundredths: Int
        var months: Int
    }

    var kind: ReceiptKind
    var language: AppLanguage
    var sequenceNumber: Int
    var showApartmentNumber: Bool
    var apartmentNumber: Int
    var amountCents: Int
    var currency: AppCurrency
    var lateFee: LateFee?
    var building: String
    var receiver: String
    var issuer: String
    var createdDate: String
    var period: String

    init(draft: ReceiptDraft, building: String, language: AppLanguage) {
        kind = draft.kind
        self.language = Self.languages.contains(language) ? language : .english
        sequenceNumber = max(0, draft.sequenceNumber)
        showApartmentNumber = draft.showApartmentNumber
        apartmentNumber = max(0, draft.apartmentNumber)
        amountCents = Self.cents(draft.amount)
        currency = draft.currency
        lateFee = draft.lateFeeAmount > 0
            ? LateFee(baseCents: Self.cents(draft.baseAmount), feeCents: Self.cents(draft.lateFeeAmount), rateHundredths: Self.cents(draft.lateFeeRate), months: max(0, draft.lateMonths))
            : nil
        self.building = ReceiptPrintedText.capped(building)
        receiver = ReceiptPrintedText.capped(draft.receiver)
        issuer = ReceiptPrintedText.capped(draft.issuer)
        createdDate = ReceiptPrintedText.capped(draft.createdDate)
        period = ReceiptPrintedText.capped(draft.monthYear)
    }

    /// The receipt rebuilt from the block (notes are not carried).
    var draft: ReceiptDraft {
        ReceiptDraft(
            receiver: receiver, issuer: issuer, notes: "", monthYear: period,
            apartmentNumber: apartmentNumber, amount: Self.amount(cents: amountCents), sequenceNumber: sequenceNumber,
            createdDate: createdDate, showApartmentNumber: showApartmentNumber, kind: kind, currency: currency,
            isLateFeeApplied: lateFee != nil,
            lateFeeRate: Self.amount(cents: lateFee?.rateHundredths ?? 0),
            lateMonths: lateFee?.months ?? 0,
            lateFeeAmount: Self.amount(cents: lateFee?.feeCents ?? 0),
            baseAmount: Self.amount(cents: lateFee?.baseCents ?? 0)
        )
    }

    /// The receipt's labeled lines in its own language, as printed.
    var printedLines: [String] {
        ReceiptPrintedText(draft: draft, apartmentName: building, l10n: L10n(language)).lines
    }

    /// `AR1.` followed by the sealed block in Crockford Base32. The nonce is derived from the content (as in
    /// SIV), so the same receipt always gives the same QR code and two different receipts never share a nonce.
    func sealed(with key: SymmetricKey) -> String? {
        let plain = encoded()
        let nonceKey = HKDF<SHA256>.deriveKey(inputKeyMaterial: key, info: Self.nonceContext, outputByteCount: 32)
        let nonceBytes = Data(HMAC<SHA256>.authenticationCode(for: plain, using: nonceKey).prefix(12))
        guard let nonce = try? ChaChaPoly.Nonce(data: nonceBytes),
              let box = try? ChaChaPoly.seal(plain, using: Self.sealingKey(key), nonce: nonce, authenticating: Self.context) else { return nil }
        return Self.prefix + String(ReceiptVerificationCode.base32(Array(box.combined)))
    }

    /// Opens a block with the first key that sealed it; `nil` when none did or the block was changed.
    static func open(_ sealed: String, keys: [SymmetricKey]) -> (block: ReceiptQRBlock, keyIndex: Int)? {
        guard sealed.hasPrefix(prefix),
              let bytes = ReceiptVerificationCode.base32Decode(String(sealed.dropFirst(prefix.count))),
              let box = try? ChaChaPoly.SealedBox(combined: Data(bytes)) else { return nil }
        for (index, key) in keys.enumerated() {
            if let plain = try? ChaChaPoly.open(box, using: sealingKey(key), authenticating: context),
               let block = ReceiptQRBlock(decoding: plain) {
                return (block, index)
            }
        }
        return nil
    }

    /// The first sealed block in a scanned QR code or a pasted email.
    static func find(in text: String) -> String? {
        text.range(of: #"AR1\.[0-9A-Za-z]{40,}"#, options: .regularExpression).map { String(text[$0]) }
    }

    private static func sealingKey(_ key: SymmetricKey) -> SymmetricKey {
        HKDF<SHA256>.deriveKey(inputKeyMaterial: key, info: context, outputByteCount: 32)
    }

    private static func cents(_ value: Double) -> Int {
        max(0, Money.cents(value))
    }

    private static func amount(cents: Int) -> Double {
        Money.double(Decimal(cents) / 100)
    }

    // MARK: Binary format v1

    private func encoded() -> Data {
        var data = Data([Self.formatVersion])
        var flags = UInt8(Self.kinds.firstIndex(of: kind) ?? 0) | UInt8(Self.languages.firstIndex(of: language) ?? 0) << 2
        if showApartmentNumber { flags |= 1 << 4 }
        if lateFee != nil { flags |= 1 << 5 }
        data.append(flags)
        for number in [sequenceNumber, apartmentNumber, amountCents] {
            Self.appendVarint(number, to: &data)
        }
        data.append(contentsOf: Array(currency.rawValue.utf8.prefix(3)))
        if let lateFee {
            for number in [lateFee.baseCents, lateFee.feeCents, lateFee.rateHundredths, lateFee.months] {
                Self.appendVarint(number, to: &data)
            }
        }
        for text in [building, receiver, issuer, createdDate, period] {
            let bytes = Array(text.utf8.prefix(255))
            data.append(UInt8(bytes.count))
            data.append(contentsOf: bytes)
        }
        return data
    }

    private init?(decoding data: Data) {
        var reader = ByteReader(bytes: Array(data))
        guard reader.byte() == Self.formatVersion, let flags = reader.byte() else { return nil }
        let kindIndex = Int(flags & 0b11), languageIndex = Int((flags >> 2) & 0b11)
        guard kindIndex < Self.kinds.count, languageIndex < Self.languages.count,
              let sequenceNumber = reader.varint(), let apartmentNumber = reader.varint(), let amountCents = reader.varint(),
              let code = reader.take(3), let currency = AppCurrency(rawValue: String(decoding: code, as: UTF8.self)) else { return nil }
        var lateFee: LateFee?
        if flags & (1 << 5) != 0 {
            guard let base = reader.varint(), let fee = reader.varint(), let rate = reader.varint(), let months = reader.varint() else { return nil }
            lateFee = LateFee(baseCents: base, feeCents: fee, rateHundredths: rate, months: months)
        }
        guard let building = reader.string(), let receiver = reader.string(), let issuer = reader.string(),
              let createdDate = reader.string(), let period = reader.string(), reader.isAtEnd else { return nil }
        self.kind = Self.kinds[kindIndex]
        self.language = Self.languages[languageIndex]
        self.sequenceNumber = sequenceNumber
        self.showApartmentNumber = flags & (1 << 4) != 0
        self.apartmentNumber = apartmentNumber
        self.amountCents = amountCents
        self.currency = currency
        self.lateFee = lateFee
        self.building = building
        self.receiver = receiver
        self.issuer = issuer
        self.createdDate = createdDate
        self.period = period
    }

    /// Unsigned LEB128.
    private static func appendVarint(_ number: Int, to data: inout Data) {
        var value = UInt64(max(0, number))
        repeat {
            var byte = UInt8(value & 0x7F)
            value >>= 7
            if value != 0 { byte |= 0x80 }
            data.append(byte)
        } while value != 0
    }

    private struct ByteReader {
        let bytes: [UInt8]
        var index = 0

        var isAtEnd: Bool { index == bytes.count }

        mutating func byte() -> UInt8? {
            guard index < bytes.count else { return nil }
            defer { index += 1 }
            return bytes[index]
        }

        mutating func take(_ count: Int) -> [UInt8]? {
            guard index + count <= bytes.count else { return nil }
            defer { index += count }
            return Array(bytes[index..<index + count])
        }

        mutating func varint() -> Int? {
            var value: UInt64 = 0
            for shift in stride(from: 0, to: 63, by: 7) {
                guard let byte = byte() else { return nil }
                value |= UInt64(byte & 0x7F) << UInt64(shift)
                if byte & 0x80 == 0 { return Int(exactly: value) }
            }
            return nil
        }

        mutating func string() -> String? {
            guard let length = byte(), let text = take(Int(length)) else { return nil }
            return String(bytes: text, encoding: .utf8)
        }
    }
}
