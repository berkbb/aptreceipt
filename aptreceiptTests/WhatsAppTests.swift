import CryptoKit
import PDFKit
import SwiftUI
import Vision
import XCTest
@testable import aptreceipt

/// WhatsApp and email messages and links.
final class WhatsAppTests: XCTestCase {
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
        XCTAssertTrue(full.contains("• Muhatap: Daire 5 - Test Resident"), full)
        XCTAssertTrue(full.contains("• Açıklama: Ekim aidatı"), full)

        let plain = WhatsAppShareHelper.receiptSummary(draft: sampleDraft(notes: "  ", lateFee: false, showFlat: false), buildingName: "", l10n: tr)
        XCTAssertFalse(plain.contains("Açıklama"), plain)
        XCTAssertFalse(plain.contains("Gecikme"), plain)
        XCTAssertTrue(plain.contains("• Muhatap: Test Resident"), plain)
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
        XCTAssertTrue(tr.contains("2.000,00") && tr.contains("2.100,00") && tr.contains("yüzde 5"), tr)
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
        XCTAssertTrue(en.contains("(5 percent: $100.00)"), en)
        XCTAssertFalse(en.contains("%"), en)
    }
}
