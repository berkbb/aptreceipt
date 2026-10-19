//
//  GitHubUpdateChecker.swift
//  aptreceipt
//
//  Created by berkbb on 19.10.2026.
//  Copyright © 2023-2026 Babadogan Tech and Edu. All rights reserved.
//

import AppKit
import CryptoKit
import Foundation
import SwiftUI

// MARK: - GitHub Release Model

public struct GitHubReleaseAsset: Codable, Equatable {
    public let name: String
    public let browserDownloadUrl: String
    public let size: Int?

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadUrl = "browser_download_url"
        case size
    }

    public init(name: String, browserDownloadUrl: String, size: Int? = nil) {
        self.name = name
        self.browserDownloadUrl = browserDownloadUrl
        self.size = size
    }
}

public struct GitHubRelease: Codable, Identifiable, Equatable {
    public var id: String { tagName }
    public let tagName: String
    public let name: String?
    public let body: String?
    public let htmlUrl: String
    public let publishedAt: String?
    public let assets: [GitHubReleaseAsset]

    static let checksumAssetName = "SHA256SUMS.txt"

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case htmlUrl = "html_url"
        case publishedAt = "published_at"
        case assets
    }

    public init(tagName: String, name: String?, body: String?, htmlUrl: String, publishedAt: String? = nil, assets: [GitHubReleaseAsset] = []) {
        self.tagName = tagName
        self.name = name
        self.body = body
        self.htmlUrl = htmlUrl
        self.publishedAt = publishedAt
        self.assets = assets
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tagName = try container.decode(String.self, forKey: .tagName)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        body = try container.decodeIfPresent(String.self, forKey: .body)
        htmlUrl = try container.decode(String.self, forKey: .htmlUrl)
        publishedAt = try container.decodeIfPresent(String.self, forKey: .publishedAt)
        assets = try container.decodeIfPresent([GitHubReleaseAsset].self, forKey: .assets) ?? []
    }

    /// The disk image installer attached to the release, if any.
    public var dmgAsset: GitHubReleaseAsset? {
        assets.first { $0.name.lowercased().hasSuffix(".dmg") }
    }

    /// The `SHA256SUMS.txt` file attached to the release, if any.
    public var checksumAsset: GitHubReleaseAsset? {
        assets.first { $0.name == Self.checksumAssetName }
    }
}

// MARK: - SHA-256 Checksums

public enum UpdateChecksums {
    /// Parses `shasum -a 256` output into a file name → lowercase hex digest map.
    public static func parse(_ text: String) -> [String: String] {
        var result: [String: String] = [:]
        for line in text.split(whereSeparator: \.isNewline) {
            let parts = line.split(maxSplits: 1, whereSeparator: \.isWhitespace)
            guard parts.count == 2 else { continue }
            let digest = parts[0].lowercased()
            guard digest.count == 64, digest.allSatisfy(\.isHexDigit) else { continue }
            var fileName = parts[1].trimmingCharacters(in: .whitespaces)
            // shasum marks binary-mode entries with a leading "*".
            if fileName.hasPrefix("*") {
                fileName.removeFirst()
            }
            result[fileName] = digest
        }
        return result
    }

    /// Streams the file through SHA-256 and returns the lowercase hex digest.
    public static func sha256(of fileURL: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: fileURL)
        defer { try? handle.close() }
        var hasher = SHA256()
        while let chunk = try handle.read(upToCount: 1 << 20), !chunk.isEmpty {
            hasher.update(data: chunk)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
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
    @Published public var isDownloading: Bool = false
    @Published public var downloadProgress: Double = 0
    @Published public var downloadingVersion: String = ""

    private var downloadTask: Task<Void, Never>? = nil
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
        if isDownloading {
            UpdateDownloadWindowManager.shared.show()
            return
        }

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
        alert.informativeText = "\(l10n.appTitle) \(release.tagName) \(l10n.isNowAvailableText) (\(l10n.currentVersionPrefix) \(currentAppVersion))."
        alert.alertStyle = .informational
        if let notes = release.body?.trimmingCharacters(in: .whitespacesAndNewlines), !notes.isEmpty {
            alert.accessoryView = Self.makeReleaseNotesView(notes)
        }
        alert.addButton(withTitle: l10n.downloadUpdate)
        alert.addButton(withTitle: l10n.laterButton)

        if alert.runModal() == .alertFirstButtonReturn {
            downloadUpdate(release: release)
        }
    }

