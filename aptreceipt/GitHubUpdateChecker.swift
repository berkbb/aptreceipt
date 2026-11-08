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
    /// The asset's API URL (`https://api.github.com/repos/<owner>/<repo>/releases/assets/<id>`), used as a
    /// second download source when github.com's release download edge fails.
    public let apiUrl: String?

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadUrl = "browser_download_url"
        case size
        case apiUrl = "url"
    }

    public init(name: String, browserDownloadUrl: String, size: Int? = nil, apiUrl: String? = nil) {
        self.name = name
        self.browserDownloadUrl = browserDownloadUrl
        self.size = size
        self.apiUrl = apiUrl
    }

    /// The API URL of this asset, accepted only when it belongs to the expected repository, so a crafted
    /// release JSON cannot point the fallback download at another host or repository.
    public func apiDownloadURL(repoOwner: String, repoName: String) -> URL? {
        guard let apiUrl, apiUrl.hasPrefix("https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/assets/") else {
            return nil
        }
        return URL(string: apiUrl)
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

    /// The detached Ed25519 signature (`<file>.sig`) for `asset`, if any.
    public func signatureAsset(for asset: GitHubReleaseAsset) -> GitHubReleaseAsset? {
        assets.first { $0.name == asset.name + ".sig" }
    }
}

// MARK: - Ed25519 Update Signatures

public enum UpdateSignature {
    static let publicKeyInfoKey = "AptReceiptUpdatePublicEDKey"

    /// The base64 Ed25519 public key that release DMGs must be signed with.
    public static var bundledPublicKey: String? {
        Bundle.main.object(forInfoDictionaryKey: publicKeyInfoKey) as? String
    }

