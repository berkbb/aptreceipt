import AppKit
import PDFKit
import SwiftUI
import UniformTypeIdentifiers
import Vision

// MARK: - QR Reader

/// Reads QR codes from receipt photos, screenshots and PDFs with Vision, on this Mac.
enum ReceiptQRReader {
    static func texts(in image: CGImage) -> [String] {
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]
        try? VNImageRequestHandler(cgImage: image).perform([request])
        return (request.results ?? []).compactMap(\.payloadStringValue)
    }

    /// QR texts in an image file, or in the first pages of a PDF rendered at about 200 dpi.
    static func texts(in url: URL) -> [String] {
        if url.pathExtension.lowercased() == "pdf" {
            guard let document = PDFDocument(url: url) else { return [] }
            return (0..<min(document.pageCount, 5)).flatMap { index -> [String] in
                guard let page = document.page(at: index) else { return [] }
                let bounds = page.bounds(for: .mediaBox)
                let scale: CGFloat = 200 / 72
                let image = page.thumbnail(of: NSSize(width: bounds.width * scale, height: bounds.height * scale), for: .mediaBox)
                return image.cgImage(forProposedRect: nil, context: nil, hints: nil).map(texts(in:)) ?? []
            }
        }
        guard let image = NSImage(contentsOf: url)?.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return [] }
        return texts(in: image)
    }

    /// The first text that is an AptReceipt receipt QR code.
    static func receiptText(in texts: [String]) -> String? {
        texts.first { ScannedReceiptVerification(scannedText: $0, keys: []) != nil }
    }
}

// MARK: - Window Manager

@MainActor
final class ReceiptVerificationWindowManager: NSObject, NSWindowDelegate {
    static let shared = ReceiptVerificationWindowManager()
    private var window: NSWindow?

    func show(settings: ReceiptSettingsStore? = nil) {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let settings = settings ?? ReceiptSettingsStore.shared
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: ReceiptVerificationView.size.width, height: ReceiptVerificationView.size.height),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = settings.l10n.verifyReceiptTitle
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentView = NSHostingView(
            rootView: ReceiptVerificationView(settings: settings)
                .preferredColorScheme(settings.theme.colorScheme)
        )
        window.center()
        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}

// MARK: - Verify Receipt Window

/// Checks a receipt offline: drop or choose a photo or PDF, or paste the QR text; the receipt is shown as a
/// POS-style slip with its verification result and how it compares with the archive.
struct ReceiptVerificationView: View {
    static let size = CGSize(width: 780, height: 640)

    @ObservedObject var settings: ReceiptSettingsStore
    /// `nil` uses the app's archive and keys; tests pass in-memory ones.
    var archiveStore: ReceiptArchiveStore? = nil
    var verificationKeys: ReceiptVerificationKeyStore? = nil

    @State private var qrText = ""
    @State private var scan: ScannedReceiptVerification?
    @State private var comparison: ReceiptArchiveComparison?
    @State private var message: String?
    @State private var isDropTargeted = false
    @State private var isReading = false

    private var l10n: L10n { settings.l10n }