    /// Release notes can be long, so they go in a fixed-height scroll view instead of the alert text.
    private static func makeReleaseNotesView(_ notes: String) -> NSView {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.frame = NSRect(x: 0, y: 0, width: 420, height: 220)
        scrollView.borderType = .bezelBorder
        if let textView = scrollView.documentView as? NSTextView {
            textView.isEditable = false
            textView.drawsBackground = false
            textView.textContainerInset = NSSize(width: 6, height: 6)
            let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
            if let markdown = try? AttributedString(markdown: notes, options: options) {
                let attributed = NSMutableAttributedString(markdown)
                attributed.addAttributes([
                    .foregroundColor: NSColor.labelColor,
                    .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
                ], range: NSRange(location: 0, length: attributed.length))
                textView.textStorage?.setAttributedString(attributed)
            } else {
                textView.string = notes
                textView.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
            }
        }
        return scrollView
    }

    // MARK: - DMG Download

    /// Downloads the release DMG into ~/Downloads, verifies it against SHA256SUMS.txt and opens it.
    /// Falls back to the release page when the release has no DMG attached.
    public func downloadUpdate(release: GitHubRelease) {
        guard !isDownloading else {
            UpdateDownloadWindowManager.shared.show()
            return
        }
        guard let dmgAsset = release.dmgAsset, let dmgURL = URL(string: dmgAsset.browserDownloadUrl) else {
            openReleasePage(release)
            return
        }

        isDownloading = true
        downloadProgress = 0
        downloadingVersion = release.tagName
        UpdateDownloadWindowManager.shared.show()

        downloadTask = Task {
            do {
                let expectedDigest = try await self.fetchExpectedDigest(release: release, fileName: dmgAsset.name)
                let tempURL = try await UpdateFileDownloader.download(from: dmgURL) { fraction in
                    Task { @MainActor in self.downloadProgress = fraction }
                }
                defer { try? FileManager.default.removeItem(at: tempURL) }

                if let expectedDigest {
                    let actualDigest = try UpdateChecksums.sha256(of: tempURL)
                    guard actualDigest == expectedDigest else {
                        throw UpdateDownloadError.checksumMismatch
                    }
                }

                let destinationURL = try Self.moveToDownloads(tempURL, fileName: dmgAsset.name)
                self.finishDownload()
                let opened = await Self.open(destinationURL)
                self.presentDownloadCompletedAlert(fileURL: destinationURL, opened: opened)
            } catch is CancellationError {
                self.finishDownload()
            } catch {
                self.finishDownload()
                self.presentDownloadFailedAlert(release: release, message: error.localizedDescription)
            }
        }
    }

    public func cancelDownload() {
        downloadTask?.cancel()
    }

    private func finishDownload() {
        downloadTask = nil
        isDownloading = false
        UpdateDownloadWindowManager.shared.close()
    }

