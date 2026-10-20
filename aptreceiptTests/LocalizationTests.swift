import CryptoKit
import PDFKit
import SwiftUI
import Vision
import XCTest
@testable import aptreceipt

/// Receipt periods, per-language formatting, one-to-one parity of the language files and no texts written per language in code.
final class LocalizationTests: XCTestCase {
    // MARK: - 12. Receipt Periods (cash summary month picker)

    func testReceiptPeriodsInAnyAppLanguageAreTheSameMonth() throws {
        let october = ReceiptPeriod(year: 2026, month: 10)
        for text in ["Ekim 2026", "October 2026", "octombrie 2026", "Octombrie 2026", " EKİM 2026 ", "ekim 2026"] {
            XCTAssertEqual(ReceiptPeriod(monthYear: text), october, text)
        }
        XCTAssertEqual(ReceiptPeriod(monthYear: "Şubat 2027"), ReceiptPeriod(year: 2027, month: 2))
        XCTAssertEqual(ReceiptPeriod(monthYear: "August 2026"), ReceiptPeriod(year: 2026, month: 8))
        XCTAssertEqual(ReceiptPeriod(monthYear: "Ağustos 2026"), ReceiptPeriod(year: 2026, month: 8))
        XCTAssertNil(ReceiptPeriod(monthYear: "Q4 2026"))
        XCTAssertNil(ReceiptPeriod(monthYear: ""))
        XCTAssertEqual(october.id, "2026-10")
    }

    func testReceiptPeriodTitlesFollowTheAppLanguageAndSortByDate() throws {
        let october = ReceiptPeriod(year: 2026, month: 10)
        XCTAssertEqual(october.title(locale: L10n(.turkish).locale), "Ekim 2026")
        XCTAssertEqual(october.title(locale: L10n(.english).locale), "October 2026")
        XCTAssertEqual(october.title(locale: L10n(.romanian).locale).lowercased(), "octombrie 2026")
        // A new receipt's own period text maps back to the same month.
        for language in [AppLanguage.turkish, .english, .romanian] {
            let locale = L10n(language).locale
            XCTAssertEqual(ReceiptPeriod(monthYear: october.title(locale: locale)), october, "\(language)")
        }
        // Chronological, not alphabetical ("Eylül" < "Ekim" by date even though "Ekim" < "Eylül" by letters).
        let september = try XCTUnwrap(ReceiptPeriod(monthYear: "Eylül 2026"))
        let january = try XCTUnwrap(ReceiptPeriod(monthYear: "Ocak 2027"))
        XCTAssertEqual([october, january, september].sorted(by: >), [january, october, september])
    }

    // MARK: - 13. Per-language display formatting and generated texts

    func testAmountsUseTheAppLanguageFormat() {
        let tr = AppFormat.currency(1750, .turkishLira, l10n: L10n(.turkish))
        XCTAssertTrue(tr.contains("1.750,00") && tr.contains("₺"), tr)
        let en = AppFormat.currency(1750, .usDollar, l10n: L10n(.english))
        XCTAssertTrue(en.contains("1,750.00") && en.contains("$"), en)
        let ro = AppFormat.currency(1750, .romanianLeu, l10n: L10n(.romanian))
        XCTAssertTrue(ro.contains("1.750,00") && ro.contains("Lei"), ro)
        XCTAssertFalse(tr.contains("1750.00"), tr)
    }

    func testPercentagesFollowTheAppLanguage() {
        XCTAssertEqual(AppFormat.percent(16.666, l10n: L10n(.turkish)), "%16,7")
        XCTAssertEqual(AppFormat.percent(16.666, l10n: L10n(.english)), "16.7%")
        XCTAssertEqual(AppFormat.percent(16.666, l10n: L10n(.romanian)), "16,7%")
        XCTAssertEqual(AppFormat.percent(0.2, l10n: L10n(.romanian), maximumFractionDigits: 2), "0,2%")
    }

