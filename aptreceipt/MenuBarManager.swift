import Cocoa
import SwiftUI

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
