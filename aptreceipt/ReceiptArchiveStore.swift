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
    static let shared = ReceiptArchiveStore()

    @Published var records: [ReceiptRecord] = []

    private var archiveURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let folder = appSupport.appendingPathComponent("aptreceipt", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("receipts_archive.json")
    }

    init() {
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
        do {
            let data = try JSONEncoder().encode(records)
            try data.write(to: archiveURL, options: .atomic)
        } catch {
            print("ReceiptArchiveStore: save error \(error)")
        }
    }

    func load() {
        guard FileManager.default.fileExists(atPath: archiveURL.path) else { return }
        do {
            let data = try Data(contentsOf: archiveURL)
            records = try JSONDecoder().decode([ReceiptRecord].self, from: data)
        } catch {
            print("ReceiptArchiveStore: load error \(error)")
        }
    }
}
