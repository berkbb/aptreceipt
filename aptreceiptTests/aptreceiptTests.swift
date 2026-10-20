//
//  aptreceiptTests.swift
//  aptreceiptTests
//
//  Created by berkbb on 16.03.2022.
//  Copyright © 2023-2026 Babadogan Tech and Edu. All rights reserved.
//

import CryptoKit
import XCTest
@testable import aptreceipt

final class aptreceiptTests: XCTestCase {

    // MARK: - 1. ReceiptDraft & Late Fee Tests

    func testReceiptDraftInitialization() {
        let draft = ReceiptDraft(
            receiver: "Ali Veli",
            issuer: "Ahmet Yılmaz",
            notes: "Ekim 2026 Aidatı",
            monthYear: "Ekim 2026",
            apartmentNumber: 5,
            amount: 2300.0,
            sequenceNumber: 105,
            createdDate: "19.10.2026",
            showApartmentNumber: true,
            kind: .income,
            currency: .turkishLira,
            isLateFeeApplied: true,
            lateFeeRate: 5.0,
            lateMonths: 3,
            lateFeeAmount: 300.0,
            baseAmount: 2000.0
        )

        XCTAssertEqual(draft.receiver, "Ali Veli")
        XCTAssertEqual(draft.issuer, "Ahmet Yılmaz")
        XCTAssertEqual(draft.amount, 2300.0)
        XCTAssertEqual(draft.baseAmount, 2000.0)
        XCTAssertEqual(draft.lateFeeAmount, 300.0)
        XCTAssertEqual(draft.lateFeeRate, 5.0)
        XCTAssertEqual(draft.lateMonths, 3)
        XCTAssertTrue(draft.isLateFeeApplied)
        XCTAssertEqual(draft.kind, .income)
        XCTAssertEqual(draft.currency, .turkishLira)
    }

    func testLateFeeCalculatorFee() {
        // KMK Art. 20/c: Base * (Rate / 100) * Months
        XCTAssertEqual(LateFeeCalculator.fee(base: 2000.0, monthlyRate: 5.0, months: 3), 300.0, accuracy: 0.001)
        XCTAssertEqual(LateFeeCalculator.fee(base: 2000.0, monthlyRate: 7.5, months: 2), 300.0, accuracy: 0.001)
        XCTAssertEqual(LateFeeCalculator.fee(base: 1750.0, monthlyRate: 5.0, months: 1), 87.5, accuracy: 0.001)
        XCTAssertEqual(LateFeeCalculator.fee(base: 2000.0, monthlyRate: 0.0, months: 4), 0.0, accuracy: 0.001)

        // Rounded to cents: 333.33 * 5% = 16.6665
        XCTAssertEqual(LateFeeCalculator.fee(base: 333.33, monthlyRate: 5.0, months: 1), 16.67, accuracy: 0.0001)
    }

    func testLateFeeCalculatorGrandTotal() {
        XCTAssertEqual(LateFeeCalculator.grandTotal(base: 2000.0, lateFee: 300.0), 2300.0, accuracy: 0.001)
        XCTAssertEqual(LateFeeCalculator.grandTotal(base: 1750.0, lateFee: 0.0), 1750.0, accuracy: 0.001)
        XCTAssertEqual(LateFeeCalculator.grandTotal(base: 0.1, lateFee: 0.2), 0.3, accuracy: 0.0001)
    }

    @MainActor
    func testMainScreenViewModelLateFeeTotals() {
        let settings = ReceiptSettingsStore.shared
        let viewModel = MainScreenViewModel()
        viewModel.receiptKind = .income
        viewModel.totalAmount = "2000"
        viewModel.customLateFeeRate = "5"
        viewModel.lateMonths = 3

        viewModel.isLateFeeApplied = false
        XCTAssertEqual(viewModel.calculatedLateFee(settings: settings), 0.0, accuracy: 0.001)
        XCTAssertEqual(viewModel.grandTotalAmount(settings: settings), 2000.0, accuracy: 0.001)

        viewModel.isLateFeeApplied = true
        XCTAssertEqual(viewModel.calculatedLateFee(settings: settings), 300.0, accuracy: 0.001)
        XCTAssertEqual(viewModel.grandTotalAmount(settings: settings), 2300.0, accuracy: 0.001)

        // Late fees only apply to income receipts.
        viewModel.receiptKind = .managementExpense
        XCTAssertEqual(viewModel.calculatedLateFee(settings: settings), 0.0, accuracy: 0.001)
        XCTAssertEqual(viewModel.grandTotalAmount(settings: settings), 2000.0, accuracy: 0.001)
    }

