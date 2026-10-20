import CryptoKit
import PDFKit
import SwiftUI
import Vision
import XCTest
@testable import aptreceipt

/// Decimal money arithmetic and the due day and grace period of the late fee.
final class MoneyAndLateFeeTests: XCTestCase {
    // MARK: - 21. Decimal Money (half a cent always rounds up)

    func testMoneyRoundsHalfUpToCentsAtDecimalValues() {
        // Each of these is just below the half in binary floating point; the old Double rounding went down.
        XCTAssertEqual(Money.roundedToCents(1.005), 1.01)
        XCTAssertEqual(Money.roundedToCents(2.675), 2.68)
        XCTAssertEqual(Money.roundedToCents(1.115), 1.12)
        XCTAssertEqual(Money.roundedToCents(0.125), 0.13)
        XCTAssertEqual(Money.roundedToCents(1.004), 1.0)
        XCTAssertEqual(Money.roundedToCents(1750), 1750)
        XCTAssertEqual(Money.cents(1.005), 101)
        XCTAssertEqual(Money.cents(12750.5), 1_275_050)
        XCTAssertEqual(Money.difference(12750.5, 750.5), 12000)
        XCTAssertEqual(Money.difference(100, 175.005), 0)
    }

    func testLateFeeIsCalculatedInDecimal() {
        XCTAssertEqual(LateFeeCalculator.fee(base: 2.01, monthlyRate: 50, months: 1), 1.01, "2.01 × 50 % = 1.005 rounds up")
        XCTAssertEqual(LateFeeCalculator.fee(base: 1750, monthlyRate: 5, months: 3), 262.5)
        XCTAssertEqual(LateFeeCalculator.fee(base: 1234.56, monthlyRate: 6, months: 7), 518.52)
        XCTAssertEqual(LateFeeCalculator.fee(base: 0.1, monthlyRate: 5, months: 1), 0.01, "0.005 rounds up")
        XCTAssertEqual(LateFeeCalculator.grandTotal(base: 0.1, lateFee: 0.2), 0.3)
        XCTAssertEqual(LateFeeCalculator.grandTotal(base: 1750, lateFee: 262.5), 2012.5)
    }

    func testMoneySumsHaveNoFloatingPointDrift() {
        XCTAssertEqual(Money.sum([0.1, 0.2]), 0.3)
        XCTAssertEqual(Money.sum(Array(repeating: 0.1, count: 10)), 1.0)
        XCTAssertEqual(Money.sum(Array(repeating: 0.01, count: 1000)), 10.0)
        XCTAssertEqual(Money.sum([1750.25, 3450.10, 120.65]), 5321.0)
        XCTAssertEqual(Money.sum([Double]()), 0)
        XCTAssertEqual(NumberToWords.convert(2.675, language: .english, currency: .usDollar), NumberToWords.convert(2.68, language: .english, currency: .usDollar))
    }

    // MARK: - 22. Due Day and Grace Period (every started month after the grace end counts)

