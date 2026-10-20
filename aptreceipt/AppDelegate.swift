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
            CommandGroup(after: .newItem) {
                Button(settings.l10n.verifyReceiptMenu) {
                    ReceiptVerificationWindowManager.shared.show(settings: ReceiptSettingsStore.shared)
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
        if ScreenshotMode.isActive {
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

}
