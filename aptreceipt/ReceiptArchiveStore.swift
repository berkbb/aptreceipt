import AppKit
import SwiftUI

// MARK: - Receipt Archive Record & Persistent Store

struct ReceiptRecord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var sequenceNumber: Int
    var kindRaw: String
    var receiver: String
    var issuer: String
    var notes: String
    var monthYear: String
    var apartmentNumber: Int
    var amount: Double
    var currencyRaw: String
    var createdDate: String
    var showApartmentNumber: Bool
    var createdAt: Date = Date()
    var invoiceAttachmentPath: String? = nil
    var isLateFeeApplied: Bool = false
    var lateFeeRate: Double = 0.0
    var lateMonths: Int = 0
    var lateFeeAmount: Double = 0.0
    var baseAmount: Double = 0.0
    var lateFeeFootnote: String? = nil

    var kind: ReceiptKind {
        ReceiptKind(rawValue: kindRaw) ?? .income
    }

    var currency: AppCurrency {
        AppCurrency(rawValue: currencyRaw) ?? .turkishLira
    }

    enum CodingKeys: String, CodingKey {
        case id, sequenceNumber, kindRaw, receiver, issuer, notes, monthYear
        case apartmentNumber, amount, currencyRaw, createdDate, showApartmentNumber
        case createdAt, invoiceAttachmentPath
        case isLateFeeApplied, lateFeeRate, lateMonths, lateFeeAmount, baseAmount
        case lateFeeFootnote
    }

    init(draft: ReceiptDraft) {
        self.id = draft.id
        self.sequenceNumber = draft.sequenceNumber
        self.kindRaw = draft.kind.rawValue
        self.receiver = draft.receiver
        self.issuer = draft.issuer
        self.notes = draft.notes
        self.monthYear = draft.monthYear
        self.apartmentNumber = draft.apartmentNumber
        self.amount = draft.amount
        self.currencyRaw = draft.currency.rawValue
        self.createdDate = draft.createdDate
        self.showApartmentNumber = draft.showApartmentNumber
        self.createdAt = Date()
        self.invoiceAttachmentPath = draft.invoiceAttachmentPath
        self.isLateFeeApplied = draft.isLateFeeApplied
        self.lateFeeRate = draft.lateFeeRate
        self.lateMonths = draft.lateMonths
        self.lateFeeAmount = draft.lateFeeAmount
        self.baseAmount = draft.baseAmount
        self.lateFeeFootnote = draft.lateFeeFootnote
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        sequenceNumber = try container.decode(Int.self, forKey: .sequenceNumber)
        kindRaw = try container.decode(String.self, forKey: .kindRaw)
        receiver = try container.decode(String.self, forKey: .receiver)
        issuer = try container.decode(String.self, forKey: .issuer)
        notes = try container.decode(String.self, forKey: .notes)
        monthYear = try container.decode(String.self, forKey: .monthYear)
        apartmentNumber = try container.decode(Int.self, forKey: .apartmentNumber)
        amount = try container.decode(Double.self, forKey: .amount)
        currencyRaw = try container.decode(String.self, forKey: .currencyRaw)
        createdDate = try container.decode(String.self, forKey: .createdDate)
        showApartmentNumber = try container.decode(Bool.self, forKey: .showApartmentNumber)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        invoiceAttachmentPath = try container.decodeIfPresent(String.self, forKey: .invoiceAttachmentPath)
        isLateFeeApplied = try container.decodeIfPresent(Bool.self, forKey: .isLateFeeApplied) ?? false
        lateFeeRate = try container.decodeIfPresent(Double.self, forKey: .lateFeeRate) ?? 0.0
        lateMonths = try container.decodeIfPresent(Int.self, forKey: .lateMonths) ?? 0
        let decodedLateFee = try container.decodeIfPresent(Double.self, forKey: .lateFeeAmount) ?? 0.0
        lateFeeAmount = decodedLateFee
        baseAmount = try container.decodeIfPresent(Double.self, forKey: .baseAmount) ?? (amount - decodedLateFee)
        lateFeeFootnote = try container.decodeIfPresent(String.self, forKey: .lateFeeFootnote)
    }

    func toDraft() -> ReceiptDraft {
        ReceiptDraft(
            id: id,
            receiver: receiver,
            issuer: issuer,
            notes: notes,
            monthYear: monthYear,
            apartmentNumber: apartmentNumber,
            amount: amount,
            sequenceNumber: sequenceNumber,
            createdDate: createdDate,
            showApartmentNumber: showApartmentNumber,
            kind: kind,
            currency: currency,
            invoiceAttachmentPath: invoiceAttachmentPath,
            isLateFeeApplied: isLateFeeApplied,
            lateFeeRate: lateFeeRate,
            lateMonths: lateMonths,
            lateFeeAmount: lateFeeAmount,
            baseAmount: baseAmount,
            lateFeeFootnote: lateFeeFootnote
        )
    }
}

@MainActor
final class ReceiptArchiveStore: ObservableObject {
    /// The active building's archive. During a screenshot run it lives in memory only (`ScreenshotMode`).
    static let shared = ReceiptArchiveStore(fileURL: BuildingRegistry.archiveFile(
        for: BuildingRegistry.storedActiveID(in: ScreenshotMode.baseDefaults),
        mainArchiveFile: ScreenshotMode.archiveFileURL()
    ))

    @Published var records: [ReceiptRecord] = []

    /// File the archive is saved to; `nil` keeps it in memory only, so nothing is read from or written to disk.
    private(set) var fileURL: URL?

    /// The user's archive file in Application Support.
    nonisolated static var defaultFileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return appSupport
            .appendingPathComponent("aptreceipt", isDirectory: true)
            .appendingPathComponent("receipts_archive.json")
    }

    init(fileURL: URL?) {
        self.fileURL = fileURL
        load()
    }

    /// Switches to another building's archive file and loads its receipts.
    func useFile(_ url: URL?) {
        fileURL = url
        records = []
        load()
    }

    func add(draft: ReceiptDraft) {
        records.removeAll(where: { $0.id == draft.id })
        let record = ReceiptRecord(draft: draft)
        records.insert(record, at: 0)
        save()
    }

    func remove(id: UUID) {
        records.removeAll(where: { $0.id == id })
        save()
    }

    func replaceRecords(_ newRecords: [ReceiptRecord]) {
        records = newRecords
        save()
    }

    func clearAll() {
        records.removeAll()
        save()
    }

    func save() {
        guard let fileURL else { return }
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(records)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("ReceiptArchiveStore: save error \(error)")
        }
    }

    func load() {
        guard let fileURL, FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            records = try JSONDecoder().decode([ReceiptRecord].self, from: data)
        } catch {
            print("ReceiptArchiveStore: load error \(error)")
        }
    }
}
