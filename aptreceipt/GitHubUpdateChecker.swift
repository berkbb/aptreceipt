//
//  GitHubUpdateChecker.swift
//  aptreceipt
//
//  Created by berkbb on 19.10.2026.
//  Copyright © 2023-2026 Babadogan Tech and Edu. All rights reserved.
//

import AppKit
import Foundation
import SwiftUI

// MARK: - GitHub Release Model

public struct GitHubRelease: Codable, Identifiable, Equatable {
    public var id: String { tagName }
    public let tagName: String
    public let name: String?
    public let body: String?
    public let htmlUrl: String
    public let publishedAt: String?

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case htmlUrl = "html_url"
        case publishedAt = "published_at"
    }

    public init(tagName: String, name: String?, body: String?, htmlUrl: String, publishedAt: String? = nil) {
        self.tagName = tagName
        self.name = name
        self.body = body
        self.htmlUrl = htmlUrl
        self.publishedAt = publishedAt
    }
}

// MARK: - Semver Comparator

public enum SemverCompare {
    /// Compares two semver strings (e.g. "v3.4.0" vs "3.3.0").
    /// Returns true if remote is strictly newer than local.
    public static func isRemoteNewer(remote: String, local: String) -> Bool {
        let cleanRemote = cleanVersion(remote)
        let cleanLocal = cleanVersion(local)

        let remoteParts = cleanRemote.split(separator: ".").compactMap { Int($0) }
        let localParts = cleanLocal.split(separator: ".").compactMap { Int($0) }

        let count = max(remoteParts.count, localParts.count)
        for i in 0..<count {
            let r = i < remoteParts.count ? remoteParts[i] : 0
            let l = i < localParts.count ? localParts[i] : 0
            if r > l { return true }
            if r < l { return false }
        }
        return false
    }

    private static func cleanVersion(_ version: String) -> String {
        var v = version.trimmingCharacters(in: .whitespacesAndNewlines)
        if v.hasPrefix("v") || v.hasPrefix("V") {
            v.removeFirst()
        }
        if let dashIdx = v.firstIndex(of: "-") {
            v = String(v[..<dashIdx])
        }
        return v
    }
}

// MARK: - Update Check Status

public enum UpdateCheckStatus: Equatable {
    case idle
    case checking
    case updateAvailable(release: GitHubRelease)
    case upToDate(currentVersion: String)
    case failed(message: String)
}

// MARK: - GitHub Update Checker Service

@MainActor
public final class GitHubUpdateChecker: ObservableObject {
    public static let shared = GitHubUpdateChecker()

    @Published public var status: UpdateCheckStatus = .idle
    @Published public var isChecking: Bool = false
    @Published public var latestRelease: GitHubRelease? = nil
    @Published public var showUpdateModal: Bool = false
    @Published public var lastCheckedDate: Date? = nil

    private let repoOwner = "berkbb"
    private let repoName = "aptreceipt"
    private let releasesURLString = "https://api.github.com/repos/berkbb/aptreceipt/releases/latest"

    public var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "3.3.0"
    }

    private init() {}

    /// Checks for updates via GitHub Releases API.
    /// - Parameter userInitiated: If true, will present native alerts / sheets for up-to-date and error states.
    public func checkForUpdates(userInitiated: Bool = true) {
        guard !isChecking else { return }

        isChecking = true
        status = .checking

        guard let url = URL(string: releasesURLString) else {
            isChecking = false
            status = .failed(message: "Invalid releases URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15.0
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("AptReceipt-macOS/\(currentAppVersion)", forHTTPHeaderField: "User-Agent")

        Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                self.lastCheckedDate = Date()
                self.isChecking = false

                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    let decoder = JSONDecoder()
                    let release = try decoder.decode(GitHubRelease.self, from: data)
                    self.latestRelease = release

                    if SemverCompare.isRemoteNewer(remote: release.tagName, local: self.currentAppVersion) {
                        self.status = .updateAvailable(release: release)
                        self.showUpdateModal = true
                        if userInitiated {
                            self.presentUpdateAvailableAlert(release: release)
                        }
                    } else {
                        self.status = .upToDate(currentVersion: self.currentAppVersion)
                        if userInitiated {
                            self.presentUpToDateAlert()
                        }
                    }
                } else {
                    let errorMsg = "GitHub API returned status \((response as? HTTPURLResponse)?.statusCode ?? -1)"
                    self.status = .failed(message: errorMsg)
                    if userInitiated {
                        self.presentErrorAlert(message: errorMsg)
                    }
                }
            } catch {
                self.isChecking = false
                let errorMsg = error.localizedDescription
                self.status = .failed(message: errorMsg)
                if userInitiated {
                    self.presentErrorAlert(message: errorMsg)
                }
            }
        }
    }

    // MARK: - Native Alerts

    private func presentUpdateAvailableAlert(release: GitHubRelease) {
        let l10n = ReceiptSettingsStore.shared.l10n
        let alert = NSAlert()
        alert.messageText = l10n.updateAvailableTitle
        alert.informativeText = "\(l10n.appTitle) \(release.tagName) \(l10n.isNowAvailableText) (\(l10n.currentVersionPrefix) \(currentAppVersion)).\n\n\(release.name ?? "")\n\(release.body ?? "")"
        alert.alertStyle = .informational
        alert.addButton(withTitle: l10n.downloadUpdate)
        alert.addButton(withTitle: l10n.laterButton)

        if alert.runModal() == .alertFirstButtonReturn {
            if let targetURL = URL(string: release.htmlUrl) {
                NSWorkspace.shared.open(targetURL)
            }
        }
    }

    private func presentUpToDateAlert() {
        let l10n = ReceiptSettingsStore.shared.l10n
        let alert = NSAlert()
        alert.messageText = l10n.upToDateTitle
        alert.informativeText = String(format: l10n.upToDateMessage, currentAppVersion)
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func presentErrorAlert(message: String) {
        let l10n = ReceiptSettingsStore.shared.l10n
        let alert = NSAlert()
        alert.messageText = l10n.updateCheckFailedTitle
        alert.informativeText = "\(l10n.updateCheckFailedMessage)\n\n(\(message))"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: l10n.openReleasesPage)

        if alert.runModal() == .alertSecondButtonReturn {
            if let releasesURL = URL(string: "https://github.com/\(repoOwner)/\(repoName)/releases") {
                NSWorkspace.shared.open(releasesURL)
            }
        }
    }
}
