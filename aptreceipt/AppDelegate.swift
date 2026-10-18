import Cocoa
import SwiftUI

@main
struct AptReceiptApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var settings = ReceiptSettingsStore()

    var body: some Scene {
        WindowGroup(settings.l10n.appTitle) {
            MainScreen(settings: settings)
                .frame(minWidth: 1040, minHeight: 720)
                .preferredColorScheme(settings.theme.colorScheme)
                .onReceive(NotificationCenter.default.publisher(for: .appLanguageDidChange)) { _ in
                    MenuBarManager.shared.updateMenuBar(with: settings.l10n)
                }
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button(settings.l10n.menuAboutApp) {
                    AboutWindowManager.shared.show(settings: settings)
                }
            }
            CommandGroup(replacing: .appSettings) {
                Button(settings.l10n.menuSettings) {
                    NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            CommandGroup(replacing: .help) {
                Button(settings.l10n.menuHelpItem) {
                    if let url = URL(string: "https://github.com/berkbb/aptreceipt") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
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

        let settings = ReceiptSettingsStore()
        settings.applyTheme(settings.theme)

        MenuBarManager.shared.install(settings: settings)

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        let settings = ReceiptSettingsStore()
        MenuBarManager.shared.updateMenuBar(with: settings.l10n)
    }

    @MainActor
    @objc func orderFrontStandardAboutPanel(_ sender: Any?) {
        AboutWindowManager.shared.show()
    }

    @MainActor
    @objc func showAboutWindow(_ sender: Any?) {
        AboutWindowManager.shared.show()
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
        settings.currency = .turkishLira
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
            kind: .income,
            currency: .turkishLira
        )
        let docView = ReceiptDocumentView(
            draft: sampleDraft,
            apartmentName: "Güleryüz Apartmanı",
            signatureImage: nil,
            l10n: settings.l10n
        )
        .frame(width: 595, height: 842)
        render(view: docView, size: CGSize(width: 595, height: 842), to: outDir.appendingPathComponent("02_receipt_document.png"))
        renderPDF(view: docView.environment(\.colorScheme, .light), size: CGSize(width: 595, height: 842), to: outDir.appendingPathComponent("02_receipt_document.pdf"))

        // 3. Settings View (About & License)
        let settingsView = SettingsView(settings: settings, initialTab: .about)
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
            kind: .outcome,
            currency: .turkishLira
        )
        let docOutcomeView = ReceiptDocumentView(
            draft: sampleOutcomeDraft,
            apartmentName: "Güleryüz Apartmanı",
            signatureImage: nil,
            l10n: settings.l10n
        )
        .frame(width: 595, height: 842)
        render(view: docOutcomeView, size: CGSize(width: 595, height: 842), to: outDir.appendingPathComponent("04_receipt_outcome.png"))

        // 5. English Main Dashboard
        let settingsEN = ReceiptSettingsStore()
        settingsEN.apartmentName = "Sunshine Residence"
        settingsEN.issuer = "John Doe"
        settingsEN.defaultPayment = "1750"
        settingsEN.seqNumber = 104
        settingsEN.flatCount = 12
        settingsEN.language = .english
        settingsEN.currency = .usDollar
        settingsEN.saveOwner("Jane Smith", apartmentNumber: 1)

        let mainViewEN = MainScreen(settings: settingsEN)
            .frame(width: 1080, height: 740)
        render(view: mainViewEN, size: CGSize(width: 1080, height: 740), to: outDir.appendingPathComponent("05_main_dashboard_en.png"))

        // 6. Romanian Main Dashboard
        let settingsRO = ReceiptSettingsStore()
        settingsRO.apartmentName = "Asociația Parcul Tineretului"
        settingsRO.issuer = "Andrei Popescu"
        settingsRO.defaultPayment = "1750"
        settingsRO.seqNumber = 104
        settingsRO.flatCount = 12
        settingsRO.language = .romanian
        settingsRO.currency = .romanianLeu
        settingsRO.saveOwner("Elena Radu", apartmentNumber: 1)

        let mainViewRO = MainScreen(settings: settingsRO)
            .frame(width: 1080, height: 740)
        render(view: mainViewRO, size: CGSize(width: 1080, height: 740), to: outDir.appendingPathComponent("06_main_dashboard_ro.png"))

        // 7. About Window
        let aboutView = AboutWindowView(settings: settings)
            .frame(width: 420, height: 460)
        render(view: aboutView, size: CGSize(width: 420, height: 460), to: outDir.appendingPathComponent("07_about_window.png"))

        print("Screenshots successfully generated in \(outDir.path)")
    }

    @MainActor
    private func render<V: View>(view: V, size: CGSize, to fileURL: URL) {
        let hosting = NSHostingView(rootView: view)
        hosting.appearance = NSAppearance(named: .aqua)
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

// MARK: - Dedicated About Window View

struct AboutWindowView: View {
    @ObservedObject var settings: ReceiptSettingsStore
    @State private var isPresentingLicense = false

    private var l10n: L10n {
        settings.l10n
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with App Icon and Meta
            VStack(spacing: 12) {
                if let appIcon = NSImage(named: "AppIcon") ?? NSImage(named: "Logo") {
                    Image(nsImage: appIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 3)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 6, x: 0, y: 3)

                        Image(systemName: "building.2.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 46, height: 46)
                            .foregroundColor(.white)
                    }
                }

                VStack(spacing: 4) {
                    Text(l10n.appTitle)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(NSColor.textColor))

                    Text(l10n.appVersionText)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(NSColor.textColor))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(Capsule())
                }

                Text(l10n.appDescription)
                    .font(.system(size: 11))
                    .foregroundColor(Color(NSColor.secondaryLabelColor))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 24)
            }
            .padding(.top, 24)
            .padding(.bottom, 16)

            Divider()

            // Details, Publisher, License
            VStack(spacing: 14) {
                // Publisher & GitHub
                HStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.shield.checkmark.fill")
                            .foregroundColor(.accentColor)
                        Text(l10n.publisher)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(NSColor.textColor))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(Capsule())

                    if let url = URL(string: "https://github.com/berkbb/aptreceipt") {
                        Link(destination: url) {
                            HStack(spacing: 5) {
                                Image(systemName: "link")
                                Text(l10n.githubRepository)
                            }
                            .font(.system(size: 11, weight: .medium))
                        }
                    }
                }

                // License Section
                VStack(spacing: 8) {
                    Text(l10n.license)
                        .font(.system(size: 11))
                        .foregroundColor(Color(NSColor.secondaryLabelColor))
                        .multilineTextAlignment(.center)

                    Button {
                        isPresentingLicense = true
                    } label: {
                        Label(l10n.viewLicenseButton, systemImage: "doc.text.magnifyingglass")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )

                // Copyright
                Text(l10n.copyright)
                    .font(.system(size: 10))
                    .foregroundColor(Color(NSColor.secondaryLabelColor))
            }
            .padding(20)
        }
        .frame(width: 420, height: 460)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $isPresentingLicense) {
            LicenseViewerSheet(l10n: l10n)
        }
    }
}

