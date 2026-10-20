import Cocoa
import SwiftUI
import Combine

@main
struct AptReceiptApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var settings = ReceiptSettingsStore.shared

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
                    AboutWindowManager.shared.show(settings: ReceiptSettingsStore.shared)
                }
                Button(settings.l10n.checkForUpdates) {
                    GitHubUpdateChecker.shared.checkForUpdates(userInitiated: true)
                }
            }
            CommandGroup(replacing: .appSettings) {
                Button(settings.l10n.menuSettings) {
                    SettingsWindowManager.shared.show(settings: ReceiptSettingsStore.shared)
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

        let settings = ReceiptSettingsStore.shared
        settings.applyTheme(settings.theme)

        MenuBarManager.shared.install(settings: settings)

        // Opt-in launch check (off by default); a newer release is announced with the usual alert.
        if settings.checkUpdatesAtLaunch {
            GitHubUpdateChecker.shared.checkForUpdates(userInitiated: false, alertWhenAvailable: true)
        }

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        let settings = ReceiptSettingsStore.shared
        MenuBarManager.shared.updateMenuBar(with: settings.l10n)
    }

    @MainActor
    @objc func orderFrontStandardAboutPanel(_ sender: Any?) {
        AboutWindowManager.shared.show(settings: ReceiptSettingsStore.shared)
    }

    @MainActor
    @objc func showAboutWindow(_ sender: Any?) {
        AboutWindowManager.shared.show(settings: ReceiptSettingsStore.shared)
    }

    @MainActor
    @objc func checkForUpdatesAction(_ sender: Any?) {
        GitHubUpdateChecker.shared.checkForUpdates(userInitiated: true)
    }

    @MainActor
    @objc func showPreferencesWindow(_ sender: Any?) {
        SettingsWindowManager.shared.show(settings: ReceiptSettingsStore.shared)
    }

    @MainActor
    @objc func showSettingsWindow(_ sender: Any?) {
        SettingsWindowManager.shared.show(settings: ReceiptSettingsStore.shared)
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

        // Backup existing live user defaults so screenshot generation never mutates real user data
        let defaults = UserDefaults.standard
        let backupKeys = [
            ReceiptSettingsStore.Keys.apartmentName,
            ReceiptSettingsStore.Keys.issuer,
            ReceiptSettingsStore.Keys.defaultPayment,
            ReceiptSettingsStore.Keys.flatCount,
            ReceiptSettingsStore.Keys.seqNumber,
            ReceiptSettingsStore.Keys.language,
            ReceiptSettingsStore.Keys.theme,
            ReceiptSettingsStore.Keys.currency,
            ReceiptSettingsStore.Keys.logo
        ]
        var backupDict: [String: Any] = [:]
        for key in backupKeys {
            if let val = defaults.object(forKey: key) {
                backupDict[key] = val
            }
        }
        for i in 1...50 {
            let key = ReceiptSettingsStore.Keys.owner(i)
            if let val = defaults.object(forKey: key) {
                backupDict[key] = val
            }
        }
        defer {
            let bundleID = Bundle.main.bundleIdentifier ?? "com.babadogantech.aptreceipt"
            defaults.removePersistentDomain(forName: bundleID)
            for (key, val) in backupDict {
                defaults.set(val, forKey: key)
            }
        }

        let settings = ReceiptSettingsStore()
        settings.loadSampleDefaults(for: .english)
        settings.language = .english
        settings.currency = .usDollar
        settings.theme = .dark
        settings.seqNumber = 104
        settings.isLateFeeEnabled = true
        settings.lateFeeMonthlyRate = 5.0
        settings.lateFeeDueDay = 15

        // 1. Main Dashboard (Dark English)
        let mainView = MainScreen(settings: settings)
            .frame(width: 1080, height: 740)
        render(view: mainView, size: CGSize(width: 1080, height: 740), to: outDir.appendingPathComponent("01_main_dashboard.png"), isDark: true)

        // 2. Receipt Certificate View (English)
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
        let settingsRO = ReceiptSettingsStore()
        settingsRO.loadSampleDefaults(for: .romanian)
        settingsRO.language = .romanian
        settingsRO.currency = .romanianLeu
        settingsRO.theme = .dark

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
        let sampleArchiveStore = ReceiptArchiveStore.shared
        sampleArchiveStore.records.removeAll()
        sampleArchiveStore.add(draft: sampleDraft)
        sampleArchiveStore.add(draft: sampleOutcomeDraft)

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

// MARK: - Dedicated About Window View

struct AboutWindowView: View {
    @ObservedObject var settings: ReceiptSettingsStore

    var body: some View {
        AboutContentView(settings: settings, showsUpdateButton: true)
            .padding(.horizontal, 30)
            .padding(.top, 34)
            .padding(.bottom, 24)
            .frame(width: 500)
            .background(.thickMaterial)
            .sheet(isPresented: $settings.showLicenseViewer) {
                LicenseViewerSheet(l10n: settings.l10n)
            }
    }
}

/// Shared About layout (same structure as Arhivar): icon, name, version, tagline, credit, link buttons, copyright.
struct AboutContentView: View {
    @ObservedObject var settings: ReceiptSettingsStore
    var showsUpdateButton: Bool

    private var l10n: L10n { settings.l10n }

    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 116, height: 116)
                .shadow(color: .black.opacity(0.2), radius: 12, y: 5)

            VStack(spacing: 5) {
                Text(l10n.appTitle)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                Text(l10n.aboutVersion(AppInfo.version, AppInfo.build))
                    .font(.callout)
                    .foregroundColor(.secondary)
                Text(l10n.appDescription)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider().padding(.horizontal, 50)

            VStack(spacing: 8) {
                Label(l10n.publisher, systemImage: "building.2")
                    .font(.callout.weight(.medium))
                Text(l10n.license)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            AboutGlassGroup {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Button {
                            NSWorkspace.shared.open(AppInfo.websiteURL)
                        } label: {
                            Label("babadogan.net", systemImage: "globe")
                        }
                        Button {
                            NSWorkspace.shared.open(AppInfo.repositoryURL)
                        } label: {
                            Label(l10n.githubRepository, systemImage: "chevron.left.forwardslash.chevron.right")
                        }
                        if showsUpdateButton {
                            Button {
                                GitHubUpdateChecker.shared.checkForUpdates(userInitiated: true)
                            } label: {
                                Label(l10n.checkForUpdatesButton, systemImage: "arrow.triangle.2.circlepath")
                            }
                            .disabled(GitHubUpdateChecker.shared.isChecking)
                        }
                    }
                    Button {
                        settings.showLicenseViewer = true
                    } label: {
                        Label(l10n.viewLicenseButton, systemImage: "doc.text")
                    }
                }
                .aboutGlassButtonStyle()
                .controlSize(.small)
            }

            Text(l10n.aboutCopyright(AppInfo.currentYear))
                .font(.caption2)
                .foregroundColor(Color(NSColor.tertiaryLabelColor))
        }
    }
}