    func testBatchReceiptsBulletinAndFileNamesAreTranslated() {
        XCTAssertEqual(L10n(.turkish).batchReceiverFallback(buildingName: "Test Apt", flat: 5), "Test Apt Sakini (Daire 5)")
        XCTAssertEqual(L10n(.english).batchReceiverFallback(buildingName: "Test Apt", flat: 5), "Test Apt Resident (Flat 5)")
        XCTAssertEqual(L10n(.romanian).batchReceiverFallback(buildingName: "Test Apt", flat: 5), "Locatar Test Apt (Ap. 5)")
        XCTAssertEqual(L10n(.turkish).batchReceiptNote(period: "Ekim 2026"), "Ekim 2026 dönemi bina ortak gider ve aidat payı")
        XCTAssertTrue(L10n(.english).batchReceiptNote(period: "October 2026").hasSuffix("October 2026"))
        XCTAssertFalse(L10n(.english).bulletinFooterTagline.contains("Apartman"))
        XCTAssertTrue(L10n(.turkish).bulletinFooterTagline.contains("Doğrulanabilir"))
        XCTAssertEqual(L10n(.turkish).bulletinPdfFileName(building: "test_apt", period: "Ekim_2026"), "test_apt_Mali_Pano_Raporu_Ekim_2026")
        XCTAssertEqual(L10n(.english).bulletinPdfFileName(building: "test_apt", period: "October_2026"), "test_apt_Financial_Bulletin_October_2026")
    }

    // MARK: - 14. Trilingual Parity (Turkish, English, Romanian must match one to one)

    private static let parityLanguages: [AppLanguage] = [.turkish, .english, .romanian]

    /// Strings that are legitimately the same in English and another language (brand, international words).
    private static let sameAsEnglishAllowed: Set<String> = ["aboutCopyrightFormat", "currencyEUR", "menuZoom", "okButton", "subtotal"]

