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

    private static func base32(_ bytes: [UInt8]) -> [Character] {
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

    /// `nil` when the text is not an AptReceipt receipt QR code.
    init?(scannedText: String, keys: [SymmetricKey]) {
        var lines = ReceiptVerificationCode.normalizedText(scannedText).components(separatedBy: "\n")
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
    @MainActor
    static func compare(_ scan: ScannedReceiptVerification, with records: [ReceiptRecord], apartmentName: String) -> ReceiptArchiveComparison {
        guard let kind = scan.kind, let language = scan.language, let number = scan.sequenceNumber else { return .missing }
        let candidates = records.filter { $0.sequenceNumber == number && $0.kind == kind }
        guard !candidates.isEmpty else { return .missing }
        guard scan.status != .olderWithoutCode else { return .matches }

        let keys = ReceiptVerificationKeyStore(fileURL: nil)
        let differences = candidates.map { record -> [String] in
            let rebuilt = ReceiptDocumentView(
                draft: record.toDraft(), apartmentName: apartmentName, signatureImage: nil,
                l10n: L10n(language), verificationKeys: keys
            ).qrText.components(separatedBy: "\n").dropLast()
            let values = Set(rebuilt.map(ScannedReceiptVerification.value(of:)))
            return scan.lines.filter { !values.contains(ScannedReceiptVerification.value(of: $0)) }
        }
        let closest = differences.min { $0.count < $1.count } ?? []
        return closest.isEmpty ? .matches : .differs(lines: closest)
    }
}