enum AppInfo {
    static let websiteURL = URL(string: "https://babadogan.net")!
    static let repositoryURL = URL(string: "https://github.com/berkbb/aptreceipt")!

    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }

    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }

    static var currentYear: String {
        String(Calendar.current.component(.year, from: Date()))
    }
}

/// Merges glass buttons into one layer on macOS 26; a plain container on older systems.
private struct AboutGlassGroup<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        #if compiler(>=6.2)
        if #available(macOS 26.0, *) {
            GlassEffectContainer(spacing: 8) { content }
        } else {
            content
        }
        #else
        content
        #endif
    }
}

private extension View {
    @ViewBuilder
    func aboutGlassButtonStyle() -> some View {
        #if compiler(>=6.2)
        if #available(macOS 26.0, *) {
            self.buttonStyle(.glass)
        } else {
            self.buttonStyle(.bordered)
        }
        #else
        self.buttonStyle(.bordered)
        #endif
    }
}

// MARK: - About Window Manager

@MainActor
final class AboutWindowManager: NSObject, NSWindowDelegate {
    static let shared = AboutWindowManager()
    private var window: NSWindow?

    func show(settings: ReceiptSettingsStore? = nil) {
        let actualSettings = settings ?? ReceiptSettingsStore.shared
        let window = window ?? makeWindow()
        window.title = actualSettings.l10n.aboutWindowHeader
        let hostingView = NSHostingView(
            rootView: AboutWindowView(settings: actualSettings)
                .preferredColorScheme(actualSettings.theme.colorScheme)
        )
        window.contentView = hostingView
        // The window takes the height of its content, like Arhivar's content-sized About window.
        window.setContentSize(hostingView.fittingSize)
        if self.window == nil {
            window.center()
            self.window = window
        }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func makeWindow() -> NSWindow {
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 480),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        newWindow.titleVisibility = .hidden
        newWindow.titlebarAppearsTransparent = true
        newWindow.isMovableByWindowBackground = true
        newWindow.isReleasedWhenClosed = false
        newWindow.delegate = self
        return newWindow
    }

    func windowWillClose(_ notification: Notification) {
        self.window = nil
    }
}

// MARK: - Settings Window Manager

