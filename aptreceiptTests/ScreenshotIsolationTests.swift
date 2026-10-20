import CryptoKit
import PDFKit
import SwiftUI
import Vision
import XCTest
@testable import aptreceipt

/// Screenshot runs keep settings, archive and keys in memory.
final class ScreenshotIsolationTests: XCTestCase {
    // MARK: - 15. Screenshot Run Isolation (sample data never reaches the user's settings or receipts)

    private func makeArchiveDraft() -> ReceiptDraft {
        ReceiptDraft(receiver: "R", issuer: "I", notes: "N", monthYear: "Ekim 2026", apartmentNumber: 5, amount: 1, sequenceNumber: 1, createdDate: "1", showApartmentNumber: true, kind: .income)
    }

    private func modificationDate(_ url: URL) -> Date? {
        (try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date
    }

    @MainActor
    func testScreenshotRunKeepsSettingsAndArchiveInMemory() {
        XCTAssertFalse(ScreenshotMode.isActive, "Tests run without \(ScreenshotMode.argument)")
        XCTAssertNil(ScreenshotMode.archiveFileURL(screenshotRun: true))
        XCTAssertEqual(ScreenshotMode.archiveFileURL(screenshotRun: false), ReceiptArchiveStore.defaultFileURL)
        XCTAssertTrue(ScreenshotMode.settingsDefaults(screenshotRun: true) is InMemoryDefaults)
        XCTAssertTrue(ScreenshotMode.settingsDefaults(screenshotRun: false) === UserDefaults.standard)
    }

    @MainActor
    func testSampleSettingsOfAScreenshotRunNeverReachTheUserDefaults() {
        let standard = UserDefaults.standard
        let keys = [
            ReceiptSettingsStore.Keys.apartmentName,
            ReceiptSettingsStore.Keys.language,
            ReceiptSettingsStore.Keys.currency,
            ReceiptSettingsStore.Keys.seqNumber,
            ReceiptSettingsStore.Keys.owner(1),
            "AppleLanguages",
        ]
        let before = keys.map { standard.object(forKey: $0) as? NSObject }

        let store = ReceiptSettingsStore(defaults: ScreenshotMode.settingsDefaults(screenshotRun: true))
        store.loadSampleDefaults(for: .romanian)
        store.language = .romanian
        store.currency = .romanianLeu
        store.seqNumber = 104

        XCTAssertEqual(store.apartmentName, SampleData.defaults(for: .romanian).apartmentName)
        XCTAssertEqual(keys.map { standard.object(forKey: $0) as? NSObject }, before)
    }

    @MainActor
    func testInMemoryArchiveWritesNoFile() {
        let realArchive = ReceiptArchiveStore.defaultFileURL
        let realArchiveDate = modificationDate(realArchive)

        let store = ReceiptArchiveStore(fileURL: nil)
        store.add(draft: makeArchiveDraft())
        store.replaceRecords([])
        store.add(draft: makeArchiveDraft())

        XCTAssertEqual(store.records.count, 1)
        XCTAssertTrue(ReceiptArchiveStore(fileURL: nil).records.isEmpty)
        XCTAssertEqual(modificationDate(realArchive), realArchiveDate)
    }

    @MainActor
    func testArchiveStoreSavesAndLoadsOnlyItsOwnFile() {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let fileURL = folder.appendingPathComponent("receipts_archive.json")
        XCTAssertNotEqual(fileURL, ReceiptArchiveStore.defaultFileURL)

        let store = ReceiptArchiveStore(fileURL: fileURL)
        XCTAssertTrue(store.records.isEmpty)
        store.add(draft: makeArchiveDraft())

        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertEqual(ReceiptArchiveStore(fileURL: fileURL).records.map(\.id), store.records.map(\.id))
    }
}