    /// Returns the expected digest for `fileName`, or nil when the release has no checksum file.
    private func fetchExpectedDigest(release: GitHubRelease, fileName: String) async throws -> String? {
        guard let checksumAsset = release.checksumAsset, let url = URL(string: checksumAsset.browserDownloadUrl) else {
            return nil
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200, let text = String(data: data, encoding: .utf8) else {
            throw UpdateDownloadError.checksumUnavailable
        }
        guard let digest = UpdateChecksums.parse(text)[fileName] else {
            throw UpdateDownloadError.checksumUnavailable
        }
        return digest
    }

    /// Moves the downloaded file into ~/Downloads without overwriting existing files.
    nonisolated static func moveToDownloads(_ fileURL: URL, fileName: String) throws -> URL {
        let fileManager = FileManager.default
        let downloadsURL = try fileManager.url(for: .downloadsDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let baseName = (fileName as NSString).deletingPathExtension
        let fileExtension = (fileName as NSString).pathExtension

        var destinationURL = downloadsURL.appendingPathComponent(fileName)
        var counter = 1
        while fileManager.fileExists(atPath: destinationURL.path) {
            destinationURL = downloadsURL.appendingPathComponent("\(baseName) (\(counter)).\(fileExtension)")
            counter += 1
        }
        try fileManager.moveItem(at: fileURL, to: destinationURL)
        return destinationURL
    }

    private func openReleasePage(_ release: GitHubRelease) {
        if let targetURL = URL(string: release.htmlUrl) {
            NSWorkspace.shared.open(targetURL)
        }
    }

    private static func open(_ fileURL: URL) async -> Bool {
        await withCheckedContinuation { continuation in
            NSWorkspace.shared.open(fileURL, configuration: NSWorkspace.OpenConfiguration()) { _, error in
                continuation.resume(returning: error == nil)
            }
        }
    }

    private func presentDownloadCompletedAlert(fileURL: URL, opened: Bool) {
        let l10n = ReceiptSettingsStore.shared.l10n
        let alert = NSAlert()
        alert.messageText = l10n.updateDownloadedTitle
        let format = opened ? l10n.updateDownloadedMessage : l10n.updateDownloadedNotOpenedMessage
        alert.informativeText = String(format: format, fileURL.lastPathComponent)
        alert.alertStyle = .informational
        alert.addButton(withTitle: l10n.quitAndInstallButton)
        alert.addButton(withTitle: l10n.laterButton)
        alert.addButton(withTitle: l10n.showInFinderButton)

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            NSApp.terminate(nil)
        case .alertThirdButtonReturn:
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        default:
            break
        }
    }

    private func presentDownloadFailedAlert(release: GitHubRelease, message: String) {
        let l10n = ReceiptSettingsStore.shared.l10n
        let alert = NSAlert()
        alert.messageText = l10n.updateDownloadFailedTitle
        alert.informativeText = "\(l10n.updateDownloadFailedMessage)\n\n(\(message))"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: l10n.openReleasesPage)

        if alert.runModal() == .alertSecondButtonReturn {
            openReleasePage(release)
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

// MARK: - Update Download Errors

public enum UpdateDownloadError: LocalizedError {
    case badResponse(statusCode: Int)
    case checksumUnavailable
    case checksumMismatch

    public var errorDescription: String? {
        switch self {
        case .badResponse(let statusCode):
            return "Download server returned status \(statusCode)"
        case .checksumUnavailable:
            return "SHA256SUMS.txt could not be read for this release"
        case .checksumMismatch:
            return "SHA-256 checksum mismatch; the downloaded file was discarded"
        }
    }
}

// MARK: - File Downloader

/// Downloads a single file with progress reporting and cooperative cancellation.
final class UpdateFileDownloader: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    private let progressHandler: @Sendable (Double) -> Void
    private let lock = NSLock()
    private var continuation: CheckedContinuation<URL, Error>?
    private var task: URLSessionDownloadTask?

    private init(progressHandler: @escaping @Sendable (Double) -> Void) {
        self.progressHandler = progressHandler
    }

    /// Downloads `url` to a temporary file and returns its location. The caller owns the file.
    static func download(from url: URL, progress: @escaping @Sendable (Double) -> Void) async throws -> URL {
        try await UpdateFileDownloader(progressHandler: progress).start(url)
    }

    private func start(_ url: URL) async throws -> URL {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
                let task = session.downloadTask(with: url)
                lock.lock()
                self.continuation = continuation
                self.task = task
                lock.unlock()
                task.resume()
                session.finishTasksAndInvalidate()
                if Task.isCancelled {
                    task.cancel()
                }
            }
        } onCancel: {
            lock.lock()
            let task = self.task
            lock.unlock()
            task?.cancel()
        }
    }

    private func resume(with result: Result<URL, Error>) {
        lock.lock()
        let continuation = self.continuation
        self.continuation = nil
        lock.unlock()
        continuation?.resume(with: result)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        progressHandler(min(1, Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)))
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let httpResponse = downloadTask.response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            resume(with: .failure(UpdateDownloadError.badResponse(statusCode: httpResponse.statusCode)))
            return
        }
        // The system deletes `location` when this method returns, so move it somewhere we own.
        let ownedURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(location.pathExtension.isEmpty ? "download" : location.pathExtension)
        do {
            try FileManager.default.moveItem(at: location, to: ownedURL)
            resume(with: .success(ownedURL))
        } catch {
            resume(with: .failure(error))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error else { return }
        if (error as NSError).code == NSURLErrorCancelled {
            resume(with: .failure(CancellationError()))
        } else {
            resume(with: .failure(error))
        }
    }
}

// MARK: - Download Progress Window

@MainActor
final class UpdateDownloadWindowManager {
    static let shared = UpdateDownloadWindowManager()
    private var window: NSWindow?

    func show() {
        let settings = ReceiptSettingsStore.shared
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 130),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        newWindow.title = settings.l10n.downloadingUpdateTitle
        newWindow.isReleasedWhenClosed = false
        newWindow.center()
        newWindow.contentView = NSHostingView(
            rootView: UpdateDownloadProgressView(checker: GitHubUpdateChecker.shared, settings: settings)
                .preferredColorScheme(settings.theme.colorScheme)
        )
        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func close() {
        window?.close()
        window = nil
    }
}

struct UpdateDownloadProgressView: View {
    @ObservedObject var checker: GitHubUpdateChecker
    @ObservedObject var settings: ReceiptSettingsStore

    var body: some View {
        let l10n = settings.l10n
        VStack(alignment: .leading, spacing: 10) {
            Text("\(l10n.appTitle) \(checker.downloadingVersion)")
                .font(.system(size: 13, weight: .semibold))
            ProgressView(value: checker.downloadProgress)
                .progressViewStyle(.linear)
            HStack {
                Text("\(Int((checker.downloadProgress * 100).rounded()))%")
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundColor(Color(NSColor.secondaryLabelColor))
                Spacer()
                Button(l10n.cancelDownloadButton) {
                    checker.cancelDownload()
                }
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding(20)
        .frame(width: 380)
    }
}