    private func day(_ year: Int, _ month: Int, _ day: Int, calendar: Calendar = .current) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 14))!
    }

    func testLateMonthsCountEveryStartedMonthAfterTheDueDay() throws {
        let schedule = try XCTUnwrap(LatePaymentSchedule(year: 2026, month: 10, dueDay: 15, graceDays: 0))
        XCTAssertEqual(schedule.dueDate, Calendar.current.startOfDay(for: day(2026, 10, 15)))
        XCTAssertFalse(schedule.hasGracePeriod)
        XCTAssertEqual(schedule.lateMonths(paidOn: day(2026, 10, 1)), 0, "before the due day")
        XCTAssertEqual(schedule.lateMonths(paidOn: day(2026, 10, 15)), 0, "on the due day")
        XCTAssertEqual(schedule.lateMonths(paidOn: day(2026, 10, 16)), 1)
        XCTAssertEqual(schedule.lateMonths(paidOn: day(2026, 11, 3)), 1)
        XCTAssertEqual(schedule.lateMonths(paidOn: day(2026, 11, 15)), 1)
        XCTAssertEqual(schedule.lateMonths(paidOn: day(2026, 11, 16)), 2)
        XCTAssertEqual(schedule.lateMonths(paidOn: day(2027, 10, 16)), 13)
    }

    func testDueDayIsClampedToTheMonthAndGraceCrossesMonths() throws {
        let november = try XCTUnwrap(LatePaymentSchedule(year: 2026, month: 11, dueDay: 31, graceDays: 0))
        XCTAssertEqual(november.dueDate, Calendar.current.startOfDay(for: day(2026, 11, 30)))
        let leapFebruary = try XCTUnwrap(LatePaymentSchedule(year: 2028, month: 2, dueDay: 30, graceDays: 0))
        XCTAssertEqual(leapFebruary.dueDate, Calendar.current.startOfDay(for: day(2028, 2, 29)))
        let february = try XCTUnwrap(LatePaymentSchedule(year: 2027, month: 2, dueDay: 30, graceDays: 0))
        XCTAssertEqual(february.dueDate, Calendar.current.startOfDay(for: day(2027, 2, 28)))

        let romania = try XCTUnwrap(LatePaymentSchedule(year: 2026, month: 10, dueDay: 20, graceDays: 30))
        XCTAssertTrue(romania.hasGracePeriod)
        XCTAssertEqual(romania.graceEnd, Calendar.current.startOfDay(for: day(2026, 11, 19)))
        XCTAssertEqual(romania.lateMonths(paidOn: day(2026, 11, 19)), 0)
        XCTAssertEqual(romania.lateMonths(paidOn: day(2026, 11, 20)), 1)
        XCTAssertEqual(romania.lateMonths(paidOn: day(2026, 12, 19)), 1)
        XCTAssertEqual(romania.lateMonths(paidOn: day(2026, 12, 20)), 2)
    }

    func testCountryProfileDefaultsGiveTheirGraceEnd() throws {
        let expected: [LateFeeCountryProfile: (Int, Int)] = [.turkey: (10, 15), .romania: (11, 19), .international: (10, 20), .custom: (10, 15)]
        for profile in LateFeeCountryProfile.allCases {
            let schedule = try XCTUnwrap(LatePaymentSchedule(year: 2026, month: 10, dueDay: profile.defaultDueDay, graceDays: profile.defaultGraceDays))
            let end = try XCTUnwrap(expected[profile])
            XCTAssertEqual(schedule.graceEnd, Calendar.current.startOfDay(for: day(2026, end.0, end.1)), "\(profile)")
        }
    }

    @MainActor
    func testAutoDetectUsesDueDayAndGraceAndTurnsTheFeeOffWhenOnTime() {
        let settings = ReceiptSettingsStore(defaults: InMemoryDefaults())
        settings.lateFeeDueDay = 15
        settings.lateFeeGracePeriodDays = 0
        let viewModel = MainScreenViewModel()
        viewModel.receiptDate = day(2026, 10, 3)

        viewModel.autoDetectOverdueMonths(settings: settings, today: day(2026, 11, 16))
        XCTAssertTrue(viewModel.isLateFeeApplied)
        XCTAssertEqual(viewModel.lateMonths, 2)

        viewModel.autoDetectOverdueMonths(settings: settings, today: day(2029, 1, 16))
        XCTAssertEqual(viewModel.lateMonths, 28, "more than the old 24-month list")

        viewModel.autoDetectOverdueMonths(settings: settings, today: day(2026, 10, 14))
        XCTAssertFalse(viewModel.isLateFeeApplied)
        XCTAssertEqual(viewModel.lateMonths, 1)

        settings.lateFeeGracePeriodDays = 10
        viewModel.autoDetectOverdueMonths(settings: settings, today: day(2026, 10, 25))
        XCTAssertFalse(viewModel.isLateFeeApplied, "still inside the grace period")
    }

    func testPaymentReminderChargesTheLateMonths() {
        let l10n = L10n(.english)
        let reminder = WhatsAppShareHelper.paymentReminder(flat: 4, owner: "Jane", period: "October 2026", dues: 1000, currency: .usDollar, lateFeeRate: 5, lateMonths: 3, buildingName: "Sunshine", manager: "John", l10n: l10n)
        XCTAssertTrue(reminder.contains("$150.00"), reminder)
        XCTAssertTrue(reminder.contains("$1,150.00"), reminder)
        let onTime = WhatsAppShareHelper.paymentReminder(flat: 4, owner: "Jane", period: "October 2026", dues: 1000, currency: .usDollar, lateFeeRate: 5, lateMonths: 0, buildingName: "Sunshine", manager: "John", l10n: l10n)
        XCTAssertFalse(onTime.contains("late fee"), onTime)
    }

    func testDueInfoTextsExistInEveryLanguage() {
        for language in [AppLanguage.turkish, .english, .romanian] {
            let l10n = L10n(language)
            XCTAssertTrue(l10n.lateFeeDueInfo(due: "D1", graceEnd: nil).contains("D1"), "\(language)")
            let both = l10n.lateFeeDueInfo(due: "D1", graceEnd: "D2")
            XCTAssertTrue(both.contains("D1") && both.contains("D2"), "\(language)")
            XCTAssertTrue(l10n.lateFeeStatusLate(months: 2).contains("2"), "\(language)")
            XCTAssertFalse(l10n.lateFeeStatusOnTime.isEmpty, "\(language)")
        }
    }
}
