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
}