@MainActor
final class SettingsWindowManager: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowManager()
    private var window: NSWindow?

    private override init() {
        super.init()
    }

    /// Opens Settings on `tab`. Every call starts a fresh draft, as before.
    func show(settings: ReceiptSettingsStore? = nil, tab: SettingsTab = .general) {
        let actualSettings = settings ?? ReceiptSettingsStore.shared
        let tabController = SettingsTabViewController(settings: actualSettings, initialTab: tab) { [weak self] in
            self?.close()
        }

        if let window = window {
            window.contentViewController = tabController
            tabController.fitWindow(animated: false)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let newWindow = NSWindow(contentViewController: tabController)
        newWindow.styleMask = [.titled, .closable, .miniaturizable]
        newWindow.toolbarStyle = .preference
        newWindow.isReleasedWhenClosed = false
        newWindow.delegate = self
        tabController.fitWindow(animated: false)
        newWindow.center()
        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func close() {
        window?.close()
        window = nil
    }

    func windowWillClose(_ notification: Notification) {
        self.window = nil
    }
}

// MARK: - Settings Toolbar Tabs

/// Arhivar-style toolbar tabs. Each tab hosts a `SettingsView` page; all pages share one draft so
/// Cancel and Save & Close keep working across tabs exactly as in the single-page window.
@MainActor
final class SettingsTabViewController: NSTabViewController {
    private let settings: ReceiptSettingsStore
    let draft = SettingsViewModel()
    private var languageObserver: AnyCancellable?

    init(settings: ReceiptSettingsStore, initialTab: SettingsTab, onClose: @escaping () -> Void) {
        self.settings = settings
        super.init(nibName: nil, bundle: nil)
        tabStyle = .toolbar
        transitionOptions = []
        draft.selectedTab = initialTab

        for tab in SettingsTab.allCases {
            let page = NSHostingController(
                rootView: AnyView(
                    SettingsView(settings: settings, initialTab: tab, viewModel: draft, onClose: onClose)
                        .preferredColorScheme(settings.theme.colorScheme)
                )
            )
            let item = NSTabViewItem(viewController: page)
            item.identifier = tab.rawValue
            item.image = NSImage(systemSymbolName: tab.iconName, accessibilityDescription: nil)
            addTabViewItem(item)
        }
        applyTitles()
        selectedTabViewItemIndex = SettingsTab.allCases.firstIndex(of: initialTab) ?? 0

        // Picking a language saves at once (existing behavior); keep the toolbar labels in step.
        languageObserver = settings.$language
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.applyTitles() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    var selectedSettingsTab: SettingsTab {
        let index = max(0, selectedTabViewItemIndex)
        return SettingsTab.allCases[min(index, SettingsTab.allCases.count - 1)]
    }

    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, didSelect: tabViewItem)
        draft.selectedTab = selectedSettingsTab
        fitWindow(animated: view.window?.isVisible == true)
        applyTitles()
    }

    /// Resizes the window to the selected tab's width, keeping its top edge in place.
    func fitWindow(animated: Bool) {
        let tab = selectedSettingsTab
        guard let window = view.window else {
            preferredContentSize = NSSize(width: tab.preferredWidth, height: SettingsTab.preferredHeight)
            return
        }
        let contentRect = NSRect(x: 0, y: 0, width: tab.preferredWidth, height: SettingsTab.preferredHeight)
        var frame = window.frameRect(forContentRect: contentRect)
        frame.origin.x = window.frame.midX - frame.width / 2
        frame.origin.y = window.frame.maxY - frame.height
        window.setFrame(frame, display: true, animate: animated)
    }

    private func applyTitles() {
        let l10n = settings.l10n
        for (item, tab) in zip(tabViewItems, SettingsTab.allCases) {
            item.label = tab.title(l10n: l10n)
            item.viewController?.title = tab.title(l10n: l10n)
        }
        view.window?.title = selectedSettingsTab.title(l10n: l10n)
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
        var seenSettings = false
        var seenUpdate = false
        var aboutIndex = 0
        var itemsToRemove: [NSMenuItem] = []

        for (idx, item) in submenu.items.enumerated() {
            let actionStr = item.action?.description ?? ""
            let titleLower = item.title.lowercased()

            if actionStr.contains("orderFrontStandardAboutPanel") || actionStr.contains("showAboutWindow") || titleLower.contains("about") || titleLower.contains("hakkında") || titleLower.contains("despre") {
                item.title = l10n.menuAboutApp
                item.target = NSApp.delegate
                item.action = #selector(AppDelegate.orderFrontStandardAboutPanel(_:))
                aboutIndex = idx
            } else if actionStr.contains("checkForUpdatesAction") || titleLower.contains("update") || titleLower.contains("güncelle") || titleLower.contains("actualiz") {
                seenUpdate = true
                item.title = l10n.checkForUpdates
                item.target = NSApp.delegate
                item.action = #selector(AppDelegate.checkForUpdatesAction(_:))
            } else if actionStr.contains("showPreferencesWindow") || actionStr.contains("showSettingsWindow") || actionStr.contains("openSettings") || titleLower.contains("preferences") || titleLower.contains("settings") || titleLower.contains("tercihler") || titleLower.contains("ayarlar") || titleLower.contains("preferințe") || titleLower.contains("configurări") {
                if seenSettings {
                    itemsToRemove.append(item)
                } else {
                    seenSettings = true
                    item.title = l10n.menuSettings
                    item.target = NSApp.delegate
                    item.action = #selector(AppDelegate.showPreferencesWindow(_:))
                    item.keyEquivalent = ","
                    item.keyEquivalentModifierMask = .command
                }
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

        for item in itemsToRemove {
            submenu.removeItem(item)
        }

        if !seenUpdate {
            let updateItem = NSMenuItem(title: l10n.checkForUpdates, action: #selector(AppDelegate.checkForUpdatesAction(_:)), keyEquivalent: "")
            updateItem.target = NSApp.delegate
            let targetIdx = min(aboutIndex + 1, submenu.items.count)
            submenu.insertItem(updateItem, at: targetIdx)
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