    /// `initialText` opens the window with that QR text already verified (screenshots).
    init(settings: ReceiptSettingsStore, archiveStore: ReceiptArchiveStore? = nil, verificationKeys: ReceiptVerificationKeyStore? = nil, initialText: String = "") {
        _settings = ObservedObject(wrappedValue: settings)
        self.archiveStore = archiveStore
        self.verificationKeys = verificationKeys
        guard !initialText.isEmpty,
              let scan = ScannedReceiptVerification(scannedText: initialText, keys: (verificationKeys ?? .shared).allKeys) else { return }
        _qrText = State(initialValue: initialText)
        _scan = State(initialValue: scan)
        _comparison = State(initialValue: ReceiptArchiveComparison.compare(scan, with: (archiveStore ?? .shared).records, apartmentName: settings.apartmentName))
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            inputPanel
                .frame(width: 320)
                .padding(20)
            Divider()
            resultPanel
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.underPageBackgroundColor))
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: Input

    private var inputPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.accentColor)
                    .font(.title2)
                Text(l10n.verifyReceiptTitle)
                    .font(.title2.weight(.bold))
            }
            Text(l10n.verifyReceiptSubtitle)
                .font(.callout)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            dropZone

            HStack(spacing: 8) {
                Button {
                    chooseFile()
                } label: {
                    Label(l10n.verifyChooseFile, systemImage: "folder")
                }
                Button {
                    pasteFromClipboard()
                } label: {
                    Label(l10n.verifyPaste, systemImage: "doc.on.clipboard")
                }
            }
            .controlSize(.regular)

            Text(l10n.verifyTextLabel)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            TextEditor(text: $qrText)
                .font(.system(size: 11, design: .monospaced))
                .frame(height: 200)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.3)))

            HStack {
                if let message {
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Button(l10n.verifyButton) {
                    verify(qrText)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(qrText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            Spacer(minLength: 0)
        }
    }

    private var dropZone: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isDropTargeted ? Color.accentColor.opacity(0.08) : Color.clear)
            )
            .frame(height: 130)
            .overlay(
                VStack(spacing: 8) {
                    if isReading {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "doc.viewfinder")
                            .font(.system(size: 30))
                            .foregroundColor(.secondary)
                    }
                    Text(l10n.verifyDropHint)
                        .font(.callout.weight(.medium))
                        .foregroundColor(.secondary)
                }
            )
            .onDrop(of: [UTType.fileURL], isTargeted: $isDropTargeted) { providers in
                guard let provider = providers.first else { return false }
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    guard let url else { return }
                    Task { @MainActor in read(url) }
                }
                return true
            }
    }

    // MARK: Result

    @ViewBuilder
    private var resultPanel: some View {
        if let scan {
            ScrollView {
                VStack(spacing: 18) {
                    ReceiptSlipView(scan: scan, l10n: l10n)
                    resultDetails(scan)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
            }
        } else {
            VStack(spacing: 10) {
                Image(systemName: "receipt")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary.opacity(0.6))
                Text(l10n.verifyEmptyState)
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func resultDetails(_ scan: ScannedReceiptVerification) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label {
                Text(statusDetail(scan.status))
            } icon: {
                Image(systemName: ReceiptSlipView.statusIcon(scan.status))
                    .foregroundColor(ReceiptSlipView.statusColor(scan.status))
            }
            if case .genuine(let keyIndex) = scan.status, keyIndex > 0 {
                Text(l10n.verifyStatusRestoredKey)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if let comparison {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(archiveText(comparison, scan: scan))
                        if case .differs(let lines) = comparison {
                            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                                Text(line)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                } icon: {
                    Image(systemName: "archivebox")
                        .foregroundColor(.secondary)
                }
            }
        }
        .font(.callout)
        .frame(width: ReceiptSlipView.width, alignment: .leading)
    }

    private func statusDetail(_ status: ScannedReceiptVerification.Status) -> String {
        switch status {
        case .genuine: return l10n.verifyStatusGenuineDetail
        case .notVerified: return l10n.verifyStatusNotVerifiedDetail
        case .olderWithoutCode: return l10n.verifyStatusOlderDetail
        }
    }

    private func archiveText(_ comparison: ReceiptArchiveComparison, scan: ScannedReceiptVerification) -> String {
        switch comparison {
        case .matches: return scan.status == .olderWithoutCode ? l10n.verifyArchiveFound : l10n.verifyArchiveMatches
        case .differs: return l10n.verifyArchiveDiffers
        case .missing: return l10n.verifyArchiveMissing
        }
    }

    // MARK: Actions

    private func verify(_ text: String) {
        qrText = text
        guard let result = ScannedReceiptVerification(scannedText: text, keys: (verificationKeys ?? .shared).allKeys) else {
            scan = nil
            comparison = nil
            message = l10n.verifyNoReceiptFound
            return
        }
        message = nil
        scan = result
        comparison = ReceiptArchiveComparison.compare(result, with: (archiveStore ?? .shared).records, apartmentName: settings.apartmentName)
    }

    private func read(_ url: URL) {
        isReading = true
        Task {
            let texts = await Task.detached(priority: .userInitiated) { ReceiptQRReader.texts(in: url) }.value
            isReading = false
            show(texts)
        }
    }

    private func show(_ texts: [String]) {
        if let text = ReceiptQRReader.receiptText(in: texts) {
            verify(text)
        } else {
            scan = nil
            comparison = nil
            message = l10n.verifyNoReceiptFound
        }
    }

    private func chooseFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf, .image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        read(url)
    }

    private func pasteFromClipboard() {
        let pasteboard = NSPasteboard.general
        if let text = pasteboard.string(forType: .string), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            verify(text)
        } else if let image = NSImage(pasteboard: pasteboard)?.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            show(ReceiptQRReader.texts(in: image))
        } else {
            message = l10n.verifyNoReceiptFound
        }
    }
}

// MARK: - POS Slip

