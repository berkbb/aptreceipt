import Cocoa
import SwiftUI

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
    }
}

/// Shared About layout (same structure as Arhivar): icon, name, version, tagline, credit, link buttons, copyright.
struct AboutContentView: View {
    @ObservedObject var settings: ReceiptSettingsStore
    var showsUpdateButton: Bool
    /// Local to this view, so the license opens only in the window whose button was pressed.
    @State private var showsLicense = false

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
                        showsLicense = true
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
        .sheet(isPresented: $showsLicense) {
            LicenseViewerSheet(l10n: l10n)
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
