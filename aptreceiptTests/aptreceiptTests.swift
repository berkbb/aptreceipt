//
//  aptreceiptTests.swift
//  aptreceiptTests
//
//  Created by berkbb on 16.03.2022.
//  Copyright © 2023-2026 Babadogan Tech and Edu. All rights reserved.
//

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

    func testKMKLateFeeMathematicalCalculation() {
        // KMK Art. 20/c calculation: Base * (Rate / 100) * Months
        let baseDues: Double = 2000.0
        let monthlyRate: Double = 5.0 // Statutory 5%
        let overdueMonths: Int = 3

        let calculatedLateFee = baseDues * (monthlyRate / 100.0) * Double(overdueMonths)
        let total = baseDues + calculatedLateFee

        XCTAssertEqual(calculatedLateFee, 300.0, accuracy: 0.001)
        XCTAssertEqual(total, 2300.0, accuracy: 0.001)

        // Custom rate test: %7.5 over 2 months
        let customRate: Double = 7.5
        let customLateFee = baseDues * (customRate / 100.0) * 2.0
        XCTAssertEqual(customLateFee, 300.0, accuracy: 0.001)
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