// MARK: - About Window Manager

@MainActor
final class AboutWindowManager: NSObject, NSWindowDelegate {
    static let shared = AboutWindowManager()
    private var window: NSWindow?

    func show(settings: ReceiptSettingsStore? = nil) {
        let actualSettings = settings ?? ReceiptSettingsStore()
        if let window = window {
            window.title = actualSettings.l10n.aboutWindowHeader
            window.contentView = NSHostingView(
                rootView: AboutWindowView(settings: actualSettings)
                    .preferredColorScheme(actualSettings.theme.colorScheme)
            )
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 460),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        newWindow.title = actualSettings.l10n.aboutWindowHeader
        newWindow.isReleasedWhenClosed = false
        newWindow.delegate = self
        newWindow.center()
        newWindow.contentView = NSHostingView(
            rootView: AboutWindowView(settings: actualSettings)
                .preferredColorScheme(actualSettings.theme.colorScheme)
        )
        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Menu Bar Localization Manager

@MainActor
final class MenuBarManager: NSObject {
    static let shared = MenuBarManager()
    private var observer: NSObjectProtocol?
    private var hasInstalled = false

    private override init() {
        super.init()
    }

    func install(settings: ReceiptSettingsStore) {
        updateMenuBar(with: settings.l10n)

        if !hasInstalled {
            hasInstalled = true
            observer = NotificationCenter.default.addObserver(
                forName: .appLanguageDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    let current = ReceiptSettingsStore()
                    self?.updateMenuBar(with: current.l10n)
                }
            }
        }

        for delay in [0.05, 0.15, 0.3, 0.6] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.updateMenuBar(with: settings.l10n)
            }
        }
    }

    func updateMenuBar(with l10n: L10n) {
        guard let mainMenu = NSApp.mainMenu else { return }

        for (index, topItem) in mainMenu.items.enumerated() {
            guard let submenu = topItem.submenu else { continue }

            if isAppMenu(topItem: topItem, index: index) {
                topItem.title = l10n.menuApp
                submenu.title = l10n.menuApp
                localizeAppSubmenu(submenu, with: l10n)
            } else if isFileMenu(topItem: topItem, index: index) {
                topItem.title = l10n.menuFile
                submenu.title = l10n.menuFile
                localizeFileSubmenu(submenu, with: l10n)
            } else if isEditMenu(topItem: topItem, index: index) {
                topItem.title = l10n.menuEdit
                submenu.title = l10n.menuEdit
                localizeEditSubmenu(submenu, with: l10n)
            } else if isViewMenu(topItem: topItem, index: index) {
                topItem.title = l10n.menuView
                submenu.title = l10n.menuView
                localizeViewSubmenu(submenu, with: l10n)
            } else if isWindowMenu(topItem: topItem, index: index) {
                topItem.title = l10n.menuWindow
                submenu.title = l10n.menuWindow
                localizeWindowSubmenu(submenu, with: l10n)
            } else if isHelpMenu(topItem: topItem, index: index) {
                topItem.title = l10n.menuHelp
                submenu.title = l10n.menuHelp
                localizeHelpSubmenu(submenu, with: l10n)
            }
        }
    }

    private func isAppMenu(topItem: NSMenuItem, index: Int) -> Bool {
        if index == 0 { return true }
        if let sub = topItem.submenu {
            for item in sub.items {
                if item.action == #selector(NSApplication.terminate(_:)) || item.action == #selector(NSApplication.hide(_:)) {
                    return true
                }
            }
        }
        return false
    }

    private func isFileMenu(topItem: NSMenuItem, index: Int) -> Bool {
        let title = topItem.title.lowercased()
        if title == "file" || title == "dosya" || title == "fișier" || title == "fisier" { return true }
        if let sub = topItem.submenu {
            for item in sub.items {
                if item.action == #selector(NSWindow.performClose(_:)) {
                    return true
                }
            }
        }
        return index == 1
    }

    private func isEditMenu(topItem: NSMenuItem, index: Int) -> Bool {
        let title = topItem.title.lowercased()
        if title == "edit" || title == "düzenle" || title == "duzenle" || title == "editare" { return true }
        if let sub = topItem.submenu {
            for item in sub.items {
                if let actionName = item.action?.description,
                   actionName.contains("undo:") || actionName.contains("copy:") || actionName.contains("selectAll:") {
                    return true
                }
            }
        }
        return index == 2
    }

    private func isViewMenu(topItem: NSMenuItem, index: Int) -> Bool {
        let title = topItem.title.lowercased()
        if title == "view" || title == "görünüm" || title == "gorunum" || title == "vizualizare" { return true }
        if let sub = topItem.submenu {
            for item in sub.items {
                if let actionName = item.action?.description, actionName.contains("toggleFullScreen:") {
                    return true
                }
            }
        }
        return false
    }

    private func isWindowMenu(topItem: NSMenuItem, index: Int) -> Bool {
        let title = topItem.title.lowercased()
        if title == "window" || title == "pencere" || title == "fereastră" || title == "fereastra" { return true }
        if let sub = topItem.submenu {
            for item in sub.items {
                if item.action == #selector(NSWindow.performMiniaturize(_:)) || item.action == #selector(NSApplication.arrangeInFront(_:)) {
                    return true
                }
            }
        }
        return false
    }

    private func isHelpMenu(topItem: NSMenuItem, index: Int) -> Bool {
        let title = topItem.title.lowercased()
        if title == "help" || title == "yardım" || title == "yardim" || title == "ajutor" { return true }
        if let sub = topItem.submenu {
            for item in sub.items {
                if item.action == #selector(NSApplication.showHelp(_:)) {
                    return true
                }
            }
        }
        return false
    }

    private func localizeAppSubmenu(_ submenu: NSMenu, with l10n: L10n) {
        for item in submenu.items {
            let actionStr = item.action?.description ?? ""
            let titleLower = item.title.lowercased()

            if actionStr.contains("orderFrontStandardAboutPanel") || actionStr.contains("showAboutWindow") || titleLower.contains("about") || titleLower.contains("hakkında") || titleLower.contains("despre") {
                item.title = l10n.menuAboutApp
                item.target = NSApp.delegate
                item.action = #selector(AppDelegate.orderFrontStandardAboutPanel(_:))
            } else if actionStr.contains("showPreferencesWindow") || actionStr.contains("openSettings") || titleLower.contains("preferences") || titleLower.contains("settings") || titleLower.contains("tercihler") || titleLower.contains("ayarlar") || titleLower.contains("preferințe") || titleLower.contains("configurări") {
                item.title = l10n.menuSettings
            } else if item.hasSubmenu || titleLower.contains("service") || titleLower.contains("servis") || titleLower.contains("servici") {
                item.title = l10n.menuServices
                item.submenu?.title = l10n.menuServices
            } else if item.action == #selector(NSApplication.hide(_:)) || titleLower.contains("hide ") || titleLower.contains("gizle") || titleLower.contains("ascunde ") {
                if !titleLower.contains("others") && !titleLower.contains("diğer") && !titleLower.contains("celelalte") {
                    item.title = l10n.menuHideApp
                }
            } else if item.action == #selector(NSApplication.hideOtherApplications(_:)) || titleLower.contains("hide others") || titleLower.contains("diğerlerini gizle") || titleLower.contains("ascunde celelalte") {
                item.title = l10n.menuHideOthers
            } else if item.action == #selector(NSApplication.unhideAllApplications(_:)) || titleLower.contains("show all") || titleLower.contains("tümünü göster") || titleLower.contains("afișează toate") {
                item.title = l10n.menuShowAll
            } else if item.action == #selector(NSApplication.terminate(_:)) || titleLower.contains("quit ") || titleLower.contains("çık") || titleLower.contains("închide ") {
                item.title = l10n.menuQuitApp
            }
        }
    }

    private func localizeFileSubmenu(_ submenu: NSMenu, with l10n: L10n) {
        for item in submenu.items {
            let actionStr = item.action?.description ?? ""
            let titleLower = item.title.lowercased()

            if item.action == #selector(NSWindow.performClose(_:)) || titleLower.contains("close") || titleLower.contains("kapat") || titleLower.contains("închide") {
                item.title = l10n.menuCloseWindow
            } else if actionStr.contains("newWindow") || titleLower.contains("new") || titleLower.contains("yeni") || titleLower.contains("nou") {
                item.title = l10n.menuNewWindow
            }
        }
    }

    private func localizeEditSubmenu(_ submenu: NSMenu, with l10n: L10n) {
        for item in submenu.items {
            let actionStr = item.action?.description ?? ""
            let titleLower = item.title.lowercased()

            if actionStr.contains("undo:") || titleLower.contains("undo") || titleLower == "geri" || titleLower == "geri al" || titleLower == "anulează" {
                item.title = l10n.menuUndo
            } else if actionStr.contains("redo:") || titleLower.contains("redo") || titleLower == "yinele" || titleLower == "refă" {
                item.title = l10n.menuRedo
            } else if actionStr.contains("cut:") || titleLower.contains("cut") || titleLower == "kes" || titleLower == "decupează" {
                item.title = l10n.menuCut
            } else if actionStr.contains("copy:") || titleLower.contains("copy") || titleLower == "kopyala" || titleLower == "copiază" {
                item.title = l10n.menuCopy
            } else if actionStr.contains("pasteAsPlainText:") || titleLower.contains("match style") || titleLower.contains("stili eşleştir") || titleLower.contains("potrivește stilul") {
                item.title = l10n.menuPasteAndMatch
            } else if actionStr.contains("paste:") || titleLower == "paste" || titleLower == "yapıştır" || titleLower == "lipește" {
                item.title = l10n.menuPaste
            } else if actionStr.contains("delete:") || titleLower.contains("delete") || titleLower == "sil" || titleLower == "șterge" {
                item.title = l10n.menuDelete
            } else if actionStr.contains("selectAll:") || titleLower.contains("select all") || titleLower.contains("tümünü seç") || titleLower.contains("selectează tot") {
                item.title = l10n.menuSelectAll
            }
        }
    }

    private func localizeViewSubmenu(_ submenu: NSMenu, with l10n: L10n) {
        for item in submenu.items {
            let actionStr = item.action?.description ?? ""
            let titleLower = item.title.lowercased()

            if actionStr.contains("toggleFullScreen:") || titleLower.contains("full screen") || titleLower.contains("tam ekran") || titleLower.contains("ecran complet") {
                item.title = l10n.menuFullScreen
            }
        }
    }

    private func localizeWindowSubmenu(_ submenu: NSMenu, with l10n: L10n) {
        for item in submenu.items {
            let titleLower = item.title.lowercased()

            if item.action == #selector(NSWindow.performMiniaturize(_:)) || titleLower.contains("minimize") || titleLower.contains("küçült") || titleLower.contains("minimizează") {
                item.title = l10n.menuMinimize
            } else if item.action == #selector(NSWindow.performZoom(_:)) || titleLower.contains("zoom") || titleLower.contains("büyüt") {
                item.title = l10n.menuZoom
            } else if item.action == #selector(NSApplication.arrangeInFront(_:)) || titleLower.contains("bring all") || titleLower.contains("öne getir") || titleLower.contains("adu toate") {
                item.title = l10n.menuBringAllToFront
            }
        }
    }

    private func localizeHelpSubmenu(_ submenu: NSMenu, with l10n: L10n) {
        for item in submenu.items {
            let titleLower = item.title.lowercased()

            if item.action == #selector(NSApplication.showHelp(_:)) || titleLower.contains("help") || titleLower.contains("yardım") || titleLower.contains("ajutor") {
                item.title = l10n.menuHelpItem
            }
        }
    }
}
