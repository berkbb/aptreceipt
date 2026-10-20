import CryptoKit
import PDFKit
import SwiftUI
import Vision
import XCTest
@testable import aptreceipt

/// Receipt QR codes, verification keys, sealed codes, the Verify Receipt window logic and recovery codes.
final class VerificationTests: XCTestCase {
    // MARK: - 16. Receipt QR Code (must scan in the exported image and PDF)

    private func decodedQRCodes(in image: CGImage) -> [String] {
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]
        try? VNImageRequestHandler(cgImage: image).perform([request])
        return (request.results ?? []).compactMap(\.payloadStringValue)
    }

    /// Renders `view` through the JPEG and PDF export paths and checks that the QR code reads back as `qrContent`.
    @MainActor
    private func assertQRCodeScans(_ view: ReceiptDocumentView, _ label: String) throws {
        let expected = view.qrContent
        let document = view.frame(width: 595, height: 842).environment(\.colorScheme, .light)

        // JPEG export path: rendered at 2x.
        let imageRenderer = ImageRenderer(content: document)
        imageRenderer.scale = 2
        imageRenderer.proposedSize = ProposedViewSize(width: 595, height: 842)
        let image = try XCTUnwrap(imageRenderer.cgImage)
        XCTAssertEqual(decodedQRCodes(in: image), [expected], "\(label): JPEG export")

        // PDF export path, then viewed or scanned at 150 dpi.
        let pdfRenderer = ImageRenderer(content: document)
        pdfRenderer.proposedSize = ProposedViewSize(width: 595, height: 842)
        let pdfData = NSMutableData()
        var box = CGRect(x: 0, y: 0, width: 595, height: 842)
        let consumer = try XCTUnwrap(CGDataConsumer(data: pdfData as CFMutableData))
        let pdfContext = try XCTUnwrap(CGContext(consumer: consumer, mediaBox: &box, nil))
        pdfContext.beginPDFPage(nil)
        pdfRenderer.render { _, draw in draw(pdfContext) }
        pdfContext.endPDFPage()
        pdfContext.closePDF()
        let pdf = try XCTUnwrap(PDFDocument(data: pdfData as Data))
        let page = try XCTUnwrap(pdf.page(at: 0))
        let thumbnail = page.thumbnail(of: NSSize(width: 1240, height: 1754), for: .mediaBox)
        let scan = try XCTUnwrap(thumbnail.cgImage(forProposedRect: nil, context: nil, hints: nil))
        XCTAssertEqual(decodedQRCodes(in: scan), [expected], "\(label): PDF export")
    }

    @MainActor
    func testReceiptQRCodeScansInExportedImageAndPDF() throws {
        // Worst case: every name over the cap, Turkish two-byte letters, a late fee, large amounts.
        let keys = ReceiptVerificationKeyStore(fileURL: nil)
        let longName = String(repeating: "Şükrü İğdır Öztürkoğlu ", count: 4)
        for language in [AppLanguage.turkish, .english, .romanian] {
            for kind in ReceiptKind.allCases {
                let draft = ReceiptDraft(receiver: longName, issuer: longName, notes: "N", monthYear: "Septembrie 2026", apartmentNumber: 128, amount: 1234567.89, sequenceNumber: 99999, createdDate: "30 septembrie 2026", showApartmentNumber: true, kind: kind, currency: .romanianLeu, isLateFeeApplied: true, lateFeeRate: 12.5, lateMonths: 11, lateFeeAmount: 123456.78, baseAmount: 1111111.11)
                let view = ReceiptDocumentView(draft: draft, apartmentName: longName, signatureImage: nil, l10n: L10n(language), verificationKeys: keys)
                try assertQRCodeScans(view, "\(language) \(kind)")
                let width = try XCTUnwrap(QRCodeGenerator.generate(from: view.qrContent, pointsPerModule: 72 / 25.4 * 0.5)?.size.width)
                XCTAssertLessThanOrEqual(width, 130, "\(language) \(kind): QR too wide for the receipt footer")
            }
        }
    }

    @MainActor
    func testQRTextListsTheReceiptInItsLanguageWithAValidCode() throws {
        let keys = ReceiptVerificationKeyStore(fileURL: nil)
        let draft = ReceiptDraft(receiver: "Ayşe Yılmaz", issuer: "Mehmet Şahin", notes: "Ekim 2026 aidatı", monthYear: "Ekim 2026", apartmentNumber: 12, amount: 12750.5, sequenceNumber: 1042, createdDate: "20.10.2026", showApartmentNumber: true, kind: .income, currency: .turkishLira, isLateFeeApplied: true, lateFeeRate: 2.5, lateMonths: 3, lateFeeAmount: 750.5, baseAmount: 12000)
        let view = ReceiptDocumentView(draft: draft, apartmentName: "Yıldız Sitesi Yönetimi", signatureImage: nil, l10n: L10n(.turkish), verificationKeys: keys)
        var lines = legacyQRText(view, keys: keys, language: .turkish).components(separatedBy: "\n")
        let codeLine = try XCTUnwrap(lines.popLast())
        XCTAssertEqual(lines, view.qrLines)
        XCTAssertEqual(lines, [
            "AptReceipt",
            "YILDIZ SİTESİ YÖNETİMİ",
            "Tahsilat Makbuzu · TAH-1042",
            "Düzenleme Tarihi: 20.10.2026",
            "Dönem: Ekim 2026",
            "Sakin / Muhatap: Ayşe Yılmaz",
            "Daire 12",
            "Aidat Ana Para: ₺12.000,00",
            "Gecikme Tazminatı: +₺750,50",
            "GENEL TOPLAM: ₺12.750,50",
            "Yönetici: Mehmet Şahin",
        ])
        let prefix = "Doğrulama kodu: "
        XCTAssertTrue(codeLine.hasPrefix(prefix), codeLine)
        let code = String(codeLine.dropFirst(prefix.count))
        XCTAssertEqual(ReceiptVerificationCode.matchingKeyIndex(code: code, text: lines.joined(separator: "\n"), keys: keys.allKeys), 0)
        XCTAssertNil(ReceiptVerificationCode.matchingKeyIndex(code: code, text: lines.joined(separator: "\n"), keys: ReceiptVerificationKeyStore(fileURL: nil).allKeys))

        // A management expense in English: payee label, no flat or late fee lines.
        let expense = ReceiptDraft(receiver: "Apex Elevator Services", issuer: "John Doe", notes: "N", monthYear: "October 2026", apartmentNumber: 0, amount: 3450, sequenceNumber: 105, createdDate: "19 October 2026", showApartmentNumber: false, kind: .managementExpense, currency: .usDollar)
        let english = ReceiptDocumentView(draft: expense, apartmentName: "Sunshine Residence", signatureImage: nil, l10n: L10n(.english), verificationKeys: keys).qrLines
        XCTAssertEqual(english, [
            "AptReceipt",
            "SUNSHINE RESIDENCE",
            "Operating Expenditure Voucher · MGT-0105",
            "Issue Date: 19 October 2026",
            "Period: October 2026",
            "Payee / Vendor: Apex Elevator Services",
            "GRAND TOTAL: $3,450.00",
            "Manager: John Doe",
        ])

        // Names over the cap end with an ellipsis.
        let long = ReceiptDraft(receiver: String(repeating: "a", count: 60), issuer: "I", notes: "N", monthYear: "October 2026", apartmentNumber: 1, amount: 1, sequenceNumber: 1, createdDate: "1", showApartmentNumber: false, kind: .income, currency: .usDollar)
        let longLines = ReceiptDocumentView(draft: long, apartmentName: "B", signatureImage: nil, l10n: L10n(.english), verificationKeys: keys).qrLines
        XCTAssertTrue(longLines.contains("Resident / Payer: " + String(repeating: "a", count: ReceiptDocumentView.qrNameLimit - 1) + "…"), "\(longLines)")
    }

    // MARK: - 18. Receipt Verification Codes and Keys (offline QR plan, phase 1)

    private static let codeKey = SymmetricKey(data: Data(repeating: 7, count: 32))
    private static let codeText = "AptReceipt\nYILDIZ SİTESİ YÖNETİMİ\nTahsilat Makbuzu · TAH-1042\nToplam: ₺12.750,50"

    @MainActor private func rawKeys(_ store: ReceiptVerificationKeyStore) -> [Data] { store.exportedKeys() }

    func testVerificationCodeIsPinnedAndIgnoresLayoutOnly() {
        let code = ReceiptVerificationCode.code(for: Self.codeText, key: Self.codeKey)
        // Printed receipts keep their codes forever: this value must never change (computed independently).
        XCTAssertEqual(code, "MYT3-6FAA-81BK-6T3W")

        let relaidOut = "\r\n  " + Self.codeText.decomposedStringWithCanonicalMapping.replacingOccurrences(of: "\n", with: "  \r\n\r\n") + "\n"
        XCTAssertEqual(ReceiptVerificationCode.code(for: relaidOut, key: Self.codeKey), code)

        XCTAssertNotEqual(ReceiptVerificationCode.code(for: Self.codeText.replacingOccurrences(of: "12.750,50", with: "12.750,51"), key: Self.codeKey), code)
        XCTAssertNotEqual(ReceiptVerificationCode.code(for: Self.codeText.replacingOccurrences(of: "TAH-1042", with: "TAH-1043"), key: Self.codeKey), code)
        XCTAssertNotEqual(ReceiptVerificationCode.code(for: Self.codeText, key: SymmetricKey(data: Data(repeating: 8, count: 32))), code)
    }

    func testVerificationCodeAcceptsTypedVariantsAndFindsTheKey() {
        let code = ReceiptVerificationCode.code(for: Self.codeText, key: Self.codeKey)
        let typed = code.replacingOccurrences(of: "-", with: " ").lowercased()
            .replacingOccurrences(of: "0", with: "o").replacingOccurrences(of: "1", with: "l")
        XCTAssertEqual(ReceiptVerificationCode.canonicalCode(typed), code)
        XCTAssertNil(ReceiptVerificationCode.canonicalCode("MYT3-6FAA-81BK"))
        XCTAssertNil(ReceiptVerificationCode.canonicalCode("MYT3-6FAA-81BK-6T3U"))

        let otherKey = SymmetricKey(data: Data(repeating: 9, count: 32))
        XCTAssertEqual(ReceiptVerificationCode.matchingKeyIndex(code: typed, text: Self.codeText, keys: [otherKey, Self.codeKey]), 1)
        XCTAssertNil(ReceiptVerificationCode.matchingKeyIndex(code: code, text: Self.codeText + "\nX", keys: [otherKey, Self.codeKey]))
        XCTAssertNil(ReceiptVerificationCode.matchingKeyIndex(code: code, text: Self.codeText, keys: [otherKey]))
    }

    @MainActor
    func testVerificationKeysStayInMemoryOrInTheirOwnFile() throws {
        XCTAssertNil(ScreenshotMode.verificationKeyFileURL(screenshotRun: true))
        XCTAssertEqual(ScreenshotMode.verificationKeyFileURL(screenshotRun: false), ReceiptVerificationKeyStore.defaultFileURL)

        let memory = ReceiptVerificationKeyStore(fileURL: nil)
        XCTAssertEqual(rawKeys(memory), rawKeys(memory))
        XCTAssertEqual(rawKeys(memory).count, 1)
        XCTAssertNotEqual(rawKeys(ReceiptVerificationKeyStore(fileURL: nil)), rawKeys(memory))

        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let fileURL = folder.appendingPathComponent("receipt-verification-keys")
        XCTAssertNotEqual(fileURL, ReceiptVerificationKeyStore.defaultFileURL)

        let first = ReceiptVerificationKeyStore(fileURL: fileURL)
        let key = try XCTUnwrap(rawKeys(first).first)
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        XCTAssertEqual(attributes[.size] as? Int, 32)
        XCTAssertEqual((attributes[.posixPermissions] as? NSNumber)?.intValue, 0o600)
        XCTAssertEqual(rawKeys(ReceiptVerificationKeyStore(fileURL: fileURL)), [key])

        let restoredKey = Data(repeating: 3, count: 32)
        first.restore([restoredKey, Data(repeating: 1, count: 5)])
        first.restore([restoredKey])
        XCTAssertEqual(rawKeys(first), [restoredKey, key])
        XCTAssertEqual(rawKeys(ReceiptVerificationKeyStore(fileURL: fileURL)), [restoredKey, key])

        // An unreadable file is moved aside, never overwritten.
        try Data([1, 2, 3, 4, 5]).write(to: fileURL)
        XCTAssertEqual(rawKeys(ReceiptVerificationKeyStore(fileURL: fileURL)).count, 1)
        let leftovers = try FileManager.default.contentsOfDirectory(atPath: folder.path)
        XCTAssertTrue(leftovers.contains { $0.hasPrefix("receipt-verification-keys.unreadable-") }, "\(leftovers)")
    }

    @MainActor
    func testSystemBackupCarriesTheVerificationKeys() throws {
        let sourceKeys = ReceiptVerificationKeyStore(fileURL: nil)
        let source = ReceiptSettingsStore(defaults: InMemoryDefaults())
        let data = try XCTUnwrap(source.exportSystemBackup(archive: ReceiptArchiveStore(fileURL: nil), verificationKeys: sourceKeys))
        let package = try JSONDecoder().decode(SystemBackupPackage.self, from: data)
        XCTAssertEqual(package.version, "2.2")
        XCTAssertEqual(package.receiptVerificationKeys, rawKeys(sourceKeys).map { $0.base64EncodedString() })

        let targetKeys = ReceiptVerificationKeyStore(fileURL: nil)
        let ownKeys = rawKeys(targetKeys)
        try ReceiptSettingsStore(defaults: InMemoryDefaults()).importSystemBackup(from: data, archive: ReceiptArchiveStore(fileURL: nil), verificationKeys: targetKeys)
        XCTAssertEqual(rawKeys(targetKeys), rawKeys(sourceKeys) + ownKeys)

        // A backup from before 3.6 has no keys and leaves them as they are.
        var older = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        older["receiptVerificationKeys"] = nil
        let olderKeys = ReceiptVerificationKeyStore(fileURL: nil)
        let olderOwn = rawKeys(olderKeys)
        try ReceiptSettingsStore(defaults: InMemoryDefaults()).importSystemBackup(from: JSONSerialization.data(withJSONObject: older), archive: ReceiptArchiveStore(fileURL: nil), verificationKeys: olderKeys)
        XCTAssertEqual(rawKeys(olderKeys), olderOwn)
    }

    // MARK: - 19. Verify Receipt (offline QR plan, phase 3)

    private static let verifyDraft = ReceiptDraft(receiver: "Ayşe Yılmaz", issuer: "Mehmet Şahin", notes: "Ekim 2026 aidatı", monthYear: "Ekim 2026", apartmentNumber: 12, amount: 12750.5, sequenceNumber: 1042, createdDate: "20.10.2026", showApartmentNumber: true, kind: .income, currency: .turkishLira, isLateFeeApplied: true, lateFeeRate: 2.5, lateMonths: 3, lateFeeAmount: 750.5, baseAmount: 12000)

    /// A receipt QR text as AptReceipt 3.6.0 printed it: the labeled lines, then the verification code.
    @MainActor
    private func legacyQRText(_ view: ReceiptDocumentView, keys: ReceiptVerificationKeyStore, language: AppLanguage = .turkish) -> String {
        let body = view.qrLines.joined(separator: "\n")
        return body + "\n" + L10n(language).qrVerificationCodeLabel + ": " + ReceiptVerificationCode.code(for: body, key: keys.currentKey)
    }

    @MainActor
    private func verifyReceiptView(_ draft: ReceiptDraft = verifyDraft, keys: ReceiptVerificationKeyStore) -> ReceiptDocumentView {
        ReceiptDocumentView(draft: draft, apartmentName: "Yıldız Sitesi Yönetimi", signatureImage: nil, l10n: L10n(.turkish), verificationKeys: keys)
    }

    func testReceiptSerialPrefixesRoundTrip() {
        for language in [AppLanguage.turkish, .english, .romanian] {
            for kind in ReceiptKind.allCases {
                let serial = ReceiptSerial.formatted(kind: kind, language: language, sequenceNumber: 42)
                let parsed = ReceiptSerial.parse("Document · \(serial)")
                XCTAssertEqual(parsed?.kind, kind, serial)
                XCTAssertEqual(parsed?.language, language, serial)
                XCTAssertEqual(parsed?.sequenceNumber, 42, serial)
            }
        }
        XCTAssertEqual(ReceiptSerial.formatted(kind: .income, language: .turkish, sequenceNumber: 1042), "TAH-1042")
        XCTAssertNil(ReceiptSerial.parse("No receipt number here"))
    }

    @MainActor
    func testTextQRCodesFrom360AreStillVerified() throws {
        let keys = ReceiptVerificationKeyStore(fileURL: nil)
        let text = legacyQRText(verifyReceiptView(keys: keys), keys: keys)

        let scan = try XCTUnwrap(ScannedReceiptVerification(scannedText: text.replacingOccurrences(of: "\n", with: "\r\n"), keys: keys.allKeys))
        XCTAssertEqual(scan.status, .genuine(keyIndex: 0))
        XCTAssertEqual(scan.kind, .income)
        XCTAssertEqual(scan.language, .turkish)
        XCTAssertEqual(scan.sequenceNumber, 1042)
        XCTAssertEqual(scan.lines, Array(text.components(separatedBy: "\n").dropLast()))
        XCTAssertEqual(scan.code, String(text.suffix(19)))

        let altered = text.replacingOccurrences(of: "₺12.750,50", with: "₺13.750,50")
        XCTAssertEqual(ScannedReceiptVerification(scannedText: altered, keys: keys.allKeys)?.status, .notVerified)
        XCTAssertEqual(ScannedReceiptVerification(scannedText: text, keys: ReceiptVerificationKeyStore(fileURL: nil).allKeys)?.status, .notVerified)
        let withoutCode = text.components(separatedBy: "\n").dropLast().joined(separator: "\n")
        XCTAssertEqual(ScannedReceiptVerification(scannedText: withoutCode, keys: keys.allKeys)?.status, .notVerified)

        // A receipt made before restoring another Mac's backup is still genuine, with this Mac's older key.
        let restored = ReceiptVerificationKeyStore(fileURL: nil)
        let earlier = legacyQRText(verifyReceiptView(keys: restored), keys: restored)
        restored.restore([Data(repeating: 4, count: 32)])
        XCTAssertEqual(ScannedReceiptVerification(scannedText: earlier, keys: restored.allKeys)?.status, .genuine(keyIndex: 1))

        // A name shaped like a code is never read as the code.
        let codeLike = ReceiptDraft(receiver: "Ayşe Yılmaz", issuer: "Abcd Efgh Ijkl Mnop", notes: "N", monthYear: "Ekim 2026", apartmentNumber: 12, amount: 100, sequenceNumber: 1043, createdDate: "20.10.2026", showApartmentNumber: true, kind: .income, currency: .turkishLira)
        let codeLikeLines = verifyReceiptView(codeLike, keys: keys).qrLines
        let codeLikeScan = try XCTUnwrap(ScannedReceiptVerification(scannedText: codeLikeLines.joined(separator: "\n"), keys: keys.allKeys))
        XCTAssertNil(codeLikeScan.code)
        XCTAssertEqual(codeLikeScan.lines.last, "Yönetici: Abcd Efgh Ijkl Mnop")
    }

    func testOlderAndForeignQRTextsAreRecognized() throws {
        let older = try XCTUnwrap(ScannedReceiptVerification(scannedText: "AptReceipt | SUNSHINE RESIDENCE | REC-0104 | 19 October 2026 | Jane Smith | $1,750.00 | John Doe", keys: []))
        XCTAssertEqual(older.status, .olderWithoutCode)
        XCTAssertEqual(older.lines, ["SUNSHINE RESIDENCE", "REC-0104", "19 October 2026", "Jane Smith", "$1,750.00", "John Doe"])
        XCTAssertEqual(older.kind, .income)
        XCTAssertEqual(older.language, .english)
        XCTAssertEqual(older.sequenceNumber, 104)
        XCTAssertNil(older.code)

        XCTAssertNil(ScannedReceiptVerification(scannedText: "https://example.com", keys: []))
        XCTAssertNil(ScannedReceiptVerification(scannedText: "AptReceipt", keys: []))
        XCTAssertNil(ReceiptQRReader.receiptText(in: ["hello", "https://example.com"]))
    }

    @MainActor
    func testScannedReceiptIsComparedWithTheArchive() throws {
        let keys = ReceiptVerificationKeyStore(fileURL: nil)
        let scan = try XCTUnwrap(ScannedReceiptVerification(scannedText: verifyReceiptView(keys: keys).qrContent, keys: keys.allKeys))
        let record = ReceiptRecord(draft: Self.verifyDraft)
        var changed = record
        changed.amount = 13750.5
        var otherNumber = record
        otherNumber.sequenceNumber = 7

        XCTAssertEqual(ReceiptArchiveComparison.compare(scan, with: [record], apartmentName: "Yıldız Sitesi Yönetimi"), .matches)
        XCTAssertEqual(ReceiptArchiveComparison.compare(scan, with: [changed], apartmentName: "Yıldız Sitesi Yönetimi"), .differs(lines: ["GENEL TOPLAM: ₺12.750,50"]))
        XCTAssertEqual(ReceiptArchiveComparison.compare(scan, with: [changed, record], apartmentName: "Yıldız Sitesi Yönetimi"), .matches)
        XCTAssertEqual(ReceiptArchiveComparison.compare(scan, with: [otherNumber], apartmentName: "Yıldız Sitesi Yönetimi"), .missing)
        XCTAssertEqual(ReceiptArchiveComparison.compare(scan, with: [], apartmentName: "Yıldız Sitesi Yönetimi"), .missing)
        XCTAssertEqual(ReceiptArchiveComparison.compare(scan, with: [record], apartmentName: "Başka Site"), .differs(lines: ["YILDIZ SİTESİ YÖNETİMİ"]))
    }

    @MainActor
    func testQRReaderFindsTheReceiptInAnExportedPDFAndImage() throws {
        let keys = ReceiptVerificationKeyStore(fileURL: nil)
        let view = verifyReceiptView(keys: keys)
        let document = view.frame(width: 595, height: 842).environment(\.colorScheme, .light)
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }

        let pdfURL = folder.appendingPathComponent("receipt.pdf")
        let pdfRenderer = ImageRenderer(content: document)
        pdfRenderer.proposedSize = ProposedViewSize(width: 595, height: 842)
        var box = CGRect(x: 0, y: 0, width: 595, height: 842)
        let pdfContext = try XCTUnwrap(CGContext(consumer: try XCTUnwrap(CGDataConsumer(url: pdfURL as CFURL)), mediaBox: &box, nil))
        pdfContext.beginPDFPage(nil)
        pdfRenderer.render { _, draw in draw(pdfContext) }
        pdfContext.endPDFPage()
        pdfContext.closePDF()
        XCTAssertEqual(ReceiptQRReader.receiptText(in: ReceiptQRReader.texts(in: pdfURL)), view.qrContent)

        let pngURL = folder.appendingPathComponent("receipt.png")
        let imageRenderer = ImageRenderer(content: document)
        imageRenderer.scale = 2
        let bitmap = NSBitmapImageRep(cgImage: try XCTUnwrap(imageRenderer.cgImage))
        try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: pngURL)
        XCTAssertEqual(ReceiptQRReader.receiptText(in: ReceiptQRReader.texts(in: pngURL)), view.qrContent)
    }

    // MARK: - 20. Sealed QR Code (the camera offers to copy it; nothing personal is readable)

    @MainActor
    func testQRContentIsOnlyTheSealedCode() throws {
        let keys = ReceiptVerificationKeyStore(fileURL: nil)
        let content = verifyReceiptView(keys: keys).qrContent
        XCTAssertTrue(content.hasPrefix(ReceiptQRBlock.prefix), content)
        XCTAssertEqual(ReceiptQRBlock.find(in: content), content)
        XCTAssertNil(content.range(of: #"[^0-9A-Z.]"#, options: .regularExpression), content)
        for secret in ["Ayşe", "Yılmaz", "Mehmet", "Şahin", "12.750", "750,50", "YILDIZ", "Ekim", "TAH-1042"] {
            XCTAssertFalse(content.contains(secret), secret)
        }
    }

    @MainActor
    func testSealedCodeOpensOnlyWithThisInstallationAndUnchanged() throws {
        let keys = ReceiptVerificationKeyStore(fileURL: nil)
        let view = verifyReceiptView(keys: keys)
        let code = view.qrContent

        // The scanned code, and the code copied into a message with text around it.
        let scanned = try XCTUnwrap(ScannedReceiptVerification(scannedText: code, keys: keys.allKeys))
        XCTAssertEqual(scanned.status, ScannedReceiptVerification.Status.genuine(keyIndex: 0))
        XCTAssertEqual(scanned.lines, view.qrLines)
        XCTAssertEqual(scanned.kind, ReceiptKind.income)
        XCTAssertEqual(scanned.language, AppLanguage.turkish)
        XCTAssertEqual(scanned.sequenceNumber, 1042)
        XCTAssertNil(scanned.code)
        let message = "Merhaba, Ekim makbuzu (TAH-1042):\r\n\r\n" + code + "\r\n\r\nİyi günler"
        XCTAssertEqual(ScannedReceiptVerification(scannedText: message, keys: keys.allKeys)?.lines, view.qrLines)

        // Another installation's key: nothing can be shown but the stamp.
        let foreign = try XCTUnwrap(ScannedReceiptVerification(scannedText: code, keys: ReceiptVerificationKeyStore(fileURL: nil).allKeys))
        XCTAssertEqual(foreign.status, ScannedReceiptVerification.Status.notVerified)
        XCTAssertEqual(foreign.lines, ["AptReceipt"])
        XCTAssertNil(foreign.sequenceNumber)

        // A changed code, or a message that names another receipt number.
        var characters = Array(code)
        let index = characters.count - 10
        characters[index] = characters[index] == "A" ? "B" : "A"
        XCTAssertEqual(ScannedReceiptVerification(scannedText: String(characters), keys: keys.allKeys)?.status, .notVerified)
        XCTAssertEqual(ScannedReceiptVerification(scannedText: "AptReceipt · TAH-1043\n" + code, keys: keys.allKeys)?.status, .notVerified)

        // Sealed before restoring another Mac's backup: this Mac's older key still opens it.
        let restored = ReceiptVerificationKeyStore(fileURL: nil)
        let earlier = verifyReceiptView(keys: restored).qrContent
        restored.restore([Data(repeating: 4, count: 32)])
        XCTAssertEqual(ScannedReceiptVerification(scannedText: earlier, keys: restored.allKeys)?.status, .genuine(keyIndex: 1))

        XCTAssertEqual(ReceiptQRReader.receiptText(in: ["hello", code]), code)
    }

    func testSealedBlockFormatIsPinned() throws {
        let key = SymmetricKey(data: Data(repeating: 7, count: 32))
        let block = ReceiptQRBlock(draft: Self.verifyDraft, building: "Yıldız Sitesi Yönetimi", language: .turkish)
        // Printed receipts keep their blocks forever: this value and its decoding must never change.
        let pinned = "AR1.A7WVSXM67JFP0NCFDYXWTBKWMZY14SHQX2AVVAREA0YEJG7SP69P3H7003MD7YR3CTHQ5ZQMSV8B6JH3PBV3NTSJ1H9VMWE8A238RGJSHEZC9PJAVT2VJCHADCPJ4SJASNG7WN4G00QATXKFZZTK42DYQCVAQPZ1WVD0ARSVGX94WJFMR1E964WPF7B2SGKA5ZR9C"
        XCTAssertEqual(block.sealed(with: key), pinned)
        XCTAssertEqual(block.sealed(with: key), block.sealed(with: key))
        let opened = try XCTUnwrap(ReceiptQRBlock.open(pinned, keys: [key]))
        XCTAssertEqual(opened.block, block)
        XCTAssertEqual(opened.block.printedLines, [
            "AptReceipt",
            "YILDIZ SİTESİ YÖNETİMİ",
            "Tahsilat Makbuzu · TAH-1042",
            "Düzenleme Tarihi: 20.10.2026",
            "Dönem: Ekim 2026",
            "Sakin / Muhatap: Ayşe Yılmaz",
            "Daire 12",
            "Aidat Ana Para: ₺12.000,00",
            "Gecikme Tazminatı: +₺750,50",
            "GENEL TOPLAM: ₺12.750,50",
            "Yönetici: Mehmet Şahin",
        ])
    }

    // MARK: - 24. Recovery Code for the Verification Keys

    func testRecoveryCodeFormatIsPinned() {
        // A written-down code must restore forever: value computed independently (Python hashlib).
        let key = Data(repeating: 7, count: 32)
        let code = ReceiptRecoveryCode.encode(key)
        XCTAssertEqual(code, "0W3G-E1R7-0W3G-E1R7-0W3G-E1R7-0W3G-E1R7-0W3G-E1R7-0W3G-E1R7-0W3M-QC3F")
        XCTAssertEqual(ReceiptRecoveryCode.decode(code), key)
        // Typed loosely: lower case, spaces instead of dashes, O for 0.
        let typed = code.lowercased().replacingOccurrences(of: "-", with: " ").replacingOccurrences(of: "0", with: "o")
        XCTAssertEqual(ReceiptRecoveryCode.decode(typed), key)
    }

    func testRecoveryCodeRejectsEveryMistypedCharacterAndWrongLength() {
        let code = ReceiptRecoveryCode.encode(Data((0..<32).map { UInt8($0 * 7 % 256) }))
        let characters = Array(code)
        let alphabet = Array("0123456789ABCDEFGHJKMNPQRSTVWXYZ")
        for index in characters.indices where characters[index] != "-" {
            for replacement in alphabet where replacement != characters[index] {
                var mistyped = characters
                mistyped[index] = replacement
                XCTAssertNil(ReceiptRecoveryCode.decode(String(mistyped)), "position \(index) → \(replacement)")
            }
        }
        XCTAssertNil(ReceiptRecoveryCode.decode(String(code.dropLast())))
        XCTAssertNil(ReceiptRecoveryCode.decode(code + "0"))
        XCTAssertNil(ReceiptRecoveryCode.decode(""))
        XCTAssertNil(ReceiptRecoveryCode.decode("U" + code.dropFirst()), "U is not in the alphabet")
    }

    @MainActor
    func testRecoveryCodeRestoresTheKeyAndKeepsTheExistingOnes() throws {
        let oldMac = ReceiptVerificationKeyStore(fileURL: nil)
        let receipt = verifyReceiptView(keys: oldMac).qrContent
        let code = oldMac.recoveryCode()

        let newMac = ReceiptVerificationKeyStore(fileURL: nil)
        let newMacKey = try XCTUnwrap(newMac.exportedKeys().first)
        XCTAssertFalse(newMac.restore(recoveryCode: "1234-5678"))
        XCTAssertEqual(newMac.exportedKeys(), [newMacKey], "a rejected code changes nothing")
        XCTAssertTrue(newMac.restore(recoveryCode: code))
        XCTAssertEqual(newMac.exportedKeys(), oldMac.exportedKeys() + [newMacKey])
        XCTAssertEqual(ScannedReceiptVerification(scannedText: receipt, keys: newMac.allKeys)?.status, .genuine(keyIndex: 0))
    }
}
