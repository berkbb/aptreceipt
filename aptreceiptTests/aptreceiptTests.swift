//
//  aptreceiptTests.swift
//  aptreceiptTests
//
//  Created by berkbb on 16.03.2022.
//  Copyright © 2023-2026 Babadogan Tech and Edu. All rights reserved.
//

import CryptoKit
import PDFKit
import SwiftUI
import Vision
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
        XCTAssertEqual(L10n(.english).lateFeeItemName(rate: 5, months: 3), "Late Fee (5.0% × 3 Months)")
        XCTAssertEqual(L10n(.english).lateFeeItemName(rate: 5, months: 1), "Late Fee (5.0% × 1 Month)")
        XCTAssertEqual(L10n(.turkish).lateFeeItemName(rate: 2.5, months: 2), "Gecikme Tazminatı (%2,5 × 2 Ay)")
        XCTAssertEqual(L10n(.romanian).lateFeeItemName(rate: 5, months: 1), "Penalități Întârziere (5,0% × 1 Lună)")
        XCTAssertEqual(L10n(.romanian).lateFeeItemName(rate: 0.25, months: 2), "Penalități Întârziere (0,25% × 2 Luni)")
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

    func testEverySettingsTabUsesTheWidestWidth() {
        for tab in SettingsTab.allCases {
            XCTAssertEqual(tab.preferredWidth, 760, tab.rawValue)
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
    func testLanguageSelectionOnSampleBuildingStoresSamplesButNotOtherDraftEdits() {
        let store = makeIsolatedStore()
        let draft = SettingsViewModel()
        draft.load(from: store)
        draft.loadSampleDefaults(for: .english)
        draft.sequenceNumber = "9"
        let originalSequence = store.seqNumber

        draft.selectLanguage(.romanian, settings: store)

        let samples = SampleData.defaults(for: .romanian)
        XCTAssertEqual(store.language, .romanian)
        XCTAssertEqual(store.currency, AppCurrency.default(for: .romanian))
        XCTAssertEqual(draft.currency, AppCurrency.default(for: .romanian))
        XCTAssertEqual(store.apartmentName, samples.apartmentName)
        XCTAssertEqual(store.issuer, samples.issuer)
        XCTAssertEqual(store.flatCount, samples.flatCount)
        XCTAssertEqual(store.vendors.map(\.name), samples.defaultVendors.map(\.name))
        for (flat, name) in samples.residents {
            XCTAssertEqual(store.owner(for: flat), name.localizedCapitalized)
        }
        // A receipt number typed on another tab stays a pending draft edit.
        XCTAssertEqual(store.seqNumber, originalSequence)
        XCTAssertEqual(draft.sequenceNumber, "9")
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

    // MARK: - 10. Settings Quirk Fixes

    func testStatutoryRateLabelHasNoRateInsideItInEveryLanguage() {
        for language in [AppLanguage.english, .turkish, .romanian] {
            let label = L10n(language).statutoryRateLabel
            XCTAssertFalse(label.isEmpty)
            XCTAssertFalse(label.contains("%"), "\(language): \(label)")
            XCTAssertFalse(label.contains(where: \.isNumber), "\(language): \(label)")
        }
        XCTAssertNotEqual(L10n(.turkish).clearResidentButton, L10n(.turkish).clearAllResidentsButton)
    }

    @MainActor
    func testSwitchingSettingsTabsKeepsWindowSizeAndPosition() async throws {
        let store = makeIsolatedStore()
        SettingsWindowManager.shared.show(settings: store, tab: .general)
        defer { SettingsWindowManager.shared.close() }
        let window = try XCTUnwrap(NSApp.windows.first { $0.contentViewController is SettingsTabViewController })
        let controller = try XCTUnwrap(window.contentViewController as? SettingsTabViewController)
        try await Task.sleep(for: .milliseconds(400))
        let topLeft = NSPoint(x: window.frame.minX, y: window.frame.maxY)

        for tab in [SettingsTab.residents, .vendors, .appearance, .residents, .general, .about] {
            controller.selectedTabViewItemIndex = SettingsTab.allCases.firstIndex(of: tab)!
            try await Task.sleep(for: .milliseconds(600))
            // The top-left corner never moves (it used to drift 100 pt per switch).
            XCTAssertEqual(window.frame.minX, topLeft.x, accuracy: 0.5, tab.rawValue)
            XCTAssertEqual(window.frame.maxY, topLeft.y, accuracy: 0.5, tab.rawValue)
            // One width for every tab, so nothing is clipped and the window never resizes.
            XCTAssertEqual(window.contentLayoutRect.width, SettingsTab.preferredWidth, accuracy: 0.5, tab.rawValue)
        }
    }

    // MARK: - 11. WhatsApp Messages

    private func sampleDraft(notes: String = "Ekim aidatı", lateFee: Bool = true, showFlat: Bool = true) -> ReceiptDraft {
        ReceiptDraft(
            receiver: "Test Resident",
            issuer: "Test Manager",
            notes: notes,
            monthYear: "Ekim 2026",
            apartmentNumber: 5,
            amount: lateFee ? 2300.0 : 2000.0,
            sequenceNumber: 105,
            createdDate: "19.10.2026",
            showApartmentNumber: showFlat,
            kind: .income,
            currency: .turkishLira,
            isLateFeeApplied: lateFee,
            lateFeeRate: 5.0,
            lateMonths: 3,
            lateFeeAmount: lateFee ? 300.0 : 0,
            baseAmount: 2000.0
        )
    }

    func testWhatsAppNumberBecomesInternational() {
        // Local Turkish and Romanian numbers get their calling code; the trunk 0 is dropped.
        XCTAssertEqual(WhatsAppShareHelper.whatsAppNumber("0532 000 00 00", callingCode: "90"), "905320000000")
        XCTAssertEqual(WhatsAppShareHelper.whatsAppNumber("532 000 00 00", callingCode: "90"), "905320000000")
        XCTAssertEqual(WhatsAppShareHelper.whatsAppNumber("0722 000 000", callingCode: "40"), "40722000000")
        // Numbers that are already international stay as they are.
        XCTAssertEqual(WhatsAppShareHelper.whatsAppNumber("+90 532 000 00 00", callingCode: "90"), "905320000000")
        XCTAssertEqual(WhatsAppShareHelper.whatsAppNumber("0090 532 000 00 00", callingCode: "90"), "905320000000")
        XCTAssertEqual(WhatsAppShareHelper.whatsAppNumber("90 532 000 00 00", callingCode: "90"), "905320000000")
        XCTAssertEqual(WhatsAppShareHelper.whatsAppNumber("+1 (555) 000-0000", callingCode: "90"), "15550000000")
        // Without a known country the digits are passed through, as before.
        XCTAssertEqual(WhatsAppShareHelper.whatsAppNumber("+1 (555) 000-0000", callingCode: nil), "15550000000")
        XCTAssertEqual(WhatsAppShareHelper.whatsAppNumber("", callingCode: "90"), "")
        XCTAssertEqual(WhatsAppShareHelper.whatsAppNumber(nil, callingCode: "90"), "")
        XCTAssertEqual(WhatsAppShareHelper.defaultCallingCode(for: .turkishLira), "90")
        XCTAssertEqual(WhatsAppShareHelper.defaultCallingCode(for: .romanianLeu), "40")
        XCTAssertNil(WhatsAppShareHelper.defaultCallingCode(for: .euro))
    }

    func testWhatsAppURLKeepsTheWholeMessage() throws {
        let message = "A & B Apartmanı\nAidat + gecikme = toplam? #105"
        let url = try XCTUnwrap(WhatsAppShareHelper.shareURL(phone: "0532 000 00 00", message: message, callingCode: "90"))
        XCTAssertTrue(url.absoluteString.hasPrefix("https://wa.me/905320000000?text="))
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        // The decoded text must be the full message: `&` must not end the parameter, `+` must not become a space.
        XCTAssertEqual(components.queryItems?.count, 1)
        XCTAssertEqual(components.queryItems?.first?.value, message)
    }

    func testEmailBodyHasNoWhatsAppAsterisks() throws {
        let url = try XCTUnwrap(WhatsAppShareHelper.emailURL(subject: "A & B", body: "Sayın *Test*,\nTutar"))
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let items = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        XCTAssertEqual(items["subject"], "A & B")
        XCTAssertEqual(items["body"], "Sayın Test,\nTutar")
    }

    func testReceiptSummaryFormatsAmountsAndSkipsEmptyLines() {
        let tr = L10n(.turkish)
        let full = WhatsAppShareHelper.receiptSummary(draft: sampleDraft(), buildingName: "Test Apt", l10n: tr)
        XCTAssertTrue(full.contains("2.300,00"), full)
        XCTAssertFalse(full.contains("2300.00"), full)
        XCTAssertTrue(full.contains("Aidat: ") && full.contains("2.000,00"), full)
        XCTAssertTrue(full.contains("Gecikme tazminatı: ") && full.contains("300,00"), full)
        XCTAssertTrue(full.contains("📍 Muhatap: Daire 5 - Test Resident"), full)
        XCTAssertTrue(full.contains("📝 Açıklama: Ekim aidatı"), full)

        let plain = WhatsAppShareHelper.receiptSummary(draft: sampleDraft(notes: "  ", lateFee: false, showFlat: false), buildingName: "", l10n: tr)
        XCTAssertFalse(plain.contains("📝"), plain)
        XCTAssertFalse(plain.contains("Gecikme"), plain)
        XCTAssertTrue(plain.contains("📍 Muhatap: Test Resident"), plain)
        XCTAssertTrue(plain.contains("*\(tr.defaultBuildingName)*"), plain)

        let en = WhatsAppShareHelper.receiptSummary(draft: sampleDraft(), buildingName: "Test Apt", l10n: L10n(.english))
        XCTAssertTrue(en.contains("Late fee: "), en)
        XCTAssertTrue(en.contains("2,300.00"), en)
    }

    func testPaymentReminderUsesOwnerNameAndFormattedAmounts() {
        let tr = WhatsAppShareHelper.paymentReminder(
            flat: 3, owner: "Test Owner", period: "Ekim 2026", dues: 2000, currency: .turkishLira,
            lateFeeRate: 5, buildingName: "Test Apt", manager: "Test Manager", l10n: L10n(.turkish)
        )
        XCTAssertTrue(tr.hasPrefix("Sayın *Test Owner* (Daire 3),"), tr)
        XCTAssertTrue(tr.contains("2.000,00") && tr.contains("2.100,00") && tr.contains("%5,0"), tr)
        XCTAssertTrue(tr.hasSuffix("- Test Manager"), tr)

        let anonymous = WhatsAppShareHelper.paymentReminder(
            flat: 3, owner: " ", period: "Ekim 2026", dues: 2000, currency: .turkishLira,
            lateFeeRate: nil, buildingName: "Test Apt", manager: "Test Manager", l10n: L10n(.turkish)
        )
        XCTAssertTrue(anonymous.hasPrefix("Sayın Komşumuz (Daire 3),"), anonymous)
        XCTAssertFalse(anonymous.contains("gecikme"), anonymous)

        let en = WhatsAppShareHelper.paymentReminder(
            flat: 3, owner: "", period: "October 2026", dues: 2000, currency: .usDollar,
            lateFeeRate: 5, buildingName: "Test Apt", manager: "Test Manager", l10n: L10n(.english)
        )
        XCTAssertTrue(en.contains("5.0%"), en)
        XCTAssertFalse(en.contains("%5"), en)
    }

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

    // MARK: - 15. Screenshot Run Isolation (sample data never reaches the user's settings or receipts)

    private func makeArchiveDraft() -> ReceiptDraft {
        ReceiptDraft(receiver: "R", issuer: "I", notes: "N", monthYear: "Ekim 2026", apartmentNumber: 5, amount: 1, sequenceNumber: 1, createdDate: "1", showApartmentNumber: true, kind: .income)
    }

    private func modificationDate(_ url: URL) -> Date? {
        (try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date
    }

    @MainActor
    func testScreenshotRunKeepsSettingsAndArchiveInMemory() {
        XCTAssertFalse(ScreenshotMode.isActive, "Tests run without \(ScreenshotMode.argument)")
        XCTAssertNil(ScreenshotMode.archiveFileURL(screenshotRun: true))
        XCTAssertEqual(ScreenshotMode.archiveFileURL(screenshotRun: false), ReceiptArchiveStore.defaultFileURL)
        XCTAssertTrue(ScreenshotMode.settingsDefaults(screenshotRun: true) is InMemoryDefaults)
        XCTAssertTrue(ScreenshotMode.settingsDefaults(screenshotRun: false) === UserDefaults.standard)
    }

    @MainActor
    func testSampleSettingsOfAScreenshotRunNeverReachTheUserDefaults() {
        let standard = UserDefaults.standard
        let keys = [
            ReceiptSettingsStore.Keys.apartmentName,
            ReceiptSettingsStore.Keys.language,
            ReceiptSettingsStore.Keys.currency,
            ReceiptSettingsStore.Keys.seqNumber,
            ReceiptSettingsStore.Keys.owner(1),
            "AppleLanguages",
        ]
        let before = keys.map { standard.object(forKey: $0) as? NSObject }

        let store = ReceiptSettingsStore(defaults: ScreenshotMode.settingsDefaults(screenshotRun: true))
        store.loadSampleDefaults(for: .romanian)
        store.language = .romanian
        store.currency = .romanianLeu
        store.seqNumber = 104

        XCTAssertEqual(store.apartmentName, SampleData.defaults(for: .romanian).apartmentName)
        XCTAssertEqual(keys.map { standard.object(forKey: $0) as? NSObject }, before)
    }

    @MainActor
    func testInMemoryArchiveWritesNoFile() {
        let realArchive = ReceiptArchiveStore.defaultFileURL
        let realArchiveDate = modificationDate(realArchive)

        let store = ReceiptArchiveStore(fileURL: nil)
        store.add(draft: makeArchiveDraft())
        store.replaceRecords([])
        store.add(draft: makeArchiveDraft())

        XCTAssertEqual(store.records.count, 1)
        XCTAssertTrue(ReceiptArchiveStore(fileURL: nil).records.isEmpty)
        XCTAssertEqual(modificationDate(realArchive), realArchiveDate)
    }

    @MainActor
    func testArchiveStoreSavesAndLoadsOnlyItsOwnFile() {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let fileURL = folder.appendingPathComponent("receipts_archive.json")
        XCTAssertNotEqual(fileURL, ReceiptArchiveStore.defaultFileURL)

        let store = ReceiptArchiveStore(fileURL: fileURL)
        XCTAssertTrue(store.records.isEmpty)
        store.add(draft: makeArchiveDraft())

        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertEqual(ReceiptArchiveStore(fileURL: fileURL).records.map(\.id), store.records.map(\.id))
    }

    // MARK: - 16. Receipt QR Code (must scan in the exported image and PDF)

    private func decodedQRCodes(in image: CGImage) -> [String] {
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]
        try? VNImageRequestHandler(cgImage: image).perform([request])
        return (request.results ?? []).compactMap(\.payloadStringValue)
    }

    /// Renders `view` through the JPEG and PDF export paths and checks that the QR code reads back as `qrText`.
    @MainActor
    private func assertQRCodeScans(_ view: ReceiptDocumentView, _ label: String) throws {
        let expected = view.qrText
        let document = view.frame(width: 595, height: 842).environment(\.colorScheme, .light)

        // JPEG export path: rendered at 2x.
        let imageRenderer = ImageRenderer(content: document)
        imageRenderer.scale = 2
        imageRenderer.proposedSize = ProposedViewSize(width: 595, height: 842)
        let image = try XCTUnwrap(imageRenderer.cgImage)
        XCTAssertEqual(decodedQRCodes(in: image), [expected], "\(label): JPEG export")

        // PDF export path, then viewed or scanned at 150 dpi.
        let pdfRenderer = ImageRenderer(content: document)
        pdfRenderer.proposedSize = ProposedViewSize(width: 595, height: 842)
        let pdfData = NSMutableData()
        var box = CGRect(x: 0, y: 0, width: 595, height: 842)
        let consumer = try XCTUnwrap(CGDataConsumer(data: pdfData as CFMutableData))
        let pdfContext = try XCTUnwrap(CGContext(consumer: consumer, mediaBox: &box, nil))
        pdfContext.beginPDFPage(nil)
        pdfRenderer.render { _, draw in draw(pdfContext) }
        pdfContext.endPDFPage()
        pdfContext.closePDF()
        let pdf = try XCTUnwrap(PDFDocument(data: pdfData as Data))
        let page = try XCTUnwrap(pdf.page(at: 0))
        let thumbnail = page.thumbnail(of: NSSize(width: 1240, height: 1754), for: .mediaBox)
        let scan = try XCTUnwrap(thumbnail.cgImage(forProposedRect: nil, context: nil, hints: nil))
        XCTAssertEqual(decodedQRCodes(in: scan), [expected], "\(label): PDF export")
    }

    @MainActor
    func testReceiptQRCodeScansInExportedImageAndPDF() throws {
        // Worst case: every name over the cap, Turkish two-byte letters, a late fee, large amounts.
        let keys = ReceiptVerificationKeyStore(fileURL: nil)
        let longName = String(repeating: "Şükrü İğdır Öztürkoğlu ", count: 4)
        for language in [AppLanguage.turkish, .english, .romanian] {
            for kind in ReceiptKind.allCases {
                let draft = ReceiptDraft(receiver: longName, issuer: longName, notes: "N", monthYear: "Septembrie 2026", apartmentNumber: 128, amount: 1234567.89, sequenceNumber: 99999, createdDate: "30 septembrie 2026", showApartmentNumber: true, kind: kind, currency: .romanianLeu, isLateFeeApplied: true, lateFeeRate: 12.5, lateMonths: 11, lateFeeAmount: 123456.78, baseAmount: 1111111.11)
                let view = ReceiptDocumentView(draft: draft, apartmentName: longName, signatureImage: nil, l10n: L10n(language), verificationKeys: keys)
                try assertQRCodeScans(view, "\(language) \(kind)")
                let width = try XCTUnwrap(QRCodeGenerator.generate(from: view.qrText, pointsPerModule: 72 / 25.4 * 0.5)?.size.width)
                XCTAssertLessThanOrEqual(width, 130, "\(language) \(kind): QR too wide for the receipt footer")
            }
        }
    }

    @MainActor
    func testQRTextListsTheReceiptInItsLanguageWithAValidCode() throws {
        let keys = ReceiptVerificationKeyStore(fileURL: nil)
        let draft = ReceiptDraft(receiver: "Ayşe Yılmaz", issuer: "Mehmet Şahin", notes: "Ekim 2026 aidatı", monthYear: "Ekim 2026", apartmentNumber: 12, amount: 12750.5, sequenceNumber: 1042, createdDate: "20.10.2026", showApartmentNumber: true, kind: .income, currency: .turkishLira, isLateFeeApplied: true, lateFeeRate: 2.5, lateMonths: 3, lateFeeAmount: 750.5, baseAmount: 12000)
        var lines = ReceiptDocumentView(draft: draft, apartmentName: "Yıldız Sitesi Yönetimi", signatureImage: nil, l10n: L10n(.turkish), verificationKeys: keys).qrText.components(separatedBy: "\n")
        let codeLine = try XCTUnwrap(lines.popLast())
        XCTAssertEqual(lines, [
            "AptReceipt",
            "YILDIZ SİTESİ YÖNETİMİ",
            "Tahsilat Makbuzu · TAH-1042",
            "Düzenleme Tarihi: 20.10.2026",
            "Dönem: Ekim 2026",
            "Sakin / Muhatap: Ayşe Yılmaz",
            "Daire 12",
            "Aidat Ana Para: ₺12.000,00",
            "Gecikme Tazminatı: +₺750,50",
            "GENEL TOPLAM: ₺12.750,50",
            "Yönetici: Mehmet Şahin",
        ])
        let prefix = "Doğrulama kodu: "
        XCTAssertTrue(codeLine.hasPrefix(prefix), codeLine)
        let code = String(codeLine.dropFirst(prefix.count))
        XCTAssertEqual(ReceiptVerificationCode.matchingKeyIndex(code: code, text: lines.joined(separator: "\n"), keys: keys.allKeys), 0)
        XCTAssertNil(ReceiptVerificationCode.matchingKeyIndex(code: code, text: lines.joined(separator: "\n"), keys: ReceiptVerificationKeyStore(fileURL: nil).allKeys))

        // A management expense in English: payee label, no flat or late fee lines.
        let expense = ReceiptDraft(receiver: "Apex Elevator Services", issuer: "John Doe", notes: "N", monthYear: "October 2026", apartmentNumber: 0, amount: 3450, sequenceNumber: 105, createdDate: "19 October 2026", showApartmentNumber: false, kind: .managementExpense, currency: .usDollar)
        let english = ReceiptDocumentView(draft: expense, apartmentName: "Sunshine Residence", signatureImage: nil, l10n: L10n(.english), verificationKeys: keys).qrText.components(separatedBy: "\n")
        XCTAssertEqual(Array(english.dropLast()), [
            "AptReceipt",
            "SUNSHINE RESIDENCE",
            "Operating Expenditure Voucher · MGT-0105",
            "Issue Date: 19 October 2026",
            "Period: October 2026",
            "Payee / Vendor: Apex Elevator Services",
            "GRAND TOTAL: $3,450.00",
            "Manager: John Doe",
        ])
        XCTAssertTrue(english.last?.hasPrefix("Verification code: ") == true)

        // Names over the cap end with an ellipsis.
        let long = ReceiptDraft(receiver: String(repeating: "a", count: 60), issuer: "I", notes: "N", monthYear: "October 2026", apartmentNumber: 1, amount: 1, sequenceNumber: 1, createdDate: "1", showApartmentNumber: false, kind: .income, currency: .usDollar)
        let longLines = ReceiptDocumentView(draft: long, apartmentName: "B", signatureImage: nil, l10n: L10n(.english), verificationKeys: keys).qrText.components(separatedBy: "\n")
        XCTAssertTrue(longLines.contains("Resident / Payer: " + String(repeating: "a", count: ReceiptDocumentView.qrNameLimit - 1) + "…"), "\(longLines)")
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
        XCTAssertEqual(turkish.qrText.components(separatedBy: "\n")[1], "YILDIZ SİTESİ YÖNETİMİ")
        let english = ReceiptDocumentView(draft: draft, apartmentName: "Yıldız Sitesi Yönetimi", signatureImage: nil, l10n: L10n(.english), verificationKeys: keys)
        XCTAssertEqual(english.qrText.components(separatedBy: "\n")[1], "YILDIZ SITESI YÖNETIMI")
    }

    // MARK: - 18. Receipt Verification Codes and Keys (offline QR plan, phase 1)

    private static let codeKey = SymmetricKey(data: Data(repeating: 7, count: 32))
    private static let codeText = "AptReceipt\nYILDIZ SİTESİ YÖNETİMİ\nTahsilat Makbuzu · TAH-1042\nToplam: ₺12.750,50"

    @MainActor private func rawKeys(_ store: ReceiptVerificationKeyStore) -> [Data] { store.exportedKeys() }

    func testVerificationCodeIsPinnedAndIgnoresLayoutOnly() {
        let code = ReceiptVerificationCode.code(for: Self.codeText, key: Self.codeKey)
        // Printed receipts keep their codes forever: this value must never change (computed independently).
        XCTAssertEqual(code, "MYT3-6FAA-81BK-6T3W")

        let relaidOut = "\r\n  " + Self.codeText.decomposedStringWithCanonicalMapping.replacingOccurrences(of: "\n", with: "  \r\n\r\n") + "\n"
        XCTAssertEqual(ReceiptVerificationCode.code(for: relaidOut, key: Self.codeKey), code)

        XCTAssertNotEqual(ReceiptVerificationCode.code(for: Self.codeText.replacingOccurrences(of: "12.750,50", with: "12.750,51"), key: Self.codeKey), code)
        XCTAssertNotEqual(ReceiptVerificationCode.code(for: Self.codeText.replacingOccurrences(of: "TAH-1042", with: "TAH-1043"), key: Self.codeKey), code)
        XCTAssertNotEqual(ReceiptVerificationCode.code(for: Self.codeText, key: SymmetricKey(data: Data(repeating: 8, count: 32))), code)
    }

    func testVerificationCodeAcceptsTypedVariantsAndFindsTheKey() {
        let code = ReceiptVerificationCode.code(for: Self.codeText, key: Self.codeKey)
        let typed = code.replacingOccurrences(of: "-", with: " ").lowercased()
            .replacingOccurrences(of: "0", with: "o").replacingOccurrences(of: "1", with: "l")
        XCTAssertEqual(ReceiptVerificationCode.canonicalCode(typed), code)
        XCTAssertNil(ReceiptVerificationCode.canonicalCode("MYT3-6FAA-81BK"))
        XCTAssertNil(ReceiptVerificationCode.canonicalCode("MYT3-6FAA-81BK-6T3U"))

        let otherKey = SymmetricKey(data: Data(repeating: 9, count: 32))
        XCTAssertEqual(ReceiptVerificationCode.matchingKeyIndex(code: typed, text: Self.codeText, keys: [otherKey, Self.codeKey]), 1)
        XCTAssertNil(ReceiptVerificationCode.matchingKeyIndex(code: code, text: Self.codeText + "\nX", keys: [otherKey, Self.codeKey]))
        XCTAssertNil(ReceiptVerificationCode.matchingKeyIndex(code: code, text: Self.codeText, keys: [otherKey]))
    }

    @MainActor
    func testVerificationKeysStayInMemoryOrInTheirOwnFile() throws {
        XCTAssertNil(ScreenshotMode.verificationKeyFileURL(screenshotRun: true))
        XCTAssertEqual(ScreenshotMode.verificationKeyFileURL(screenshotRun: false), ReceiptVerificationKeyStore.defaultFileURL)

        let memory = ReceiptVerificationKeyStore(fileURL: nil)
        XCTAssertEqual(rawKeys(memory), rawKeys(memory))
        XCTAssertEqual(rawKeys(memory).count, 1)
        XCTAssertNotEqual(rawKeys(ReceiptVerificationKeyStore(fileURL: nil)), rawKeys(memory))

        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let fileURL = folder.appendingPathComponent("receipt-verification-keys")
        XCTAssertNotEqual(fileURL, ReceiptVerificationKeyStore.defaultFileURL)

        let first = ReceiptVerificationKeyStore(fileURL: fileURL)
        let key = try XCTUnwrap(rawKeys(first).first)
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        XCTAssertEqual(attributes[.size] as? Int, 32)
        XCTAssertEqual((attributes[.posixPermissions] as? NSNumber)?.intValue, 0o600)
        XCTAssertEqual(rawKeys(ReceiptVerificationKeyStore(fileURL: fileURL)), [key])

        let restoredKey = Data(repeating: 3, count: 32)
        first.restore([restoredKey, Data(repeating: 1, count: 5)])
        first.restore([restoredKey])
        XCTAssertEqual(rawKeys(first), [restoredKey, key])
        XCTAssertEqual(rawKeys(ReceiptVerificationKeyStore(fileURL: fileURL)), [restoredKey, key])

        // An unreadable file is moved aside, never overwritten.
        try Data([1, 2, 3, 4, 5]).write(to: fileURL)
        XCTAssertEqual(rawKeys(ReceiptVerificationKeyStore(fileURL: fileURL)).count, 1)
        let leftovers = try FileManager.default.contentsOfDirectory(atPath: folder.path)
        XCTAssertTrue(leftovers.contains { $0.hasPrefix("receipt-verification-keys.unreadable-") }, "\(leftovers)")
    }

    @MainActor
    func testSystemBackupCarriesTheVerificationKeys() throws {
        let sourceKeys = ReceiptVerificationKeyStore(fileURL: nil)
        let source = ReceiptSettingsStore(defaults: InMemoryDefaults())
        let data = try XCTUnwrap(source.exportSystemBackup(archive: ReceiptArchiveStore(fileURL: nil), verificationKeys: sourceKeys))
        let package = try JSONDecoder().decode(SystemBackupPackage.self, from: data)
        XCTAssertEqual(package.version, "2.2")
        XCTAssertEqual(package.receiptVerificationKeys, rawKeys(sourceKeys).map { $0.base64EncodedString() })

        let targetKeys = ReceiptVerificationKeyStore(fileURL: nil)
        let ownKeys = rawKeys(targetKeys)
        try ReceiptSettingsStore(defaults: InMemoryDefaults()).importSystemBackup(from: data, archive: ReceiptArchiveStore(fileURL: nil), verificationKeys: targetKeys)
        XCTAssertEqual(rawKeys(targetKeys), rawKeys(sourceKeys) + ownKeys)

        // A backup from before 3.6 has no keys and leaves them as they are.
        var older = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        older["receiptVerificationKeys"] = nil
        let olderKeys = ReceiptVerificationKeyStore(fileURL: nil)
        let olderOwn = rawKeys(olderKeys)
        try ReceiptSettingsStore(defaults: InMemoryDefaults()).importSystemBackup(from: JSONSerialization.data(withJSONObject: older), archive: ReceiptArchiveStore(fileURL: nil), verificationKeys: olderKeys)
        XCTAssertEqual(rawKeys(olderKeys), olderOwn)
    }

    // MARK: - 19. Verify Receipt (offline QR plan, phase 3)

    private static let verifyDraft = ReceiptDraft(receiver: "Ayşe Yılmaz", issuer: "Mehmet Şahin", notes: "Ekim 2026 aidatı", monthYear: "Ekim 2026", apartmentNumber: 12, amount: 12750.5, sequenceNumber: 1042, createdDate: "20.10.2026", showApartmentNumber: true, kind: .income, currency: .turkishLira, isLateFeeApplied: true, lateFeeRate: 2.5, lateMonths: 3, lateFeeAmount: 750.5, baseAmount: 12000)

    @MainActor
    private func verifyReceiptView(_ draft: ReceiptDraft = verifyDraft, keys: ReceiptVerificationKeyStore) -> ReceiptDocumentView {
        ReceiptDocumentView(draft: draft, apartmentName: "Yıldız Sitesi Yönetimi", signatureImage: nil, l10n: L10n(.turkish), verificationKeys: keys)
    }

    func testReceiptSerialPrefixesRoundTrip() {
        for language in [AppLanguage.turkish, .english, .romanian] {
            for kind in ReceiptKind.allCases {
                let serial = ReceiptSerial.formatted(kind: kind, language: language, sequenceNumber: 42)
                let parsed = ReceiptSerial.parse("Document · \(serial)")
                XCTAssertEqual(parsed?.kind, kind, serial)
                XCTAssertEqual(parsed?.language, language, serial)
                XCTAssertEqual(parsed?.sequenceNumber, 42, serial)
            }
        }
        XCTAssertEqual(ReceiptSerial.formatted(kind: .income, language: .turkish, sequenceNumber: 1042), "TAH-1042")
        XCTAssertNil(ReceiptSerial.parse("No receipt number here"))
    }

    @MainActor
    func testScannedReceiptIsGenuineOnlyWhenUnchangedAndFromThisInstallation() throws {
        let keys = ReceiptVerificationKeyStore(fileURL: nil)
        let text = verifyReceiptView(keys: keys).qrText

        let scan = try XCTUnwrap(ScannedReceiptVerification(scannedText: text.replacingOccurrences(of: "\n", with: "\r\n"), keys: keys.allKeys))
        XCTAssertEqual(scan.status, .genuine(keyIndex: 0))
        XCTAssertEqual(scan.kind, .income)
        XCTAssertEqual(scan.language, .turkish)
        XCTAssertEqual(scan.sequenceNumber, 1042)
        XCTAssertEqual(scan.lines, Array(text.components(separatedBy: "\n").dropLast()))
        XCTAssertEqual(scan.code, String(text.suffix(19)))

        let altered = text.replacingOccurrences(of: "₺12.750,50", with: "₺13.750,50")
        XCTAssertEqual(ScannedReceiptVerification(scannedText: altered, keys: keys.allKeys)?.status, .notVerified)
        XCTAssertEqual(ScannedReceiptVerification(scannedText: text, keys: ReceiptVerificationKeyStore(fileURL: nil).allKeys)?.status, .notVerified)
        let withoutCode = text.components(separatedBy: "\n").dropLast().joined(separator: "\n")
        XCTAssertEqual(ScannedReceiptVerification(scannedText: withoutCode, keys: keys.allKeys)?.status, .notVerified)

        // A receipt made before restoring another Mac's backup is still genuine, with this Mac's older key.
        let restored = ReceiptVerificationKeyStore(fileURL: nil)
        let earlier = verifyReceiptView(keys: restored).qrText
        restored.restore([Data(repeating: 4, count: 32)])
        XCTAssertEqual(ScannedReceiptVerification(scannedText: earlier, keys: restored.allKeys)?.status, .genuine(keyIndex: 1))

        // A name shaped like a code is never read as the code.
        let codeLike = ReceiptDraft(receiver: "Ayşe Yılmaz", issuer: "Abcd Efgh Ijkl Mnop", notes: "N", monthYear: "Ekim 2026", apartmentNumber: 12, amount: 100, sequenceNumber: 1043, createdDate: "20.10.2026", showApartmentNumber: true, kind: .income, currency: .turkishLira)
        let codeLikeLines = verifyReceiptView(codeLike, keys: keys).qrText.components(separatedBy: "\n").dropLast()
        let codeLikeScan = try XCTUnwrap(ScannedReceiptVerification(scannedText: codeLikeLines.joined(separator: "\n"), keys: keys.allKeys))
        XCTAssertNil(codeLikeScan.code)
        XCTAssertEqual(codeLikeScan.lines.last, "Yönetici: Abcd Efgh Ijkl Mnop")
    }

    func testOlderAndForeignQRTextsAreRecognized() throws {
        let older = try XCTUnwrap(ScannedReceiptVerification(scannedText: "AptReceipt | SUNSHINE RESIDENCE | REC-0104 | 19 October 2026 | Jane Smith | $1,750.00 | John Doe", keys: []))
        XCTAssertEqual(older.status, .olderWithoutCode)
        XCTAssertEqual(older.lines, ["SUNSHINE RESIDENCE", "REC-0104", "19 October 2026", "Jane Smith", "$1,750.00", "John Doe"])
        XCTAssertEqual(older.kind, .income)
        XCTAssertEqual(older.language, .english)
        XCTAssertEqual(older.sequenceNumber, 104)
        XCTAssertNil(older.code)

        XCTAssertNil(ScannedReceiptVerification(scannedText: "https://example.com", keys: []))
        XCTAssertNil(ScannedReceiptVerification(scannedText: "AptReceipt", keys: []))
        XCTAssertNil(ReceiptQRReader.receiptText(in: ["hello", "https://example.com"]))
    }

    @MainActor
    func testScannedReceiptIsComparedWithTheArchive() throws {
        let keys = ReceiptVerificationKeyStore(fileURL: nil)
        let scan = try XCTUnwrap(ScannedReceiptVerification(scannedText: verifyReceiptView(keys: keys).qrText, keys: keys.allKeys))
        let record = ReceiptRecord(draft: Self.verifyDraft)
        var changed = record
        changed.amount = 13750.5
        var otherNumber = record
        otherNumber.sequenceNumber = 7

        XCTAssertEqual(ReceiptArchiveComparison.compare(scan, with: [record], apartmentName: "Yıldız Sitesi Yönetimi"), .matches)
        XCTAssertEqual(ReceiptArchiveComparison.compare(scan, with: [changed], apartmentName: "Yıldız Sitesi Yönetimi"), .differs(lines: ["GENEL TOPLAM: ₺12.750,50"]))
        XCTAssertEqual(ReceiptArchiveComparison.compare(scan, with: [changed, record], apartmentName: "Yıldız Sitesi Yönetimi"), .matches)
        XCTAssertEqual(ReceiptArchiveComparison.compare(scan, with: [otherNumber], apartmentName: "Yıldız Sitesi Yönetimi"), .missing)
        XCTAssertEqual(ReceiptArchiveComparison.compare(scan, with: [], apartmentName: "Yıldız Sitesi Yönetimi"), .missing)
        XCTAssertEqual(ReceiptArchiveComparison.compare(scan, with: [record], apartmentName: "Başka Site"), .differs(lines: ["YILDIZ SİTESİ YÖNETİMİ"]))
    }

    @MainActor
    func testQRReaderFindsTheReceiptInAnExportedPDFAndImage() throws {
        let keys = ReceiptVerificationKeyStore(fileURL: nil)
        let view = verifyReceiptView(keys: keys)
        let document = view.frame(width: 595, height: 842).environment(\.colorScheme, .light)
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }

        let pdfURL = folder.appendingPathComponent("receipt.pdf")
        let pdfRenderer = ImageRenderer(content: document)
        pdfRenderer.proposedSize = ProposedViewSize(width: 595, height: 842)
        var box = CGRect(x: 0, y: 0, width: 595, height: 842)
        let pdfContext = try XCTUnwrap(CGContext(consumer: try XCTUnwrap(CGDataConsumer(url: pdfURL as CFURL)), mediaBox: &box, nil))
        pdfContext.beginPDFPage(nil)
        pdfRenderer.render { _, draw in draw(pdfContext) }
        pdfContext.endPDFPage()
        pdfContext.closePDF()
        XCTAssertEqual(ReceiptQRReader.receiptText(in: ReceiptQRReader.texts(in: pdfURL)), view.qrText)

        let pngURL = folder.appendingPathComponent("receipt.png")
        let imageRenderer = ImageRenderer(content: document)
        imageRenderer.scale = 2
        let bitmap = NSBitmapImageRep(cgImage: try XCTUnwrap(imageRenderer.cgImage))
        try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: pngURL)
        XCTAssertEqual(ReceiptQRReader.receiptText(in: ReceiptQRReader.texts(in: pngURL)), view.qrText)
    }
}