    private var sourceDirectory: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("aptreceipt")
    }

    private func catalogTable(_ localization: String) throws -> [String: String] {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "Localizable", withExtension: "strings", subdirectory: nil, localization: localization))
        return try XCTUnwrap(NSDictionary(contentsOf: url) as? [String: String])
    }

    func testEveryLanguageHasItsOwnStringFile() throws {
        var keySets: [String: Set<String>] = [:]
        for language in ["en", "tr", "ro"] {
            let url = sourceDirectory.appendingPathComponent("\(language).lproj/Localizable.strings")
            let table = try XCTUnwrap(NSDictionary(contentsOf: url) as? [String: String], "\(language) has no own Localizable.strings")
            keySets[language] = Set(table.keys)
        }
        XCTAssertEqual(keySets["tr"], keySets["en"])
        XCTAssertEqual(keySets["ro"], keySets["en"])
        // All languages in one shared file is not allowed; each language keeps its own file.
        let sharedCatalogs = try FileManager.default.contentsOfDirectory(at: sourceDirectory, includingPropertiesForKeys: nil).filter { $0.pathExtension == "xcstrings" }
        XCTAssertTrue(sharedCatalogs.isEmpty, "Shared catalog found: \(sharedCatalogs.map(\.lastPathComponent))")
    }

    func testEveryCatalogStringIsReallyTranslated() throws {
        let english = try catalogTable("en")
        for localization in ["tr", "ro"] {
            let translated = try catalogTable(localization)
            for (key, englishValue) in english where !Self.sameAsEnglishAllowed.contains(key) {
                XCTAssertNotEqual(translated[key], englishValue, "\(localization).\(key) is still English: \(englishValue)")
            }
        }
    }

    func testEveryKeyUsedInCodeExistsInAllThreeLanguages() throws {
        var used = Set<String>()
        let regex = try NSRegularExpression(pattern: #"\btr\("([^"]+)"\)|"(lateFeeItemName\.[a-z]+)""#)
        let source = try String(contentsOf: sourceDirectory.appendingPathComponent("L10n.swift"), encoding: .utf8)
        for match in regex.matches(in: source, range: NSRange(source.startIndex..., in: source)) {
            for group in 1...2 {
                if let range = Range(match.range(at: group), in: source) { used.insert(String(source[range])) }
            }
        }
        XCTAssertGreaterThan(used.count, 300)
        for localization in ["en", "tr", "ro"] {
            let table = try catalogTable(localization)
            let missing = used.subtracting(table.keys).sorted()
            XCTAssertTrue(missing.isEmpty, "\(localization) is missing keys used by L10n: \(missing)")
        }
    }

    /// Drops every `\\( … )` segment, including nested parentheses, so only literal text remains.
    private static func removingInterpolations(_ literal: String) -> String {
        var result = ""
        var depth = 0
        let characters = Array(literal)
        var index = 0
        while index < characters.count {
            if depth == 0, characters[index] == "\\", index + 1 < characters.count, characters[index + 1] == "(" {
                depth = 1
                index += 2
                continue
            }
            if depth > 0 {
                if characters[index] == "(" { depth += 1 }
                if characters[index] == ")" { depth -= 1 }
                index += 1
                continue
            }
            result.append(characters[index])
            index += 1
        }
        return result
    }

    /// No user-facing text may be written straight into a view; it has to come from the catalog (L10n).
    func testNoHardcodedTextInViews() throws {
        let allowedLiterals: Set<String> = ["Babadogan Tech and Edu", "GNU GPL v3.0", "babadogan.net", "Türkçe", "English", "Română", "OK"]
        let uiCall = try NSRegularExpression(pattern: #"\b(Text|Label|Button|Toggle|Picker|TextField|Section|Menu|help|navigationTitle)\s*\(\s*"((?:[^"\\]|\\.)*)""#)
        let wordPattern = try NSRegularExpression(pattern: #"\p{L}{2,}"#)
        let files = try FileManager.default.contentsOfDirectory(at: sourceDirectory, includingPropertiesForKeys: nil).filter { $0.pathExtension == "swift" }
        XCTAssertGreaterThan(files.count, 10)
        var offenders: [String] = []
        for file in files {
            let lines = try String(contentsOf: file, encoding: .utf8).components(separatedBy: "\n")
            for (index, line) in lines.enumerated() where !line.trimmingCharacters(in: .whitespaces).hasPrefix("//") {
                for match in uiCall.matches(in: line, range: NSRange(line.startIndex..., in: line)) {
                    guard let range = Range(match.range(at: 2), in: line) else { continue }
                    let literal = String(line[range])
                    // Interpolated values (l10n.…, numbers) are fine; only literal words count.
                    let withoutInterpolation = Self.removingInterpolations(literal)
                    let hasWords = wordPattern.firstMatch(in: withoutInterpolation, range: NSRange(withoutInterpolation.startIndex..., in: withoutInterpolation)) != nil
                    if hasWords && !allowedLiterals.contains(literal) {
                        offenders.append("\(file.lastPathComponent):\(index + 1): \(literal)")
                    }
                }
            }
        }
        XCTAssertTrue(offenders.isEmpty, "Hardcoded UI text:\n" + offenders.joined(separator: "\n"))
    }

    /// Amounts and percentages on screen must go through AppFormat, never a fixed "%.2f" pattern.
    func testNoFixedNumberFormatsOnScreen() throws {
        let banned = [#"String(format: "%.2f %@""#, #"String(format: "+%.2f %@""#, #""%%%"#, #"(%\(String(format: "%.1f""#]
        let files = try FileManager.default.contentsOfDirectory(at: sourceDirectory, includingPropertiesForKeys: nil).filter { $0.pathExtension == "swift" }
        var offenders: [String] = []
        for file in files {
            let lines = try String(contentsOf: file, encoding: .utf8).components(separatedBy: "\n")
            for (index, line) in lines.enumerated() where banned.contains(where: line.contains) {
                offenders.append("\(file.lastPathComponent):\(index + 1): \(line.trimmingCharacters(in: .whitespaces))")
            }
        }
        XCTAssertTrue(offenders.isEmpty, "Fixed number formats:\n" + offenders.joined(separator: "\n"))
    }

    private func assertDistinctPerLanguage(_ label: String, file: StaticString = #filePath, line: UInt = #line, _ make: (AppLanguage) -> String) {
        let texts = Self.parityLanguages.map { make($0) }
        for (language, text) in zip(Self.parityLanguages, texts) {
            XCTAssertFalse(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "\(label) is empty in \(language)", file: file, line: line)
        }
        XCTAssertEqual(Set(texts).count, texts.count, "\(label) is not translated into every language: \(texts)", file: file, line: line)
    }

    /// Texts the code builds per language (messages, legal notes, sample data, words, file names).
    func testGeneratedTextsExistInAllThreeLanguages() {
        let draft = ReceiptDraft(receiver: "Test Resident", issuer: "Test Manager", notes: "Note", monthYear: "Ekim 2026", apartmentNumber: 5, amount: 2087.5, sequenceNumber: 7, createdDate: "19.10.2026", showApartmentNumber: true, kind: .income, currency: .turkishLira, isLateFeeApplied: true, lateFeeRate: 2.5, lateMonths: 3, lateFeeAmount: 337.5, baseAmount: 1750)

        assertDistinctPerLanguage("WhatsApp receipt message") { WhatsAppShareHelper.receiptSummary(draft: draft, buildingName: "Test Apt", l10n: L10n($0)) }
        assertDistinctPerLanguage("WhatsApp payment reminder") {
            WhatsAppShareHelper.paymentReminder(flat: 3, owner: "Test Owner", period: "10/2026", dues: 1750, currency: .turkishLira, lateFeeRate: 5, buildingName: "Test Apt", manager: "Test Manager", l10n: L10n($0))
        }
        for profile in LateFeeCountryProfile.allCases {
            assertDistinctPerLanguage("late-fee footnote \(profile)") { profile.defaultFootnote(for: $0) }
            assertDistinctPerLanguage("late-fee legal notice \(profile)") { profile.defaultLegalNotice(for: $0) }
        }
        for currency in AppCurrency.allCases {
            assertDistinctPerLanguage("amount in words \(currency)") { NumberToWords.convert(2087.5, language: $0, currency: currency) }
        }
        for kind in ReceiptKind.allCases {
            let kindDraft = ReceiptDraft(receiver: "R", issuer: "I", notes: "N", monthYear: "Ekim 2026", apartmentNumber: 5, amount: 1, sequenceNumber: 1, createdDate: "1", showApartmentNumber: true, kind: kind)
            assertDistinctPerLanguage("export file name \(kind)") { buildExportFileName(draft: kindDraft, apartmentName: "", language: $0, ext: "pdf") }
        }
        assertDistinctPerLanguage("sample building") { SampleData.defaults(for: $0).apartmentName }
        assertDistinctPerLanguage("sample vendors") { SampleData.defaults(for: $0).defaultVendors.map(\.category).joined(separator: ",") }
        assertDistinctPerLanguage("sample services") { SampleData.defaults(for: $0).defaultServices.map(\.defaultDescription).joined(separator: ",") }
        assertDistinctPerLanguage("batch receipt note") { L10n($0).batchReceiptNote(period: "10/2026") }
        assertDistinctPerLanguage("late-fee row") { L10n($0).lateFeeItemName(rate: 2.5, months: 3) }
        assertDistinctPerLanguage("month title") { ReceiptPeriod(year: 2026, month: 10).title(locale: L10n($0).locale) }
        assertDistinctPerLanguage("percent") { AppFormat.percent(16.666, l10n: L10n($0)) }
    }

    /// Every option list the user picks from has a non-empty, translated title in each language.
    func testEnumTitlesExistInAllThreeLanguages() {
        for kind in ReceiptKind.allCases {
            assertDistinctPerLanguage("receipt kind \(kind)") { kind.title(l10n: L10n($0)) }
            assertDistinctPerLanguage("receipt badge \(kind)") { kind.badgeTitle(l10n: L10n($0)) }
        }
        for theme in AppTheme.allCases {
            assertDistinctPerLanguage("theme \(theme)") { theme.title(l10n: L10n($0)) }
        }
        for profile in LateFeeCountryProfile.allCases {
            assertDistinctPerLanguage("country profile \(profile)") { profile.title(l10n: L10n($0)) }
        }
        for tab in SettingsTab.allCases {
            assertDistinctPerLanguage("settings tab \(tab)") { tab.title(l10n: L10n($0)) }
        }
        for currency in AppCurrency.allCases where currency != .euro {
            assertDistinctPerLanguage("currency \(currency)") { currency.title(l10n: L10n($0)) }
        }
    }

    // MARK: - 17. Upper-casing follows the app language (Turkish dotted İ)

    func testUppercasingFollowsTheAppLanguage() {
        XCTAssertEqual(L10n(.turkish).uppercased("Yıldız Sitesi"), "YILDIZ SİTESİ")
        XCTAssertEqual(L10n(.english).uppercased("Yıldız Sitesi"), "YILDIZ SITESI")
        XCTAssertEqual(L10n(.romanian).uppercased("Asociația Parcul Tineretului"), "ASOCIAȚIA PARCUL TINERETULUI")
        XCTAssertEqual(L10n(.turkish).uppercased(L10n(.turkish).flatPrefix), "DAİRE")
        XCTAssertEqual(L10n(.english).uppercased(L10n(.english).flatPrefix), "FLAT")
    }

    @MainActor
    func testReceiptBuildingNameUsesTheAppLanguageUppercase() {
        let draft = ReceiptDraft(receiver: "R", issuer: "I", notes: "N", monthYear: "Ekim 2026", apartmentNumber: 5, amount: 1, sequenceNumber: 1, createdDate: "1", showApartmentNumber: true, kind: .income)
        let keys = ReceiptVerificationKeyStore(fileURL: nil)
        let turkish = ReceiptDocumentView(draft: draft, apartmentName: "Yıldız Sitesi Yönetimi", signatureImage: nil, l10n: L10n(.turkish), verificationKeys: keys)
        XCTAssertEqual(turkish.qrLines[1], "YILDIZ SİTESİ YÖNETİMİ")
        let english = ReceiptDocumentView(draft: draft, apartmentName: "Yıldız Sitesi Yönetimi", signatureImage: nil, l10n: L10n(.english), verificationKeys: keys)
        XCTAssertEqual(english.qrLines[1], "YILDIZ SITESI YÖNETIMI")
    }

    // MARK: - 23. No Inline Per-Language Texts (every language in its own file)

    func testNoInlinePerLanguageTextsInCode() throws {
        // Language data that is not interface text: number-word grammar, sample data, language self-names
        // and the receipt number prefixes printed on receipts.
        let exempt: Set<String> = ["NumberToWords.swift", "SampleData.swift", "AppSettingsEnums.swift", "ReceiptVerification.swift"]
        let literal = try NSRegularExpression(pattern: #""((?:[^"\\\n]|\\.)*)""#)
        let languageCase = try NSRegularExpression(pattern: #"case \.(turkish|romanian)\b"#)
        let word = try NSRegularExpression(pattern: #"\p{L}{3,}"#)
        func hasWords(_ text: String) -> Bool {
            literal.matches(in: text, range: NSRange(text.startIndex..., in: text)).contains { match in
                guard let range = Range(match.range(at: 1), in: text) else { return false }
                let content = String(text[range])
                return word.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)) != nil
            }
        }
        var offenders: [String] = []
        let files = try FileManager.default.contentsOfDirectory(at: sourceDirectory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "swift" && !exempt.contains($0.lastPathComponent) }
        for file in files {
            let lines = try String(contentsOf: file, encoding: .utf8).components(separatedBy: "\n")
            for (index, line) in lines.enumerated() {
                if line.contains("isTurkish ?") || line.contains("isRomanian ?") {
                    offenders.append("\(file.lastPathComponent):\(index + 1)")
                }
                guard languageCase.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) != nil else { continue }
                // The case line and its body, up to the next case, default or closing brace.
                var body = [line]
                for next in lines.dropFirst(index + 1).prefix(6) {
                    let trimmed = next.trimmingCharacters(in: .whitespaces)
                    if trimmed.hasPrefix("case ") || trimmed.hasPrefix("default") || trimmed.hasPrefix("}") { break }
                    body.append(next)
                }
                if body.contains(where: hasWords) {
                    offenders.append("\(file.lastPathComponent):\(index + 1)")
                }
            }
        }
        XCTAssertTrue(offenders.isEmpty, "Texts written per language in code instead of the language files: \(offenders)")
    }

    func testEveryMessageKeyExistsInAllThreeLanguages() throws {
        let source = try String(contentsOf: sourceDirectory.appendingPathComponent("SharingHelpers.swift"), encoding: .utf8)
        let regex = try NSRegularExpression(pattern: #"message\("([A-Za-z]+)""#)
        let keys = Set(regex.matches(in: source, range: NSRange(source.startIndex..., in: source)).compactMap {
            Range($0.range(at: 1), in: source).map { String(source[$0]) }
        })
        XCTAssertGreaterThan(keys.count, 15)
        for localization in ["en", "tr", "ro"] {
            let table = try catalogTable(localization)
            for key in keys {
                XCTAssertNotNil(table[key], "\(localization) lacks \(key)")
            }
        }
    }

    func testWhatsAppMessagesCarryNoPercentSignOrEmojiAndSurviveTheLink() throws {
        for language in Self.parityLanguages {
            let l10n = L10n(language)
            let reminder = WhatsAppShareHelper.paymentReminder(flat: 3, owner: "Test Owner", period: "Ekim 2026", dues: 2000, currency: .turkishLira, lateFeeRate: 5, lateMonths: 1, buildingName: "Test Apt", manager: "Test Manager", l10n: l10n)
            XCTAssertFalse(reminder.contains("%"), "\(language): \(reminder)")
            // wa.me shows characters outside the Basic Multilingual Plane (emoji) as "�".
            let summary = WhatsAppShareHelper.receiptSummary(draft: ReceiptDraft(receiver: "Test Resident", issuer: "Test Manager", notes: "Note", monthYear: "Ekim 2026", apartmentNumber: 1, amount: 1750, sequenceNumber: 9, createdDate: "20 Ekim 2026", showApartmentNumber: true, kind: .income), buildingName: "Test Apt", l10n: l10n)
            for message in [reminder, summary] {
                XCTAssertFalse(message.unicodeScalars.contains { $0.value > 0xFFFF }, "\(language): \(message)")
            }
            let url = try XCTUnwrap(WhatsAppShareHelper.shareURL(phone: "05320000000", message: reminder, callingCode: "90"))
            let decoded = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first?.value
            XCTAssertEqual(decoded, reminder, "\(language)")
        }
        XCTAssertEqual(WhatsAppShareHelper.formatRate(2.5, l10n: L10n(.turkish)), "yüzde 2,5")
        XCTAssertEqual(WhatsAppShareHelper.formatRate(5, l10n: L10n(.english)), "5 percent")
        XCTAssertEqual(WhatsAppShareHelper.formatRate(0.2, l10n: L10n(.romanian)), "0,2 la sută")
    }
}