    func testReceiptDraftCodableRoundTrip() throws {
        let originalDraft = ReceiptDraft(
            receiver: "Mehmet Demir",
            issuer: "Yönetici",
            notes: "Aidat",
            monthYear: "Ekim 2026",
            apartmentNumber: 3,
            amount: 1850.0,
            sequenceNumber: 42,
            createdDate: "19.10.2026",
            showApartmentNumber: true,
            kind: .income,
            currency: .euro,
            isLateFeeApplied: true,
            lateFeeRate: 5.0,
            lateMonths: 1,
            lateFeeAmount: 88.0,
            baseAmount: 1762.0
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(originalDraft)

        let decoder = JSONDecoder()
        let decodedDraft = try decoder.decode(ReceiptDraft.self, from: data)

        XCTAssertEqual(originalDraft.id, decodedDraft.id)
        XCTAssertEqual(originalDraft.receiver, decodedDraft.receiver)
        XCTAssertEqual(originalDraft.amount, decodedDraft.amount)
        XCTAssertEqual(originalDraft.baseAmount, decodedDraft.baseAmount)
        XCTAssertEqual(originalDraft.lateFeeAmount, decodedDraft.lateFeeAmount)
        XCTAssertEqual(originalDraft.lateFeeRate, decodedDraft.lateFeeRate)
        XCTAssertEqual(originalDraft.lateMonths, decodedDraft.lateMonths)
        XCTAssertEqual(originalDraft.isLateFeeApplied, decodedDraft.isLateFeeApplied)
        XCTAssertEqual(originalDraft.currency, decodedDraft.currency)
    }

    func testReceiptDraftBackwardCompatibilityWithLegacyJSON() throws {
        // Legacy JSON without late fee keys
        let legacyJSON = """
        {
            "id": "12345678-1234-1234-1234-123456789abc",
            "receiver": "Ahmet Kaya",
            "issuer": "Yönetim",
            "notes": "Aidat Ödemesi",
            "monthYear": "Ocak 2025",
            "apartmentNumber": 4,
            "amount": 1500.0,
            "sequenceNumber": 12,
            "createdDate": "15.01.2025",
            "showApartmentNumber": true,
            "kind": "income",
            "currency": "TRY"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let draft = try decoder.decode(ReceiptDraft.self, from: legacyJSON)

        XCTAssertEqual(draft.receiver, "Ahmet Kaya")
        XCTAssertEqual(draft.amount, 1500.0)
        XCTAssertFalse(draft.isLateFeeApplied)
        XCTAssertEqual(draft.lateFeeRate, 0.0)
        XCTAssertEqual(draft.lateMonths, 0)
        XCTAssertEqual(draft.lateFeeAmount, 0.0)
        XCTAssertEqual(draft.baseAmount, 1500.0)
    }

    // MARK: - 2. Currency & Language Tests

    func testCurrencySymbolsAndIdentifiers() {
        XCTAssertEqual(AppCurrency.turkishLira.symbol, "₺")
        XCTAssertEqual(AppCurrency.turkishLira.code, "TRY")

        XCTAssertEqual(AppCurrency.euro.symbol, "€")
        XCTAssertEqual(AppCurrency.euro.code, "EUR")

        XCTAssertEqual(AppCurrency.usDollar.symbol, "$")
        XCTAssertEqual(AppCurrency.usDollar.code, "USD")

        XCTAssertEqual(AppCurrency.romanianLeu.symbol, "Lei")
        XCTAssertEqual(AppCurrency.romanianLeu.code, "RON")
    }

    func testAppLanguageLocalesAndL10n() {
        XCTAssertEqual(AppLanguage.turkish.rawValue, "tr")
        XCTAssertEqual(AppLanguage.english.rawValue, "en")
        XCTAssertEqual(AppLanguage.romanian.rawValue, "ro")

        // Verify L10n localization keys
        let trL10n = L10n(.turkish)
        XCTAssertEqual(trL10n.incomeDocumentType, "Tahsilat Makbuzu")
        XCTAssertEqual(trL10n.expenseDocumentType, "Sakin İade / Tediye Makbuzu")
        XCTAssertEqual(trL10n.statutoryRateChip, "%5.0 (Kanuni)")

        let enL10n = L10n(.english)
        XCTAssertEqual(enL10n.incomeDocumentType, "Collection Receipt")
        XCTAssertEqual(enL10n.expenseDocumentType, "Resident Refund Voucher")

        let roL10n = L10n(.romanian)
        XCTAssertEqual(roL10n.incomeDocumentType, "Chitanță Încasare")
        XCTAssertEqual(roL10n.expenseDocumentType, "Dispoziție de Plată Locatar")
    }

    func testStringCatalogHasEveryKeyInEveryLanguage() throws {
        func table(_ localization: String) throws -> [String: String] {
            let url = try XCTUnwrap(Bundle.main.url(forResource: "Localizable", withExtension: "strings", subdirectory: nil, localization: localization))
            return try XCTUnwrap(NSDictionary(contentsOf: url) as? [String: String])
        }
        func formatSpecifiers(_ text: String) -> [String] {
            let regex = try! NSRegularExpression(pattern: "%(?:\\d+\\$)?[@d]")
            return regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
                .map { String(text[Range($0.range, in: text)!]) }
                .sorted()
        }

        let english = try table("en")
        XCTAssertFalse(english.isEmpty)
        for localization in ["tr", "ro"] {
            let translated = try table(localization)
            XCTAssertEqual(Set(translated.keys), Set(english.keys), "\(localization) keys differ from en")
            for (key, value) in translated {
                XCTAssertFalse(value.isEmpty, "\(localization).\(key) is empty")
                XCTAssertEqual(formatSpecifiers(value), formatSpecifiers(english[key] ?? ""), "\(localization).\(key) format specifiers differ from en")
            }
        }
    }

    func testLateFeeItemNameFormatting() {
        XCTAssertEqual(L10n(.english).lateFeeItemName(rate: 5, months: 3), "Late Fee (%5.0 × 3 Months)")
        XCTAssertEqual(L10n(.english).lateFeeItemName(rate: 5, months: 1), "Late Fee (%5.0 × 1 Month)")
        XCTAssertEqual(L10n(.turkish).lateFeeItemName(rate: 2.5, months: 2), "Gecikme Tazminatı (%2.5 × 2 Ay)")
        XCTAssertEqual(L10n(.romanian).lateFeeItemName(rate: 5, months: 1), "Penalități Întârziere (%5.0 × 1 Lună)")
    }

    // MARK: - 3. Backup Package & Settings Store Tests

    func testSystemBackupPackageCodable() throws {
        let package = SystemBackupPackage(
            apartmentName: "Güleryüz Apartmanı",
            issuer: "Ahmet Yılmaz",
            defaultPayment: "2000",
            flatCount: 16,
            seqNumber: 150,
            language: "tr",
            currency: "TRY",
            residents: [1: "Ali", 2: "Ayşe"],
            residentPhones: [1: "05551234567"],
            vendors: [VendorRecord(name: "Otis Asansör", category: "Asansör")],
            expenseServices: [],
            archivedReceipts: [],
            isLateFeeEnabled: true,
            lateFeeMonthlyRate: 5.0,
            lateFeeDueDay: 15
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(package)

        let decoder = JSONDecoder()
        let restored = try decoder.decode(SystemBackupPackage.self, from: data)

        XCTAssertEqual(restored.apartmentName, "Güleryüz Apartmanı")
        XCTAssertEqual(restored.defaultPayment, "2000")
        XCTAssertEqual(restored.seqNumber, 150)
        XCTAssertEqual(restored.flatCount, 16)
        XCTAssertEqual(restored.isLateFeeEnabled, true)
        XCTAssertEqual(restored.lateFeeMonthlyRate, 5.0)
        XCTAssertEqual(restored.lateFeeDueDay, 15)
        XCTAssertEqual(restored.residents[1], "Ali")
        XCTAssertEqual(restored.vendors.count, 1)
        XCTAssertEqual(restored.vendors.first?.name, "Otis Asansör")
    }

    @MainActor
    func testReceiptSettingsStoreDefaults() {
        let store = ReceiptSettingsStore.shared
        XCTAssertFalse(store.apartmentName.isEmpty)
        XCTAssertGreaterThan(store.flatCount, 0)
        XCTAssertGreaterThan(store.lateFeeMonthlyRate, 0.0)
        XCTAssertGreaterThanOrEqual(store.lateFeeDueDay, 1)
        XCTAssertLessThanOrEqual(store.lateFeeDueDay, 31)
    }

    // MARK: - 4. Semver & GitHub Release Update Checker Tests

    func testLicenseViewerMatchesRepositoryLicense() throws {
        let licenseURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("LICENSE")
        let repository = try String(contentsOf: licenseURL, encoding: .utf8)
        XCTAssertEqual(LicenseViewerSheet.licenseText, repository.trimmingCharacters(in: .newlines))
    }

    func testAboutVersionAndCopyrightAreFormatted() {
        XCTAssertEqual(L10n(.english).aboutVersion("3.4.3", "10"), "Version 3.4.3 (Build 10)")
        XCTAssertEqual(L10n(.turkish).aboutVersion("3.4.3", "10"), "Sürüm 3.4.3 (Yapı 10)")
        XCTAssertEqual(L10n(.english).aboutCopyright("2026"), "© 2026 Babadogan Tech and Edu")
    }

    func testUpdateCheckFailureClassifiesStatusCodes() {
        XCTAssertNil(UpdateCheckFailure(statusCode: 200))
        XCTAssertEqual(UpdateCheckFailure(statusCode: 404), .noPublicRelease)
        XCTAssertEqual(UpdateCheckFailure(statusCode: 403), .rateLimited)
        XCTAssertEqual(UpdateCheckFailure(statusCode: 429), .rateLimited)
        XCTAssertEqual(UpdateCheckFailure(statusCode: 503), .serverError(statusCode: 503))
        XCTAssertEqual(UpdateCheckFailure(statusCode: 301), .badResponse(statusCode: 301))
    }

    func testUpdateCheckFailureSeparatesNetworkErrorsFromMissingRelease() {
        XCTAssertEqual(UpdateCheckFailure(error: URLError(.notConnectedToInternet)), .offline)
        XCTAssertEqual(UpdateCheckFailure(error: URLError(.timedOut)), .timedOut)
        XCTAssertEqual(UpdateCheckFailure(error: URLError(.cannotFindHost)), .unreachable)
        let decoding = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "bad"))
        XCTAssertEqual(UpdateCheckFailure(error: decoding), .invalidData)
    }

    func testSemverComparison() {
        // Higher minor/patch should detect update
        XCTAssertTrue(SemverCompare.isRemoteNewer(remote: "v3.4.0", local: "3.3.0"))
        XCTAssertTrue(SemverCompare.isRemoteNewer(remote: "3.3.1", local: "3.3.0"))
        XCTAssertTrue(SemverCompare.isRemoteNewer(remote: "v4.0.0", local: "3.99.99"))
        XCTAssertTrue(SemverCompare.isRemoteNewer(remote: "3.3.0.1", local: "3.3.0"))

        // Equal version should NOT detect update
        XCTAssertFalse(SemverCompare.isRemoteNewer(remote: "v3.3.0", local: "3.3.0"))
        XCTAssertFalse(SemverCompare.isRemoteNewer(remote: "3.3.0", local: "3.3.0"))

        // Older version should NOT detect update
        XCTAssertFalse(SemverCompare.isRemoteNewer(remote: "v3.2.0", local: "3.3.0"))
        XCTAssertFalse(SemverCompare.isRemoteNewer(remote: "2.9.9", local: "3.0.0"))

        // Prerelease stripped comparison
        XCTAssertFalse(SemverCompare.isRemoteNewer(remote: "v3.3.0-beta.1", local: "3.3.0"))
    }

    func testGitHubReleaseModelDecodable() throws {
        let json = """
        {
            "tag_name": "v3.4.0",
            "name": "AptReceipt v3.4.0 - macOS Native Update",
            "body": "### Features\\n- GitHub release update check\\n- International late fee profiles",
            "html_url": "https://github.com/berkbb/aptreceipt/releases/tag/v3.4.0",
            "published_at": "2026-10-19T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let release = try decoder.decode(GitHubRelease.self, from: json)

        XCTAssertEqual(release.tagName, "v3.4.0")
        XCTAssertEqual(release.name, "AptReceipt v3.4.0 - macOS Native Update")
        XCTAssertEqual(release.htmlUrl, "https://github.com/berkbb/aptreceipt/releases/tag/v3.4.0")
        XCTAssertEqual(release.id, "v3.4.0")
        XCTAssertTrue(release.assets.isEmpty)
        XCTAssertNil(release.dmgAsset)
        XCTAssertNil(release.checksumAsset)
    }

    func testGitHubReleaseAssetSelection() throws {
        let json = """
        {
            "tag_name": "v3.5.0",
            "name": "aptreceipt 3.5.0",
            "body": null,
            "html_url": "https://github.com/berkbb/aptreceipt/releases/tag/v3.5.0",
            "assets": [
                { "name": "SHA256SUMS.txt", "browser_download_url": "https://example.com/SHA256SUMS.txt", "size": 87 },
                { "name": "aptreceipt-3.5.0.dmg", "browser_download_url": "https://example.com/aptreceipt-3.5.0.dmg", "size": 4838919 }
            ]
        }
        """.data(using: .utf8)!

        let release = try JSONDecoder().decode(GitHubRelease.self, from: json)

        XCTAssertEqual(release.assets.count, 2)
        XCTAssertEqual(release.dmgAsset?.name, "aptreceipt-3.5.0.dmg")
        XCTAssertEqual(release.dmgAsset?.browserDownloadUrl, "https://example.com/aptreceipt-3.5.0.dmg")
        XCTAssertEqual(release.dmgAsset?.size, 4838919)
        XCTAssertEqual(release.checksumAsset?.name, "SHA256SUMS.txt")
    }

    func testUpdateChecksumsParsing() {
        let dmgDigest = String(repeating: "a", count: 64)
        let otherDigest = String(repeating: "B", count: 64)
        let text = """
        \(dmgDigest)  aptreceipt-3.5.0.dmg
        \(otherDigest) *notes file.txt

        not-a-digest  ignored.dmg
        """

        let checksums = UpdateChecksums.parse(text)

        XCTAssertEqual(checksums["aptreceipt-3.5.0.dmg"], dmgDigest)
        XCTAssertEqual(checksums["notes file.txt"], otherDigest.lowercased())
        XCTAssertNil(checksums["ignored.dmg"])
        XCTAssertEqual(checksums.count, 2)
    }

    func testUpdateChecksumsSHA256OfFile() throws {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data("abc".utf8).write(to: fileURL)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        XCTAssertEqual(
            try UpdateChecksums.sha256(of: fileURL),
            "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        )
    }

    func testGitHubReleaseSignatureAssetLookup() {
        let dmg = GitHubReleaseAsset(name: "aptreceipt-3.5.0.dmg", browserDownloadUrl: "https://example.com/aptreceipt-3.5.0.dmg")
        let signature = GitHubReleaseAsset(name: "aptreceipt-3.5.0.dmg.sig", browserDownloadUrl: "https://example.com/aptreceipt-3.5.0.dmg.sig")
        let release = GitHubRelease(tagName: "v3.5.0", name: nil, body: nil, htmlUrl: "https://example.com", assets: [dmg, signature])

        XCTAssertEqual(release.dmgAsset, dmg)
        XCTAssertEqual(release.signatureAsset(for: dmg), signature)
        XCTAssertNil(GitHubRelease(tagName: "v3.5.0", name: nil, body: nil, htmlUrl: "https://example.com", assets: [dmg]).signatureAsset(for: dmg))
    }

    func testUpdateSignatureVerification() throws {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data("aptreceipt update payload".utf8).write(to: fileURL)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let key = Curve25519.Signing.PrivateKey()
        let publicKey = key.publicKey.rawRepresentation.base64EncodedString()
        let signature = try key.signature(for: Data(contentsOf: fileURL)).base64EncodedString()

        XCTAssertTrue(try UpdateSignature.isValid(fileURL: fileURL, signatureBase64: signature + "\n", publicKeyBase64: publicKey))

        let otherPublicKey = Curve25519.Signing.PrivateKey().publicKey.rawRepresentation.base64EncodedString()
        XCTAssertFalse(try UpdateSignature.isValid(fileURL: fileURL, signatureBase64: signature, publicKeyBase64: otherPublicKey))
        XCTAssertFalse(try UpdateSignature.isValid(fileURL: fileURL, signatureBase64: "not-base64", publicKeyBase64: publicKey))

        try Data("tampered payload".utf8).write(to: fileURL)
        XCTAssertFalse(try UpdateSignature.isValid(fileURL: fileURL, signatureBase64: signature, publicKeyBase64: publicKey))
    }

    func testBundledUpdatePublicKeyIsValid() throws {
        let publicKey = try XCTUnwrap(UpdateSignature.bundledPublicKey)
        let data = try XCTUnwrap(Data(base64Encoded: publicKey))
        XCTAssertNoThrow(try Curve25519.Signing.PublicKey(rawRepresentation: data))
    }

    // MARK: - 5. Multi-Country Late Fee Profiles Tests

    func testLateFeeCountryProfiles() {
        // Turkey
        let turkey = LateFeeCountryProfile.turkey
        XCTAssertEqual(turkey.flagEmoji, "🇹🇷")
        XCTAssertEqual(turkey.defaultRate, 5.0)
        XCTAssertEqual(turkey.defaultDueDay, 15)
        XCTAssertEqual(turkey.defaultGraceDays, 0)
        XCTAssertTrue(turkey.quickPresets.contains(5.0))
        XCTAssertTrue(turkey.defaultFootnote(for: .turkish).contains("Kat Mülkiyeti Kanunu"))
        XCTAssertTrue(turkey.defaultLegalNotice(for: .turkish).contains("Madde 20/c"))

        // Romania
        let romania = LateFeeCountryProfile.romania
        XCTAssertEqual(romania.flagEmoji, "🇷🇴")
        XCTAssertEqual(romania.defaultRate, 6.0)
        XCTAssertEqual(romania.defaultDueDay, 20)
        XCTAssertEqual(romania.defaultGraceDays, 30)
        XCTAssertTrue(romania.defaultFootnote(for: .romanian).contains("196/2018"))
        XCTAssertTrue(romania.defaultLegalNotice(for: .english).contains("Law 196/2018"))

        // International
        let intl = LateFeeCountryProfile.international
        XCTAssertEqual(intl.flagEmoji, "🌐")
        XCTAssertEqual(intl.defaultRate, 5.0)
        XCTAssertEqual(intl.defaultDueDay, 10)
        XCTAssertEqual(intl.defaultGraceDays, 10)
        XCTAssertTrue(intl.defaultFootnote(for: .english).contains("condominium"))

        // Custom
        let custom = LateFeeCountryProfile.custom
        XCTAssertEqual(custom.flagEmoji, "⚙️")
        XCTAssertEqual(custom.defaultRate, 5.0)
    }

    func testSystemBackupPackageWithCountryProfile() throws {
        let package = SystemBackupPackage(
            apartmentName: "Palas Residence",
            issuer: "Admin",
            defaultPayment: "500",
            flatCount: 20,
            seqNumber: 1,
            language: "ro",
            currency: "RON",
            residents: [:],
            residentPhones: [:],
            vendors: [],
            expenseServices: [],
            archivedReceipts: [],
            isLateFeeEnabled: true,
            lateFeeMonthlyRate: 6.0,
            lateFeeDueDay: 20,
            lateFeeCountryProfile: LateFeeCountryProfile.romania.rawValue,
            lateFeeGracePeriodDays: 30,
            lateFeeCustomFootnote: "Penalități cf. Legea 196/2018"
        )

        let encoded = try JSONEncoder().encode(package)
        let decoded = try JSONDecoder().decode(SystemBackupPackage.self, from: encoded)

        XCTAssertEqual(decoded.lateFeeCountryProfile, LateFeeCountryProfile.romania.rawValue)
        XCTAssertEqual(decoded.lateFeeGracePeriodDays, 30)
        XCTAssertEqual(decoded.lateFeeCustomFootnote, "Penalități cf. Legea 196/2018")
    }

    // MARK: - 6. Settings Draft Characterization (Arhivar alignment phase 0)
    //
    // These pin today's settings behavior before the settings window is restructured, so the
    // migration cannot silently drop or change an app-specific feature. They use an isolated
    // UserDefaults suite and never touch the real app data.

    @MainActor
    private func makeIsolatedStore() -> ReceiptSettingsStore {
        let store = ReceiptSettingsStore(defaults: InMemoryDefaults())
        store.language = .english
        return store
    }

    @MainActor
    func testSettingsDraftSaveWritesTrimmedClampedValuesToStore() {
        let store = makeIsolatedStore()
        let draft = SettingsViewModel()
        draft.load(from: store)
        draft.language = .english
        draft.apartmentName = "  Test Building  "
        draft.issuer = "jane doe"
        draft.defaultPayment = " 1500,50 "
        draft.flatCount = "4"
        draft.sequenceNumber = "7"
        draft.theme = .dark
        draft.currency = .euro
        draft.isLateFeeEnabled = true
        draft.lateFeeMonthlyRate = "7,5"
        draft.lateFeeDueDay = 40
        draft.lateFeeGracePeriodDays = 99
        draft.lateFeeCustomFootnote = "  Custom note  "
        draft.residents[2] = "  john smith "
        draft.residentPhones[2] = " 0000000000 "
        draft.newVendorName = "Sample Lift Co"
        draft.addVendor()

        XCTAssertTrue(draft.save(to: store))
        XCTAssertNil(draft.validationError)
        XCTAssertEqual(store.apartmentName, "Test Building")
        XCTAssertEqual(store.issuer, "Jane Doe")
        XCTAssertEqual(store.defaultPayment, "1500,50")
        XCTAssertEqual(store.flatCount, 4)
        XCTAssertEqual(store.seqNumber, 7)
        XCTAssertEqual(store.theme, .dark)
        XCTAssertEqual(store.currency, .euro)
        XCTAssertTrue(store.isLateFeeEnabled)
        XCTAssertEqual(store.lateFeeMonthlyRate, 7.5, accuracy: 0.0001)
        XCTAssertEqual(store.lateFeeDueDay, 31)
        XCTAssertEqual(store.lateFeeGracePeriodDays, 60)
        XCTAssertEqual(store.lateFeeCustomFootnote, "Custom note")
        XCTAssertEqual(store.owner(for: 2), "John Smith")
        XCTAssertEqual(store.ownerPhone(for: 2), "0000000000")
        XCTAssertTrue(store.vendors.contains { $0.name == "Sample Lift Co" })

        // A fresh draft loads back exactly what was saved.
        let reloaded = SettingsViewModel()
        reloaded.load(from: store)
        XCTAssertEqual(reloaded.apartmentName, "Test Building")
        XCTAssertEqual(reloaded.flatCount, "4")
        XCTAssertEqual(reloaded.sequenceNumber, "7")
        XCTAssertEqual(reloaded.lateFeeMonthlyRate, "7.5")
        XCTAssertEqual(reloaded.residents[2], "John Smith")
        XCTAssertEqual(reloaded.residents.count, 4)
    }

    @MainActor
    func testSettingsDraftValidationRejectsInvalidInputAndLeavesStoreUntouched() {
        let store = makeIsolatedStore()
        let l10n = L10n(.english)
        let cases: [(String, (SettingsViewModel) -> Void, String)] = [
            ("zero flats", { $0.flatCount = "0" }, l10n.errFlatCountInvalid),
            ("non-numeric flats", { $0.flatCount = "abc" }, l10n.errFlatCountInvalid),
            ("zero sequence", { $0.sequenceNumber = "0" }, l10n.errSequenceInvalid),
            ("non-numeric dues", { $0.defaultPayment = "abc" }, l10n.errAmountInvalid),
            ("blank building", { $0.apartmentName = "   " }, l10n.errBuildingIssuerRequired),
            ("blank issuer", { $0.issuer = "" }, l10n.errBuildingIssuerRequired),
        ]
        let originalName = store.apartmentName
        let originalFlats = store.flatCount

        for (label, breakDraft, expectedMessage) in cases {
            let draft = SettingsViewModel()
            draft.load(from: store)
            draft.language = .english
            breakDraft(draft)
            XCTAssertFalse(draft.save(to: store), label)
            XCTAssertEqual(draft.validationError?.message, expectedMessage, label)
            XCTAssertEqual(store.apartmentName, originalName, label)
            XCTAssertEqual(store.flatCount, originalFlats, label)
        }
    }

    @MainActor
    func testSettingsDraftWithoutSaveLeavesStoreUntouched() {
        let store = makeIsolatedStore()
        let originalName = store.apartmentName
        let originalVendors = store.vendors
        let draft = SettingsViewModel()
        draft.load(from: store)

        draft.apartmentName = "Changed"
        draft.clearAllResidents()
        draft.loadSampleVendorsAndServices(for: .romanian)
        draft.vendors.removeAll()

        // Cancel only closes the window; the store keeps its values.
        XCTAssertEqual(store.apartmentName, originalName)
        XCTAssertEqual(store.vendors, originalVendors)
    }

    @MainActor
    func testSelectCountryProfileResetsEveryLateFeeField() {
        let draft = SettingsViewModel()
        for profile in LateFeeCountryProfile.allCases {
            draft.lateFeeCustomFootnote = "stale"
            draft.lateFeeDueDay = 3
            draft.selectCountryProfile(profile)
            XCTAssertEqual(draft.lateFeeCountryProfile, profile)
            XCTAssertEqual(draft.lateFeeMonthlyRate, String(format: "%.1f", profile.defaultRate))
            XCTAssertEqual(draft.lateFeeDueDay, profile.defaultDueDay)
            XCTAssertEqual(draft.lateFeeGracePeriodDays, profile.defaultGraceDays)
            XCTAssertEqual(draft.lateFeeCustomFootnote, "")
        }
    }

    @MainActor
    func testQuickFlatCountFillsOnlyEmptyResidentSlots() {
        let draft = SettingsViewModel()
        draft.language = .english
        draft.residents = [1: "Kept Resident"]
        draft.setQuickFlatCount(3)

        let samples = SampleData.defaults(for: .english)
        XCTAssertEqual(draft.flatCount, "3")
        XCTAssertEqual(draft.residents[1], "Kept Resident")
        for (flat, name) in samples.residents where flat > 1 && flat <= 3 {
            XCTAssertEqual(draft.residents[flat], name)
        }
        XCTAssertTrue(draft.residents.keys.allSatisfy { $0 <= 3 })
    }

    @MainActor
    func testResidentDirectoryCountsSearchFillAndClear() {
        let draft = SettingsViewModel()
        draft.flatCount = "3"
        draft.residents = [1: "Alice Example", 2: "  ", 3: ""]
        draft.residentPhones = [1: "111"]

        XCTAssertEqual(draft.availableApartments, [1, 2, 3])
        XCTAssertEqual(draft.registeredCount, 1)
        XCTAssertEqual(draft.unassignedCount, 2)
        draft.residentSearchQuery = "alice"
        XCTAssertEqual(draft.filteredApartments, [1])
        draft.residentSearchQuery = "3"
        XCTAssertEqual(draft.filteredApartments, [3])
        draft.residentSearchQuery = ""

        draft.clearResident(for: 1)
        XCTAssertEqual(draft.residents[1], "")
        XCTAssertEqual(draft.residentPhones[1], "")

        draft.fillSampleResidents(for: .english)
        let samples = SampleData.defaults(for: .english)
        for (flat, name) in samples.residents {
            XCTAssertEqual(draft.residents[flat], flat <= 3 ? name : nil)
        }

        draft.clearAllResidents()
        XCTAssertEqual(draft.registeredCount, 0)
        XCTAssertTrue([1, 2, 3].allSatisfy { draft.residentPhones[$0] == "" })
    }

    @MainActor
    func testVendorAndServiceDraftEditing() {
        let draft = SettingsViewModel()

        draft.newVendorName = "   "
        draft.addVendor()
        XCTAssertTrue(draft.vendors.isEmpty)

        draft.newVendorName = "  Lift Service  "
        draft.newVendorCategory = " Elevator "
        draft.newVendorContact = " 000 "
        draft.addVendor()
        XCTAssertEqual(draft.vendors, [VendorRecord(id: draft.vendors[0].id, name: "Lift Service", category: "Elevator", contactInfo: "000")])
        XCTAssertEqual([draft.newVendorName, draft.newVendorCategory, draft.newVendorContact], ["", "", ""])
        draft.vendorSearchQuery = "elev"
        XCTAssertEqual(draft.filteredVendors.count, 1)
        draft.deleteVendor(id: draft.vendors[0].id)
        XCTAssertTrue(draft.vendors.isEmpty)

        draft.newServiceName = " Cleaning "
        draft.addExpenseService()
        let service = draft.expenseServices[0]
        XCTAssertEqual(service.name, "Cleaning")
        XCTAssertEqual(service.defaultDescription, "Cleaning")
        XCTAssertEqual(service.iconName, "briefcase.fill")
        XCTAssertNil(service.suggestedVendor)
        XCTAssertEqual([draft.newServiceName, draft.newServiceDescription, draft.newServiceSuggestedVendor], ["", "", ""])

        draft.newServiceName = "Repairs"
        draft.newServiceDescription = "Monthly repairs"
        draft.newServiceSuggestedVendor = "Lift Service"
        draft.addExpenseService()
        XCTAssertEqual(draft.expenseServices[1].defaultDescription, "Monthly repairs")
        XCTAssertEqual(draft.expenseServices[1].suggestedVendor, "Lift Service")
        draft.deleteExpenseService(id: service.id)
        XCTAssertEqual(draft.expenseServices.map(\.name), ["Repairs"])
    }

    @MainActor
    func testScenarioSamplesFillTheDraftOnly() {
        let store = makeIsolatedStore()
        let originalName = store.apartmentName
        let draft = SettingsViewModel()
        draft.load(from: store)

        draft.loadSampleDefaults(for: .romanian)

        let samples = SampleData.defaults(for: .romanian)
        XCTAssertEqual(draft.apartmentName, samples.apartmentName)
        XCTAssertEqual(draft.issuer, samples.issuer)
        XCTAssertEqual(draft.defaultPayment, samples.defaultPayment)
        XCTAssertEqual(draft.flatCount, String(samples.flatCount))
        XCTAssertEqual(draft.currency, samples.currency)
        // Sample records get fresh UUIDs on every call, so compare their content.
        XCTAssertEqual(draft.vendors.map { [$0.name, $0.category, $0.contactInfo] },
                       samples.defaultVendors.map { [$0.name, $0.category, $0.contactInfo] })
        XCTAssertEqual(draft.expenseServices.map { [$0.name, $0.defaultDescription, $0.iconName, $0.suggestedVendor ?? ""] },
                       samples.defaultServices.map { [$0.name, $0.defaultDescription, $0.iconName, $0.suggestedVendor ?? ""] })
        XCTAssertEqual(draft.residents, samples.residents)
        XCTAssertTrue(draft.showSampleDefaultsFeedback)
        XCTAssertEqual(store.apartmentName, originalName)
    }

    @MainActor
    func testSettingsTabsStayCompleteAndLocalized() {
        // Order, identifiers and icons are part of the feature set (deep links, screenshots).
        XCTAssertEqual(SettingsTab.allCases.map(\.rawValue), ["building", "residents", "vendors", "appearance", "signature", "backup", "about"])
        for tab in SettingsTab.allCases {
            XCTAssertFalse(tab.iconName.isEmpty, tab.rawValue)
            for language in [AppLanguage.english, .turkish, .romanian] {
                let title = tab.title(l10n: L10n(language))
                XCTAssertFalse(title.isEmpty, "\(tab.rawValue) \(language)")
            }
        }
    }

    // MARK: - 7. Settings Toolbar Tabs (Arhivar alignment phase 1)

    func testSettingsTabWidthsFollowArhivarStandard() {
        for tab in SettingsTab.allCases {
            let expected: CGFloat = (tab == .residents || tab == .vendors) ? 760 : 560
            XCTAssertEqual(tab.preferredWidth, expected, tab.rawValue)
        }
        XCTAssertGreaterThan(SettingsTab.preferredHeight, 0)
    }

    @MainActor
    func testSettingsToolbarTabsShareOneDraftAndOpenOnTheRequestedTab() {
        let store = makeIsolatedStore()
        for initialTab in SettingsTab.allCases {
            let controller = SettingsTabViewController(settings: store, initialTab: initialTab) {}
            XCTAssertEqual(controller.tabStyle, .toolbar)
            XCTAssertEqual(controller.tabViewItems.compactMap { $0.identifier as? String }, SettingsTab.allCases.map(\.rawValue))
            XCTAssertEqual(controller.selectedSettingsTab, initialTab)
            XCTAssertEqual(controller.draft.selectedTab, initialTab)
            XCTAssertEqual(controller.tabViewItems.map(\.label), SettingsTab.allCases.map { $0.title(l10n: store.l10n) })
        }

        let controller = SettingsTabViewController(settings: store, initialTab: .general) {}
        controller.draft.load(from: store)
        controller.draft.apartmentName = "Edited On Building Tab"
        controller.selectedTabViewItemIndex = SettingsTab.allCases.firstIndex(of: .vendors)!
        XCTAssertEqual(controller.draft.selectedTab, .vendors)
        // Switching tabs keeps the shared draft; nothing reloads it from the store.
        XCTAssertEqual(controller.draft.apartmentName, "Edited On Building Tab")
        XCTAssertTrue(controller.draft.isLoaded)
    }

    // MARK: - 8. Appearance Tab (Arhivar alignment phase 2)

    @MainActor
    func testLanguageSelectionOnSampleBuildingSwitchesSamplesAndSavesDraft() {
        let store = makeIsolatedStore()
        let draft = SettingsViewModel()
        draft.load(from: store)
        draft.loadSampleDefaults(for: .english)
        draft.sequenceNumber = "9"

        draft.selectLanguage(.romanian, settings: store)

        let samples = SampleData.defaults(for: .romanian)
        XCTAssertEqual(store.language, .romanian)
        XCTAssertEqual(store.currency, AppCurrency.default(for: .romanian))
        XCTAssertEqual(draft.currency, AppCurrency.default(for: .romanian))
        XCTAssertEqual(store.apartmentName, samples.apartmentName)
        // The whole draft is committed, including fields edited on other tabs.
        XCTAssertEqual(store.seqNumber, 9)
        XCTAssertTrue(draft.showRestartAlert)
    }

    @MainActor
    func testLanguageSelectionOnCustomBuildingKeepsDraftUnsaved() {
        let store = makeIsolatedStore()
        let draft = SettingsViewModel()
        draft.load(from: store)
        draft.apartmentName = "Custom Building"
        draft.sequenceNumber = "9"
        let originalSequence = store.seqNumber
        let originalName = store.apartmentName

        draft.selectLanguage(.turkish, settings: store)

        XCTAssertEqual(store.language, .turkish)
        XCTAssertEqual(store.currency, AppCurrency.default(for: .turkish))
        XCTAssertEqual(draft.apartmentName, "Custom Building")
        XCTAssertEqual(store.apartmentName, originalName)
        XCTAssertEqual(store.seqNumber, originalSequence)
        XCTAssertTrue(draft.showRestartAlert)
    }

    // MARK: - 9. About Tab: Updates and Reset (Arhivar alignment phase 3)

    @MainActor
    func testLaunchUpdateCheckIsOptInAndPersists() {
        let defaults = InMemoryDefaults()
        let store = ReceiptSettingsStore(defaults: defaults)
        XCTAssertFalse(store.checkUpdatesAtLaunch)

        store.checkUpdatesAtLaunch = true
        XCTAssertTrue(ReceiptSettingsStore(defaults: defaults).checkUpdatesAtLaunch)
    }

    @MainActor
    func testPreferenceResetRestoresPreferencesAndKeepsAllData() {
        let defaults = InMemoryDefaults()
        let store = ReceiptSettingsStore(defaults: defaults)
        store.apartmentName = "Kept Building"
        store.issuer = "Kept Manager"
        store.defaultPayment = "1234"
        store.flatCount = 5
        store.seqNumber = 42
        store.saveOwner("Kept Resident", apartmentNumber: 2)
        store.saveOwnerPhone("0000", apartmentNumber: 2)
        store.vendors = [VendorRecord(name: "Kept Vendor")]
        store.expenseServices = [ExpenseServicePreset(name: "Kept Service", defaultDescription: "Kept")]
        store.logoData = Data([1, 2, 3])
        store.signatureData = Data([4, 5, 6])

        store.language = .turkish
        store.theme = .dark
        store.currency = .euro
        store.isLateFeeEnabled = true
        store.lateFeeCountryProfile = .romania
        store.lateFeeMonthlyRate = 9
        store.lateFeeDueDay = 3
        store.lateFeeGracePeriodDays = 10
        store.lateFeeCustomFootnote = "Custom"
        store.checkUpdatesAtLaunch = true
        store.setLateFeeCountryProfile(.turkey)

        store.resetPreferencesToDefaults()

        let defaultProfile = LateFeeCountryProfile.default(for: ReceiptSettingsStore.Defaults.language)
        XCTAssertEqual(store.language, ReceiptSettingsStore.Defaults.language)
        XCTAssertEqual(store.theme, ReceiptSettingsStore.Defaults.theme)
        XCTAssertEqual(store.currency, AppCurrency.default(for: ReceiptSettingsStore.Defaults.language))
        XCTAssertFalse(store.isLateFeeEnabled)
        XCTAssertEqual(store.lateFeeCountryProfile, defaultProfile)
        XCTAssertEqual(store.lateFeeMonthlyRate, ReceiptSettingsStore.Defaults.lateFeeMonthlyRate)
        XCTAssertEqual(store.lateFeeDueDay, ReceiptSettingsStore.Defaults.lateFeeDueDay)
        XCTAssertEqual(store.lateFeeGracePeriodDays, defaultProfile.defaultGraceDays)
        XCTAssertEqual(store.lateFeeCustomFootnote, "")
        XCTAssertFalse(store.checkUpdatesAtLaunch)
        XCTAssertTrue(LateFeeCountryProfile.allCases.allSatisfy { defaults.object(forKey: "late_fee_rate_\($0.rawValue)") == nil })

        // Data survives, also after reloading from the backing store.
        for reloaded in [store, ReceiptSettingsStore(defaults: defaults)] {
            XCTAssertEqual(reloaded.apartmentName, "Kept Building")
            XCTAssertEqual(reloaded.issuer, "Kept Manager")
            XCTAssertEqual(reloaded.defaultPayment, "1234")
            XCTAssertEqual(reloaded.flatCount, 5)
            XCTAssertEqual(reloaded.seqNumber, 42)
            XCTAssertEqual(reloaded.owner(for: 2), "Kept Resident")
            XCTAssertEqual(reloaded.ownerPhone(for: 2), "0000")
            XCTAssertEqual(reloaded.vendors.map(\.name), ["Kept Vendor"])
            XCTAssertEqual(reloaded.expenseServices.map(\.name), ["Kept Service"])
            XCTAssertEqual(reloaded.logoData, Data([1, 2, 3]))
            XCTAssertEqual(reloaded.signatureData, Data([4, 5, 6]))
        }
    }

    @MainActor
    func testPreferenceResetMirrorsIntoDraftAndKeepsOtherDraftEdits() {
        let store = makeIsolatedStore()
        store.theme = .dark
        store.isLateFeeEnabled = true
        let draft = SettingsViewModel()
        draft.load(from: store)
        draft.apartmentName = "Unsaved Draft Name"
        draft.lateFeeCustomFootnote = "Unsaved footnote"

        draft.resetPreferences(settings: store)

        XCTAssertEqual(draft.theme, store.theme)
        XCTAssertEqual(draft.language, store.language)
        XCTAssertEqual(draft.currency, store.currency)
        XCTAssertFalse(draft.isLateFeeEnabled)
        XCTAssertEqual(draft.lateFeeMonthlyRate, String(format: "%.1f", store.lateFeeMonthlyRate))
        XCTAssertEqual(draft.lateFeeCustomFootnote, "")
        XCTAssertEqual(draft.apartmentName, "Unsaved Draft Name")
        XCTAssertNotEqual(store.apartmentName, "Unsaved Draft Name")
    }
}


// MARK: - Test Doubles

/// `UserDefaults` that keeps values in memory only. A real suite would leave a plist in
/// ~/Library/Preferences on every run, because cfprefsd writes it back after the domain is removed.
final class InMemoryDefaults: UserDefaults {
    private var values: [String: Any] = [:]

    convenience init() {
        self.init(suiteName: nil)!
    }

    override init?(suiteName suitename: String?) {
        super.init(suiteName: suitename)
    }

    override func object(forKey defaultName: String) -> Any? { values[defaultName] }
    override func set(_ value: Any?, forKey defaultName: String) { values[defaultName] = value }
    override func set(_ value: Bool, forKey defaultName: String) { values[defaultName] = value }
    override func set(_ value: Int, forKey defaultName: String) { values[defaultName] = value }
    override func set(_ value: Double, forKey defaultName: String) { values[defaultName] = value }
    override func set(_ value: Float, forKey defaultName: String) { values[defaultName] = value }
    override func removeObject(forKey defaultName: String) { values[defaultName] = nil }
    override func string(forKey defaultName: String) -> String? { values[defaultName] as? String }
    override func data(forKey defaultName: String) -> Data? { values[defaultName] as? Data }
    override func array(forKey defaultName: String) -> [Any]? { values[defaultName] as? [Any] }
    override func dictionary(forKey defaultName: String) -> [String: Any]? { values[defaultName] as? [String: Any] }
    override func bool(forKey defaultName: String) -> Bool { (values[defaultName] as? NSNumber)?.boolValue ?? false }
    override func integer(forKey defaultName: String) -> Int {
        if let string = values[defaultName] as? String { return Int(string) ?? 0 }
        return (values[defaultName] as? NSNumber)?.intValue ?? 0
    }
    override func double(forKey defaultName: String) -> Double {
        if let string = values[defaultName] as? String { return Double(string) ?? 0 }
        return (values[defaultName] as? NSNumber)?.doubleValue ?? 0
    }
    override func float(forKey defaultName: String) -> Float { Float(double(forKey: defaultName)) }
}

