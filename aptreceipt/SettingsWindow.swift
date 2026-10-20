import Cocoa
import SwiftUI
import Combine

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
            // Each page reports its own size; the tab controller and `fitWindow` both size the window
            // from it, so they never fight (which made the window drift and clipped the wide tabs).
            page.sizingOptions = []
            page.preferredContentSize = NSSize(width: tab.preferredWidth, height: SettingsTab.preferredHeight)
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

    /// Resizes the window to the selected tab's width. The top-left corner stays where it is, as in
    /// macOS settings windows, so switching tabs never moves the window.
    func fitWindow(animated: Bool) {
        let tab = selectedSettingsTab
        let size = NSSize(width: tab.preferredWidth, height: SettingsTab.preferredHeight)
        preferredContentSize = size
        guard let window = view.window else { return }
        var frame = window.frameRect(forContentRect: NSRect(origin: .zero, size: size))
        frame.origin.x = window.frame.minX
        frame.origin.y = window.frame.maxY - frame.height
        guard frame != window.frame else { return }
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
