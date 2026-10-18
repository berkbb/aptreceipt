import Cocoa
import SwiftUI

@main
struct AptReceiptApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var settings = ReceiptSettingsStore()

    var body: some Scene {
        WindowGroup("Apartman Makbuzu") {
            MainScreen(settings: settings)
                .frame(minWidth: 1040, minHeight: 720)
                .preferredColorScheme(settings.theme.colorScheme)
        }

        // Dedicated Settings window accessible from Menu Bar (Cmd+,)
        Settings {
            SettingsView(settings: settings)
                .frame(width: 680, height: 580)
                .preferredColorScheme(settings.theme.colorScheme)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if CommandLine.arguments.contains("--generate-screenshots") {
            generateScreenshots()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NSApp.terminate(nil)
            }
            return
        }

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows {
                window.makeKeyAndOrderFront(self)
            }
            NSApp.activate(ignoringOtherApps: true)
        }
        return true
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    @MainActor
    private func generateScreenshots() {
        let currentDir = FileManager.default.currentDirectoryPath
        let outDir = URL(fileURLWithPath: currentDir).appendingPathComponent("docs/screenshots")
        try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

        let settings = ReceiptSettingsStore()
        settings.apartmentName = "Güleryüz Apartmanı"
        settings.issuer = "Ahmet Yılmaz"
        settings.defaultPayment = "1750"
        settings.seqNumber = 104
        settings.flatCount = 12
        settings.language = .turkish
        settings.theme = .system
        settings.saveOwner("Mehmet Kaya", apartmentNumber: 1)
        settings.saveOwner("Ayşe Demir", apartmentNumber: 2)

        // 1. Main Dashboard (TR)
        let mainView = MainScreen(settings: settings)
            .frame(width: 1080, height: 740)
        render(view: mainView, size: CGSize(width: 1080, height: 740), to: outDir.appendingPathComponent("01_main_dashboard.png"))

        // 2. Receipt Certificate View (TR)
        let sampleDraft = ReceiptDraft(
            receiver: "Mehmet Kaya",
            issuer: "Ahmet Yılmaz",
            notes: "2026 Ekim ayı aidatı ve asansör periyodik bakım gider payı",
            monthYear: "Ekim 2026",
            apartmentNumber: 4,
            amount: 1750.0,
            sequenceNumber: 104,
            createdDate: "18 Ekim 2026",
            showApartmentNumber: true,
            kind: .income
        )
        let docView = ReceiptDocumentView(
            draft: sampleDraft,
            apartmentName: "Güleryüz Apartmanı",
            signatureImage: nil,
            l10n: settings.l10n
        )
        .frame(width: 780, height: 540)
        render(view: docView, size: CGSize(width: 780, height: 540), to: outDir.appendingPathComponent("02_receipt_document.png"))

        // 3. Settings View
        let settingsView = SettingsView(settings: settings)
            .frame(width: 680, height: 580)
        render(view: settingsView, size: CGSize(width: 680, height: 580), to: outDir.appendingPathComponent("03_settings_view.png"))

        // 4. Expense Receipt Document
        let sampleOutcomeDraft = ReceiptDraft(
            receiver: "Asansör Bakım Servisi",
            issuer: "Ahmet Yılmaz",
            notes: "2026 Ekim ayı bina asansörü periyodik bakım ve kontrol bedeli",
            monthYear: "Ekim 2026",
            apartmentNumber: 1,
            amount: 3450.0,
            sequenceNumber: 105,
            createdDate: "18 Ekim 2026",
            showApartmentNumber: false,
            kind: .outcome
        )
        let docOutcomeView = ReceiptDocumentView(
            draft: sampleOutcomeDraft,
            apartmentName: "Güleryüz Apartmanı",
            signatureImage: nil,
            l10n: settings.l10n
        )
        .frame(width: 780, height: 540)
        render(view: docOutcomeView, size: CGSize(width: 780, height: 540), to: outDir.appendingPathComponent("04_receipt_outcome.png"))

        // 5. English Main Dashboard
        let settingsEN = ReceiptSettingsStore()
        settingsEN.apartmentName = "Sunshine Residence"
        settingsEN.issuer = "John Doe"
        settingsEN.defaultPayment = "1750"
        settingsEN.seqNumber = 104
        settingsEN.flatCount = 12
        settingsEN.language = .english
        settingsEN.saveOwner("Jane Smith", apartmentNumber: 1)

        let mainViewEN = MainScreen(settings: settingsEN)
            .frame(width: 1080, height: 740)
        render(view: mainViewEN, size: CGSize(width: 1080, height: 740), to: outDir.appendingPathComponent("05_main_dashboard_en.png"))

        print("Screenshots successfully generated in \(outDir.path)")
    }

    @MainActor
    private func render<V: View>(view: V, size: CGSize, to fileURL: URL) {
        let hosting = NSHostingView(rootView: view)
        hosting.frame = CGRect(origin: .zero, size: size)
        hosting.layoutSubtreeIfNeeded()
        guard let rep = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds) else { return }
        hosting.cacheDisplay(in: hosting.bounds, to: rep)
        guard let pngData = rep.representation(using: .png, properties: [:]) else { return }
        try? pngData.write(to: fileURL)
    }
}
