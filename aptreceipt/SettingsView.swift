import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var settings: ReceiptSettingsStore
    @StateObject var viewModel: SettingsViewModel
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var updateChecker = GitHubUpdateChecker.shared
    @State var confirmsPreferenceReset = false
    @State var showsRecoveryCode = false
    @State var recoveryCodeInput = ""
    @State var recoveryCodeMessage: (text: String, isError: Bool)?
    /// The tab this page shows. In the settings window each toolbar tab hosts its own page and all
    /// pages share one draft, so Save & Close commits the edits made on every tab.
    let tab: SettingsTab
    let onClose: (() -> Void)?

    /// - Parameters:
    ///   - viewModel: The shared draft. When `nil` (screenshots, standalone sheet) the page owns a fresh draft.
    ///   - onClose: Closes the hosting window after Cancel or a successful save.
    init(
        settings: ReceiptSettingsStore,
        initialTab: SettingsTab = .general,
        viewModel: SettingsViewModel? = nil,
        onClose: (() -> Void)? = nil
    ) {
        self.settings = settings
        let vm = viewModel ?? SettingsViewModel()
        if viewModel == nil {
            vm.selectedTab = initialTab
        }
        _viewModel = StateObject(wrappedValue: vm)
        self.tab = initialTab
        self.onClose = onClose
    }

    var l10n: L10n {
        L10n(viewModel.language)
    }

    /// Only the visible page presents alerts; hidden toolbar pages stay quiet.
    var isActivePage: Bool {
        viewModel.selectedTab == tab
    }

    var body: some View {
        VStack(spacing: 0) {
            // Every tab is a grouped Form that scrolls on its own (Arhivar standard).
            tabContent
                .frame(maxHeight: .infinity)

            Divider()

            // Footer Buttons
            HStack {
                Button(l10n.cancel) {
                    close()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(l10n.saveAndClose) {
                    if viewModel.save(to: settings) {
                        NotificationCenter.default.post(name: .settingsDidSave, object: settings)
                        close()
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: tab.preferredWidth, height: SettingsTab.preferredHeight)
        .onAppear {
            // Load once per draft; switching toolbar tabs must not discard edits made on other tabs.
            if !viewModel.isLoaded {
                viewModel.load(from: settings)
            }
        }
        .alert(item: isActivePage ? $viewModel.validationError : .constant(nil)) { issue in
            Alert(
                title: Text(l10n.validationErrorTitle),
                message: Text(issue.message),
                dismissButton: .default(Text(l10n.okButton))
            )
        }
        .alert(isPresented: isActivePage ? $viewModel.showRestartAlert : .constant(false)) {
            Alert(
                title: Text(l10n.restartWarningTitle),
                message: Text(l10n.restartMenuBarNotice),
                dismissButton: .default(Text(l10n.okButton))
            )
        }
    }

    @ViewBuilder
    var tabContent: some View {
        switch tab {
        case .general:
            generalSettingsTab
        case .residents:
            residentsTab
        case .vendors:
            vendorsTab
        case .appearance:
            appearanceTab
        case .signature:
            signatureTab
        case .backup:
            backupTab
        case .about:
            aboutTab
        }
    }

    func close() {
        presentationMode.wrappedValue.dismiss()
        if let onClose {
            onClose()
        } else {
            SettingsWindowManager.shared.close()
        }
    }
}
