import Cocoa
import SwiftUI

/// `--generate-screenshots` renders the README screenshots from sample data. For that run the shared
/// settings, receipt archive and verification keys live in memory only, so the user's real settings and receipts are never
/// read into the images or overwritten.
enum ScreenshotMode {
    static let argument = "--generate-screenshots"
    static let isActive = CommandLine.arguments.contains(argument)

    /// Backing store for the shared settings: the user's defaults, or memory only during a screenshot run.
    static func settingsDefaults(screenshotRun: Bool = isActive) -> UserDefaults {
        screenshotRun ? InMemoryDefaults() : .standard
    }

    /// File for the shared archive: the user's archive, or `nil` (memory only) during a screenshot run.
    static func archiveFileURL(screenshotRun: Bool = isActive) -> URL? {
        screenshotRun ? nil : ReceiptArchiveStore.defaultFileURL
    }

    /// File for the receipt verification keys: the user's keys, or `nil` (memory only) during a screenshot run.
    static func verificationKeyFileURL(screenshotRun: Bool = isActive) -> URL? {
        screenshotRun ? nil : ReceiptVerificationKeyStore.defaultFileURL
    }
}

// MARK: - Screenshot Generator

extension AppDelegate {
    @MainActor
    func generateScreenshots() {
        let currentDir = FileManager.default.currentDirectoryPath
        let outDir = URL(fileURLWithPath: currentDir).appendingPathComponent("docs/screenshots")
        try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

        // Sample data only: every store used here is in memory, so the user's settings and receipts stay untouched.
        guard ReceiptArchiveStore.shared.fileURL == nil else {
            print("Screenshots not generated: the receipt archive is not in memory.")
            return
        }

        let settings = ReceiptSettingsStore(defaults: InMemoryDefaults())
        settings.loadSampleDefaults(for: .english)
        settings.language = .english
        settings.currency = .usDollar
        settings.theme = .dark
        settings.seqNumber = 104
        settings.isLateFeeEnabled = true
        settings.lateFeeMonthlyRate = 5.0
        settings.lateFeeDueDay = 15

        let sampleDraft = ReceiptDraft(
            receiver: "Jane Smith",
            issuer: "John Doe",
            notes: "October 2026 monthly dues and elevator maintenance share",
            monthYear: "October 2026",
            apartmentNumber: 4,
            amount: 1750.0,
            sequenceNumber: 104,
            createdDate: "19 October 2026",
            showApartmentNumber: true,
            kind: .income,
            currency: .usDollar,
            isLateFeeApplied: true,
            lateFeeRate: 5.0,
            lateMonths: 2,
            lateFeeAmount: 175.0,
            baseAmount: 1575.0
        )

        let sampleOutcomeDraft = ReceiptDraft(
            receiver: "Apex Elevator Services Inc.",
            issuer: "John Doe",
            notes: "October 2026 periodic elevator maintenance and safety inspection",
            monthYear: "October 2026",
            apartmentNumber: 0,
            amount: 3450.0,
            sequenceNumber: 105,
            createdDate: "19 October 2026",
            showApartmentNumber: false,
            kind: .managementExpense,
            currency: .usDollar
        )

        // The sample receipts are in the archive for every screenshot (badge, archive sheet, report, bulletin).
        let sampleArchiveStore = ReceiptArchiveStore.shared
        sampleArchiveStore.replaceRecords([])
        sampleArchiveStore.add(draft: sampleDraft)
        sampleArchiveStore.add(draft: sampleOutcomeDraft)

        // 1. Main Dashboard (Dark English)
        let mainView = MainScreen(settings: settings)
            .frame(width: 1080, height: 740)
        render(view: mainView, size: CGSize(width: 1080, height: 740), to: outDir.appendingPathComponent("01_main_dashboard.png"), isDark: true)

        // 2. Receipt Certificate View (English)
        let docView = ReceiptDocumentView(
            draft: sampleDraft,
            apartmentName: "Sunshine Residence",
            signatureImage: nil,
            l10n: settings.l10n
        )
        .frame(width: 595, height: 842)
        render(view: docView, size: CGSize(width: 595, height: 842), to: outDir.appendingPathComponent("02_receipt_document.png"), isDark: true)
        renderPDF(view: docView.environment(\.colorScheme, .light), size: CGSize(width: 595, height: 842), to: outDir.appendingPathComponent("02_receipt_document.pdf"))

        // 3. Settings View (Hero Building & KMK Late Fee Settings - Dark English)
        let settingsView = SettingsView(settings: settings, initialTab: .general)
        render(view: settingsView, size: CGSize(width: SettingsTab.general.preferredWidth, height: SettingsTab.preferredHeight), to: outDir.appendingPathComponent("03_settings_view.png"), isDark: true)

        // 4. Management Expense Receipt Document (English)
        let docOutcomeView = ReceiptDocumentView(
            draft: sampleOutcomeDraft,
            apartmentName: "Sunshine Residence",
            signatureImage: nil,
            l10n: settings.l10n
        )
        .frame(width: 595, height: 842)
        render(view: docOutcomeView, size: CGSize(width: 595, height: 842), to: outDir.appendingPathComponent("04_receipt_outcome.png"), isDark: true)

        // 5. English Main Dashboard (Dark English)
        let mainViewEN = MainScreen(settings: settings)
            .frame(width: 1080, height: 740)
        render(view: mainViewEN, size: CGSize(width: 1080, height: 740), to: outDir.appendingPathComponent("05_main_dashboard_en.png"), isDark: true)

        // 6. Romanian Main Dashboard (Dark Romanian)
        let settingsRO = ReceiptSettingsStore(defaults: InMemoryDefaults())
        settingsRO.loadSampleDefaults(for: .romanian)
        settingsRO.language = .romanian
        settingsRO.currency = .romanianLeu
        settingsRO.theme = .dark
        settingsRO.seqNumber = settings.seqNumber
        settingsRO.isLateFeeEnabled = settings.isLateFeeEnabled
        settingsRO.lateFeeMonthlyRate = settings.lateFeeMonthlyRate
        settingsRO.lateFeeDueDay = settings.lateFeeDueDay

        let mainViewRO = MainScreen(settings: settingsRO)
            .frame(width: 1080, height: 740)
        render(view: mainViewRO, size: CGSize(width: 1080, height: 740), to: outDir.appendingPathComponent("06_main_dashboard_ro.png"), isDark: true)

        // Reload English defaults for all subsequent screenshots
        settings.loadSampleDefaults(for: .english)

        // 7. About Window (Dark English)
        let aboutView = AboutWindowView(settings: settings)
            .frame(width: 500, height: 480)
        render(view: aboutView, size: CGSize(width: 500, height: 480), to: outDir.appendingPathComponent("07_about_window.png"), isDark: true)

        // 8. Management Expense Dashboard (Dark English)
        let mgtDashboardView = MainScreen(
            settings: settings,
            initialKind: .managementExpense,
            initialVendor: "Apex Elevator Services Inc.",
            initialNotes: "October 2026 periodic elevator maintenance and safety inspection"
        )
        .frame(width: 1080, height: 740)
        render(view: mgtDashboardView, size: CGSize(width: 1080, height: 740), to: outDir.appendingPathComponent("08_management_expense_dashboard.png"), isDark: true)

        // 9. Settings Vendors & Services Tab (Dark English)
        let vendorsSettingsView = SettingsView(settings: settings, initialTab: .vendors)
        render(view: vendorsSettingsView, size: CGSize(width: SettingsTab.vendors.preferredWidth, height: SettingsTab.preferredHeight), to: outDir.appendingPathComponent("09_settings_vendors.png"), isDark: true)

        // 10. Settings Appearance & Language Hero Deck (Dark English)
        let appearanceSettingsView = SettingsView(settings: settings, initialTab: .appearance)
        render(view: appearanceSettingsView, size: CGSize(width: SettingsTab.appearance.preferredWidth, height: SettingsTab.preferredHeight), to: outDir.appendingPathComponent("10_settings_appearance.png"), isDark: true)

        // 11. Receipt Archive Sheet (Dark English)
        let archiveView = ReceiptArchiveSheet(settings: settings, onSelectDraft: { _ in })
            .frame(width: 860, height: 640)
        render(view: archiveView, size: CGSize(width: 860, height: 640), to: outDir.appendingPathComponent("11_receipt_archive.png"), isDark: true)

        // 12. Financial Report Sheet (KPI cards, dues tracking, transactions - Dark English)
        let financialReportView = ApartmentFinancialReportSheet(settings: settings)
            .frame(width: 880, height: 660)
        render(view: financialReportView, size: CGSize(width: 880, height: 660), to: outDir.appendingPathComponent("12_financial_report.png"), isDark: true)

        // 13. Batch Dues Generator Sheet (Dark English)
        let batchDuesView = BatchDuesGeneratorSheet(settings: settings, onComplete: {})
            .frame(width: 720, height: 600)
        render(view: batchDuesView, size: CGSize(width: 720, height: 600), to: outDir.appendingPathComponent("13_batch_dues.png"), isDark: true)

        // 14. Printable A4 Apartment Bulletin Board Notice (English)
        let bulletinBoardView = ApartmentBulletinBoardView(
            settings: settings,
            periodTitle: "October 2026",
            totalIncome: 17500.0,
            totalExpenses: 3450.0,
            netBalance: 14050.0,
            expenseCategories: [("Elevator Maintenance", 3450.0, 100.0)],
            paidFlatsCount: 10,
            totalFlatsCount: 12,
            records: sampleArchiveStore.records,
            l10n: settings.l10n
        )
        .frame(width: 595, height: 842)
        .environment(\.colorScheme, .light)
        render(view: bulletinBoardView, size: CGSize(width: 595, height: 842), to: outDir.appendingPathComponent("14_bulletin_board_notice.png"), isDark: false)

        // 15. Verify Receipt window with the sample receipt's QR text (Dark English)
        let sampleQRText = ReceiptDocumentView(draft: sampleDraft, apartmentName: "Sunshine Residence", signatureImage: nil, l10n: settings.l10n).qrContent
        let verifyView = ReceiptVerificationView(settings: settings, initialText: sampleQRText)
        render(view: verifyView, size: ReceiptVerificationView.size, to: outDir.appendingPathComponent("15_verify_receipt.png"), isDark: true)

        print("Screenshots successfully generated in \(outDir.path)")
    }

    @MainActor
    private func render<V: View>(view: V, size: CGSize, to fileURL: URL, isDark: Bool = true) {
        let hosting = NSHostingView(rootView: view.preferredColorScheme(isDark ? .dark : .light))
        hosting.appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)
        hosting.frame = CGRect(origin: .zero, size: size)
        hosting.layoutSubtreeIfNeeded()
        guard let rep = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds) else { return }
        hosting.cacheDisplay(in: hosting.bounds, to: rep)
        guard let pngData = rep.representation(using: .png, properties: [:]) else { return }
        try? pngData.write(to: fileURL)
    }

    @MainActor
    private func renderPDF<V: View>(view: V, size: CGSize, to fileURL: URL) {
        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = ProposedViewSize(size)
        var box = CGRect(origin: .zero, size: size)
        guard let consumer = CGDataConsumer(url: fileURL as CFURL),
              let pdfContext = CGContext(consumer: consumer, mediaBox: &box, nil) else {
            return
        }
        pdfContext.beginPDFPage(nil)
        renderer.render { size, context in
            context(pdfContext)
        }
        pdfContext.endPDFPage()
        pdfContext.closePDF()
    }
}