/// A scanned receipt drawn like a thermal POS printout: monospaced lines on a paper strip with a torn edge.
struct ReceiptSlipView: View {
    static let width: CGFloat = 300

    let scan: ScannedReceiptVerification
    let l10n: L10n

    private let ink = Color(white: 0.1)
    private let faded = Color(white: 0.45)

    /// Lines centered at the top: brand, building and receipt type with number (older receipts: title and number).
    private var headerCount: Int {
        min(scan.lines.count, scan.status == .olderWithoutCode ? 2 : 3)
    }

    /// The grand total label in the receipt's own language, to print that line in bold.
    private var totalLabel: String {
        L10n(scan.language ?? .english).grandTotal.trimmingCharacters(in: CharacterSet(charactersIn: ": "))
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 7) {
                stamp
                    .padding(.bottom, 6)
                ForEach(0..<headerCount, id: \.self) { index in
                    Text(scan.lines[index])
                        .font(.system(size: index == 0 ? 10 : 12, weight: index == 1 ? .bold : .regular, design: .monospaced))
                        .foregroundColor(index == 0 ? faded : ink)
                        .multilineTextAlignment(.center)
                }
                dashedRule
                ForEach(Array(scan.lines.dropFirst(headerCount).enumerated()), id: \.offset) { _, line in
                    if isTotal(line) {
                        dashedRule
                    }
                    row(line)
                }
                if let code = scan.code {
                    dashedRule
                    HStack {
                        Text(l10n.qrVerificationCodeLabel)
                            .foregroundColor(faded)
                        Spacer(minLength: 8)
                        Text(code)
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 10, design: .monospaced))
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
            .padding(.bottom, 14)
            .background(Color.white)

            TornEdge()
                .fill(Color.white)
                .frame(height: 8)
        }
        .frame(width: Self.width)
        .foregroundColor(ink)
        .compositingGroup()
        .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
    }

    private var stamp: some View {
        Text(statusTitle)
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .tracking(1)
            .foregroundColor(Self.statusColor(scan.status))
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Self.statusColor(scan.status), lineWidth: 2.5)
            )
            .rotationEffect(.degrees(-4))
    }

    private var statusTitle: String {
        switch scan.status {
        case .genuine: return l10n.verifyStatusGenuine
        case .notVerified: return l10n.verifyStatusNotVerified
        case .olderWithoutCode: return l10n.verifyStatusOlder
        }
    }

    static func statusColor(_ status: ScannedReceiptVerification.Status) -> Color {
        switch status {
        case .genuine: return Color(red: 0.10, green: 0.55, blue: 0.25)
        case .notVerified: return Color(red: 0.80, green: 0.15, blue: 0.15)
        case .olderWithoutCode: return Color(white: 0.45)
        }
    }

    static func statusIcon(_ status: ScannedReceiptVerification.Status) -> String {
        switch status {
        case .genuine: return "checkmark.seal.fill"
        case .notVerified: return "xmark.octagon.fill"
        case .olderWithoutCode: return "questionmark.circle.fill"
        }
    }

    private func isTotal(_ line: String) -> Bool {
        line.hasPrefix(totalLabel)
    }

    @ViewBuilder
    private func row(_ line: String) -> some View {
        let bold = isTotal(line)
        if let separator = line.range(of: ": ") {
            HStack(alignment: .firstTextBaseline) {
                Text(line[..<separator.lowerBound])
                    .foregroundColor(bold ? ink : faded)
                Spacer(minLength: 8)
                Text(line[separator.upperBound...])
                    .multilineTextAlignment(.trailing)
            }
            .font(.system(size: bold ? 13 : 11, weight: bold ? .bold : .regular, design: .monospaced))
        } else {
            Text(line)
                .font(.system(size: 11, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var dashedRule: some View {
        HorizontalRule()
            .stroke(faded.opacity(0.7), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            .frame(height: 1)
            .padding(.vertical, 3)
    }
}

private struct HorizontalRule: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        }
    }
}

/// The torn bottom edge of the paper strip: small triangles pointing down.
private struct TornEdge: Shape {
    func path(in rect: CGRect) -> Path {
        let tooth: CGFloat = 10
        let count = max(1, Int(rect.width / tooth))
        let step = rect.width / CGFloat(count)
        return Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            for index in 0..<count {
                let x = rect.minX + CGFloat(index) * step
                path.addLine(to: CGPoint(x: x + step / 2, y: rect.maxY))
                path.addLine(to: CGPoint(x: x + step, y: rect.minY))
            }
            path.closeSubpath()
        }
    }
}
