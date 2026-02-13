import AppKit
import SwiftUI

struct MainScreen: View {
    @StateObject private var settings = ReceiptSettingsStore()

    @State private var selectedApartment = 1
    @State private var receiptDate = Date()
    @State private var issuerName = ""
    @State private var ownerName = ""
    @State private var sequenceNumber = "1"
    @State private var totalAmount = ""
    @State private var notes = ""
    @State private var printApartmentNumber = true
    @State private var receiptKind: ReceiptKind = .income

    @State private var previewDraft: ReceiptDraft?
    @State private var isPresentingSettings = false
    @State private var validationError: ValidationError?

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Apartman Makbuzu")
                    .font(.system(size: 24, weight: .semibold))
                Spacer()
                Button("Tercihler") {
                    isPresentingSettings = true
                }
            }

            VStack(spacing: 12) {
                GroupBox(
                    label: Text("Makbuz Türü")
                ) {
                    Picker("Makbuz Türü", selection: $receiptKind) {
                        ForEach(ReceiptKind.allCases) { kind in
                            Text(kind.title).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                GroupBox(
                    label: Text("Makbuz Bilgileri")
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Picker("Daire No", selection: $selectedApartment) {
                                ForEach(settings.apartmentNumbers, id: \.self) { number in
                                    Text("\(number)").tag(number)
                                }
                            }
                            Toggle("Daire numarasını yazdır", isOn: $printApartmentNumber)
                        }

                        DatePicker("Dönem", selection: $receiptDate, displayedComponents: .date)

                        TextField("Tahsil Eden", text: $issuerName)
                        TextField("Ödeyen", text: $ownerName)
                        TextField("Sıra No", text: $sequenceNumber)
                        TextField("Tutar", text: $totalAmount)
                        TextField("Açıklama", text: $notes)
                    }
                }
            }

            HStack {
                Button("Temizle") {
                    resetForm()
                }

                Spacer()

                Button("Makbuz Oluştur") {
                    createReceipt()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .onAppear {
            resetForm()
        }
        .onChange(of: selectedApartment) { newValue in
            ownerName = settings.owner(for: newValue)
        }
        .sheet(item: $previewDraft) { draft in
            ReceiptPreviewSheet(draft: draft, settings: settings)
        }
        .sheet(isPresented: $isPresentingSettings) {
            SettingsView(settings: settings)
                .frame(width: 640, height: 560)
        }
        .alert(item: $validationError) { issue in
            Alert(
                title: Text("Doğrulama Hatası"),
                message: Text(issue.message),
                dismissButton: .default(Text("Tamam"))
            )
        }
    }

    private func resetForm() {
        selectedApartment = settings.apartmentNumbers.first ?? 1
        receiptDate = Date()
        issuerName = settings.issuer
        ownerName = settings.owner(for: selectedApartment)
        sequenceNumber = String(settings.seqNumber)
        totalAmount = settings.defaultPayment
        notes = ""
        printApartmentNumber = true
        receiptKind = .income
    }

    private func createReceipt() {
        let trimmedIssuer = issuerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedOwner = ownerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSequence = sequenceNumber.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedIssuer.isEmpty else {
            validationError = ValidationError(message: "Tahsil eden bilgisi zorunludur.")
            return
        }
        guard !trimmedOwner.isEmpty else {
            validationError = ValidationError(message: "Ödeyen bilgisi zorunludur.")
            return
        }
        guard let sequence = Int(trimmedSequence), sequence > 0 else {
            validationError = ValidationError(message: "Sıra numarası pozitif tam sayı olmalıdır.")
            return
        }
        guard let amount = parseAmount(totalAmount), amount >= 0 else {
            validationError = ValidationError(message: "Tutar sayısal olmalıdır.")
            return
        }

        previewDraft = ReceiptDraft(
            receiver: trimmedOwner.localizedCapitalized,
            issuer: trimmedIssuer.localizedCapitalized,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "-" : notes,
            monthYear: receiptDate.monthYearString,
            apartmentNumber: selectedApartment,
            amount: amount,
            sequenceNumber: sequence,
            createdDate: Date().dayMonthYearString,
            showApartmentNumber: printApartmentNumber,
            kind: receiptKind
        )

        settings.seqNumber = sequence + 1
        sequenceNumber = String(settings.seqNumber)
    }

    private func parseAmount(_ input: String) -> Double? {
        let normalized = input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }
}

struct ValidationError: Identifiable {
    let id = UUID()
    let message: String
}

enum ReceiptKind: String, CaseIterable, Identifiable {
    case income
    case outcome

    var id: String { rawValue }

    var title: String {
        switch self {
        case .income:
            return "Gelir"
        case .outcome:
            return "Gider"
        }
    }
}

struct ReceiptDraft: Identifiable {
    let id = UUID()
    let receiver: String
    let issuer: String
    let notes: String
    let monthYear: String
    let apartmentNumber: Int
    let amount: Double
    let sequenceNumber: Int
    let createdDate: String
    let showApartmentNumber: Bool
    let kind: ReceiptKind
}

@MainActor
final class ReceiptSettingsStore: ObservableObject {
    @Published var apartmentName: String {
        didSet { defaults.set(apartmentName, forKey: Keys.apartmentName) }
    }
    @Published var issuer: String {
        didSet { defaults.set(issuer, forKey: Keys.issuer) }
    }
    @Published var defaultPayment: String {
        didSet { defaults.set(defaultPayment, forKey: Keys.defaultPayment) }
    }
    @Published var flatCount: Int {
        didSet { defaults.set(String(flatCount), forKey: Keys.flatCount) }
    }
    @Published var seqNumber: Int {
        didSet { defaults.set(String(seqNumber), forKey: Keys.seqNumber) }
    }
    @Published var signatureData: Data? {
        didSet {
            if let signatureData {
                defaults.set(signatureData, forKey: Keys.signature)
            } else {
                defaults.removeObject(forKey: Keys.signature)
            }
        }
    }

    private let defaults = UserDefaults.standard

    init() {
        apartmentName = defaults.string(forKey: Keys.apartmentName) ?? ""
        issuer = defaults.string(forKey: Keys.issuer) ?? ""
        defaultPayment = defaults.string(forKey: Keys.defaultPayment) ?? ""
        flatCount = max(1, ReceiptSettingsStore.readInt(defaults, key: Keys.flatCount, fallback: 1))
        seqNumber = max(1, ReceiptSettingsStore.readInt(defaults, key: Keys.seqNumber, fallback: 1))
        signatureData = defaults.data(forKey: Keys.signature)
    }

    var apartmentNumbers: [Int] {
        Array(1...max(flatCount, 1))
    }

    var signatureImage: NSImage? {
        guard let signatureData else { return nil }
        return NSImage(data: signatureData)
    }

    func owner(for apartmentNumber: Int) -> String {
        defaults.string(forKey: Keys.owner(apartmentNumber))?.localizedCapitalized ?? ""
    }

    func saveOwner(_ owner: String, apartmentNumber: Int) {
        defaults.set(owner, forKey: Keys.owner(apartmentNumber))
        objectWillChange.send()
    }

    func clearSignature() {
        signatureData = nil
    }

    func importSignature() {
        let panel = NSOpenPanel()
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedFileTypes = ["png", "jpg", "jpeg"]

        if panel.runModal() == .OK, let url = panel.url {
            do {
                signatureData = try Data(contentsOf: url)
            } catch {
                signatureData = nil
            }
        }
    }

    private static func readInt(_ defaults: UserDefaults, key: String, fallback: Int) -> Int {
        if let value = defaults.object(forKey: key) as? Int {
            return value
        }
        if let value = defaults.string(forKey: key), let intValue = Int(value) {
            return intValue
        }
        return fallback
    }

    enum Keys {
        static let apartmentName = "aptname"
        static let issuer = "issuer"
        static let defaultPayment = "defaultpay"
        static let flatCount = "flatcount"
        static let seqNumber = "seqNumber"
        static let signature = "usersign"

        static func owner(_ number: Int) -> String {
            "homeowner_\(number)"
        }
    }
}

extension Date {
    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }

    var dayMonthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("MMMM d, yyyy")
        return formatter.string(from: self)
    }
}