    /// Returns true when `signatureBase64` is a valid Ed25519 signature of the file for `publicKeyBase64`.
    public static func isValid(fileURL: URL, signatureBase64: String, publicKeyBase64: String) throws -> Bool {
        guard
            let signature = Data(base64Encoded: signatureBase64.trimmingCharacters(in: .whitespacesAndNewlines)),
            let publicKeyData = Data(base64Encoded: publicKeyBase64),
            let publicKey = try? Curve25519.Signing.PublicKey(rawRepresentation: publicKeyData)
        else {
            return false
        }
        let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
        return publicKey.isValidSignature(signature, for: data)
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
    /// Kind of the last failure, so Settings can tell "no public release" apart from real errors.
    @Published public var lastFailure: UpdateCheckFailure? = nil
    @Published public var isDownloading: Bool = false
    @Published public var downloadProgress: Double = 0
    @Published public var downloadingVersion: String = ""

    private var downloadTask: Task<Void, Never>? = nil
    nonisolated static let repoOwner = "berkbb"
    nonisolated static let repoName = "aptreceipt"
    private let releasesURLString = "https://api.github.com/repos/\(GitHubUpdateChecker.repoOwner)/\(GitHubUpdateChecker.repoName)/releases/latest"
    /// Session for the release check and the asset downloads; tests inject one with a stub `URLProtocol`.
    private let session: URLSession

    public var currentAppVersion: String {
        AppInfo.version
    }

    private var userAgent: String {
        "AptReceipt-macOS/\(currentAppVersion)"
    }

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Checks for updates via GitHub Releases API.
    /// - Parameters:
    ///   - userInitiated: If true, will present native alerts / sheets for up-to-date and error states.
    ///   - alertWhenAvailable: Also alert when a newer release exists even if not user-initiated (launch check).
    public func checkForUpdates(userInitiated: Bool = true, alertWhenAvailable: Bool = false) {
        guard !isChecking else { return }
        if isDownloading {
            UpdateDownloadWindowManager.shared.show()
            return
        }

        isChecking = true
        status = .checking
        lastFailure = nil

        guard let url = URL(string: releasesURLString) else {
            isChecking = false
            status = .failed(message: "Invalid releases URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15.0
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        Task {
            do {
                let (data, response) = try await session.data(for: request)
                self.lastCheckedDate = Date()
                self.isChecking = false

                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    let decoder = JSONDecoder()
                    let release = try decoder.decode(GitHubRelease.self, from: data)
                    self.latestRelease = release

                    if SemverCompare.isRemoteNewer(remote: release.tagName, local: self.currentAppVersion) {
                        self.status = .updateAvailable(release: release)
                        self.showUpdateModal = true
                        if userInitiated || alertWhenAvailable {
                            self.presentUpdateAvailableAlert(release: release)
                        }
                    } else {
                        self.status = .upToDate(currentVersion: self.currentAppVersion)
                        if userInitiated {
                            self.presentUpToDateAlert()
                        }
                    }
                } else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    self.reportFailure(UpdateCheckFailure(statusCode: statusCode) ?? .badResponse(statusCode: statusCode), userInitiated: userInitiated)
                }
            } catch {
                self.isChecking = false
                self.reportFailure(UpdateCheckFailure(error: error), userInitiated: userInitiated)
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
                let tempURL = try await self.downloadVerifiedUpdate(release: release, dmgAsset: dmgAsset, dmgURL: dmgURL)
                defer { try? FileManager.default.removeItem(at: tempURL) }

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

    /// Downloads the release DMG to a temporary file and verifies it against `SHA256SUMS.txt` and the
    /// release's Ed25519 signature. Returns the verified file; the caller owns it. A file that fails
    /// verification is deleted before the error is thrown. `publicKey` is the bundled key; tests inject their own.
    func downloadVerifiedUpdate(
        release: GitHubRelease,
        dmgAsset: GitHubReleaseAsset,
        dmgURL: URL,
        publicKey: String? = UpdateSignature.bundledPublicKey
    ) async throws -> URL {
        let expectedDigest = try await fetchExpectedDigest(release: release, fileName: dmgAsset.name)
        let signature = try await fetchSignature(release: release, asset: dmgAsset, publicKey: publicKey)
        let configuration = session.configuration
        let tempURL = try await withAssetFallback(dmgAsset, browserURL: dmgURL) { request in
            try await UpdateFileDownloader.download(request, configuration: configuration) { fraction in
                Task { @MainActor in self.downloadProgress = fraction }
            }
        }

        do {
            if let expectedDigest {
                let actualDigest = try UpdateChecksums.sha256(of: tempURL)
                guard actualDigest == expectedDigest else {
                    throw UpdateDownloadError.checksumMismatch
                }
            }

            if let signature {
                guard try UpdateSignature.isValid(fileURL: tempURL, signatureBase64: signature.value, publicKeyBase64: signature.publicKey) else {
                    throw UpdateDownloadError.signatureInvalid
                }
            }
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
            throw error
        }
        return tempURL
    }

    /// Returns the expected digest for `fileName`, or nil when the release has no checksum file.
    private func fetchExpectedDigest(release: GitHubRelease, fileName: String) async throws -> String? {
        guard let checksumAsset = release.checksumAsset, let url = URL(string: checksumAsset.browserDownloadUrl) else {
            return nil
        }
        let data: Data
        do {
            data = try await fetchAssetData(checksumAsset, browserURL: url)
        } catch UpdateDownloadError.badResponse {
            throw UpdateDownloadError.checksumUnavailable
        }
        guard let text = String(data: data, encoding: .utf8), let digest = UpdateChecksums.parse(text)[fileName] else {
            throw UpdateDownloadError.checksumUnavailable
        }
        return digest
    }

    /// Returns the release's signature for `asset` with `publicKey`, or nil when this build has no
    /// public key. A release without a signature is rejected so it cannot bypass verification.
    private func fetchSignature(release: GitHubRelease, asset: GitHubReleaseAsset, publicKey: String?) async throws -> (value: String, publicKey: String)? {
        guard let publicKey else {
            return nil
        }
        guard let signatureAsset = release.signatureAsset(for: asset), let url = URL(string: signatureAsset.browserDownloadUrl) else {
            throw UpdateDownloadError.signatureMissing
        }
        let data: Data
        do {
            data = try await fetchAssetData(signatureAsset, browserURL: url)
        } catch UpdateDownloadError.badResponse {
            throw UpdateDownloadError.signatureMissing
        }
        guard let text = String(data: data, encoding: .utf8) else {
            throw UpdateDownloadError.signatureMissing
        }
        return (text, publicKey)
    }

    // MARK: - GitHub API Download Fallback

    /// The asset's API URL when it belongs to this app's repository, otherwise nil.
    nonisolated static func acceptedAPIURL(for asset: GitHubReleaseAsset) -> URL? {
        asset.apiDownloadURL(repoOwner: repoOwner, repoName: repoName)
    }

    /// A download is retried through the API after a transport error or an HTTP 5xx from github.com,
    /// as on the 2026-11-08 regional outage. A 404 or any other 4xx is a plain failure, and a cancelled
    /// download stays cancelled.
    nonisolated static func shouldRetryThroughAPI(after error: Error) -> Bool {
        if let urlError = error as? URLError {
            return urlError.code != .cancelled
        }
        if case .badResponse(let statusCode)? = error as? UpdateDownloadError {
            return statusCode >= 500
        }
        return false
    }

    /// Builds the request for a release asset. API requests ask for the file itself (`Accept:
    /// application/octet-stream`); GitHub then redirects to the storage host and URLSession follows.
    private func assetRequest(url: URL, viaAPI: Bool) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        if viaAPI {
            request.setValue("application/octet-stream", forHTTPHeaderField: "Accept")
        }
        return request
    }

    /// Runs `attempt` with the asset's `browser_download_url`; when that fails in a retryable way and the
    /// asset has an API URL in this repository, runs it once more with the API URL.
    private func withAssetFallback<T>(
        _ asset: GitHubReleaseAsset,
        browserURL: URL,
        _ attempt: (URLRequest) async throws -> T
    ) async throws -> T {
        do {
            return try await attempt(assetRequest(url: browserURL, viaAPI: false))
        } catch {
            guard Self.shouldRetryThroughAPI(after: error), !Task.isCancelled, let apiURL = Self.acceptedAPIURL(for: asset) else {
                throw error
            }
            return try await attempt(assetRequest(url: apiURL, viaAPI: true))
        }
    }

    /// Downloads a small release asset (checksums, signature) into memory; non-200 answers throw `badResponse`.
    private func fetchAssetData(_ asset: GitHubReleaseAsset, browserURL: URL) async throws -> Data {
        try await withAssetFallback(asset, browserURL: browserURL) { request in
            let (data, response) = try await session.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            guard statusCode == 200 else {
                throw UpdateDownloadError.badResponse(statusCode: statusCode)
            }
            return data
        }
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

    /// Not every failure is a connection problem, so each kind gets its own explanation.
    private func reportFailure(_ failure: UpdateCheckFailure, userInitiated: Bool) {
        let message = failure.message(ReceiptSettingsStore.shared.l10n)
        lastFailure = failure
        status = .failed(message: message)
        if userInitiated {
            presentErrorAlert(message: message, style: failure == .noPublicRelease ? .informational : .warning)
        }
    }

    private func presentErrorAlert(message: String, style: NSAlert.Style) {
        let l10n = ReceiptSettingsStore.shared.l10n
        let alert = NSAlert()
        alert.messageText = l10n.updateCheckFailedTitle
        alert.informativeText = message
        alert.alertStyle = style
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: l10n.openReleasesPage)

        if alert.runModal() == .alertSecondButtonReturn {
            if let releasesURL = URL(string: "https://github.com/\(Self.repoOwner)/\(Self.repoName)/releases") {
                NSWorkspace.shared.open(releasesURL)
            }
        }
    }
}

// MARK: - Update Check Failures

/// Why a `releases/latest` check failed. Each case maps to its own user-facing message.
public enum UpdateCheckFailure: Error, Equatable {
    /// The device is offline.
    case offline
    /// GitHub did not answer in time.
    case timedOut
    /// The network works but GitHub could not be reached (DNS, TLS, proxy).
    case unreachable
    /// 404: the repository is private or has no public release yet. Not a connection error.
    case noPublicRelease
    /// 403/429: GitHub API rate limit reached.
    case rateLimited
    /// 5xx: temporary problem on GitHub's side.
    case serverError(statusCode: Int)
    /// Any other unexpected HTTP status.
    case badResponse(statusCode: Int)
    /// A response arrived but the release could not be decoded.
    case invalidData
    case other(String)

    /// The failure for an HTTP status; `nil` for 200.
    public init?(statusCode: Int) {
        switch statusCode {
        case 200: return nil
        case 404: self = .noPublicRelease
        case 403, 429: self = .rateLimited
        case 500...599: self = .serverError(statusCode: statusCode)
        default: self = .badResponse(statusCode: statusCode)
        }
    }

    public init(error: Error) {
        if let failure = error as? UpdateCheckFailure {
            self = failure
        } else if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
                self = .offline
            case .timedOut:
                self = .timedOut
            case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed,
                 .secureConnectionFailed, .serverCertificateUntrusted, .serverCertificateHasBadDate,
                 .serverCertificateNotYetValid, .serverCertificateHasUnknownRoot, .clientCertificateRejected:
                self = .unreachable
            default:
                self = .other(urlError.localizedDescription)
            }
        } else if error is DecodingError {
            self = .invalidData
        } else {
            self = .other(error.localizedDescription)
        }
    }

    func message(_ l10n: L10n) -> String {
        switch self {
        case .offline: return l10n.updateErrorOffline
        case .timedOut: return l10n.updateErrorTimedOut
        case .unreachable: return l10n.updateCheckFailedMessage
        case .noPublicRelease: return l10n.updateErrorNoPublicRelease
        case .rateLimited: return l10n.updateErrorRateLimited
        case .serverError(let statusCode): return "\(l10n.updateErrorServer) (HTTP \(statusCode))"
        case .badResponse(let statusCode): return "\(l10n.updateErrorBadResponse) (HTTP \(statusCode))"
        case .invalidData: return l10n.updateErrorInvalidData
        case .other(let detail): return "\(l10n.updateErrorUnexpected)\n\n(\(detail))"
        }
    }
}

// MARK: - Update Download Errors

public enum UpdateDownloadError: LocalizedError {
    case badResponse(statusCode: Int)
    case checksumUnavailable
    case checksumMismatch
    case signatureMissing
    case signatureInvalid

    public var errorDescription: String? {
        switch self {
        case .badResponse(let statusCode):
            return "Download server returned status \(statusCode)"
        case .checksumUnavailable:
            return "SHA256SUMS.txt could not be read for this release"
        case .checksumMismatch:
            return "SHA-256 checksum mismatch; the downloaded file was discarded"
        case .signatureMissing:
            return "This release has no update signature, so it cannot be verified"
        case .signatureInvalid:
            return "Update signature is invalid; the downloaded file was discarded"
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

    /// Downloads `request` to a temporary file and returns its location. The caller owns the file.
    /// `configuration` comes from the checker's session so tests can route the download through a stub protocol.
    static func download(_ request: URLRequest, configuration: URLSessionConfiguration = .default, progress: @escaping @Sendable (Double) -> Void) async throws -> URL {
        try await UpdateFileDownloader(progressHandler: progress).start(request, configuration: configuration)
    }

    private func start(_ request: URLRequest, configuration: URLSessionConfiguration) async throws -> URL {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
                let task = session.downloadTask(with: request)
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
                Text(AppFormat.percent(checker.downloadProgress * 100, l10n: l10n, minimumFractionDigits: 0, maximumFractionDigits: 0))
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
