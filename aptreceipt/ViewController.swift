import AppKit
import SwiftUI

// MARK: - Main Screen

struct MainScreen: View {
    @StateObject private var settings = ReceiptSettingsStore()
    @StateObject private var viewModel = MainScreenViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            headerBar
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Main Content Area: Left Form + Right Live Preview
            HSplitView {
                // Left Form
                ScrollView {
                    VStack(spacing: 18) {
                        receiptTypeSection
                        apartmentAndPeriodSection
                        partiesSection
                        financialSection
                        actionButtons
                    }
                    .padding(24)
                }
                .frame(minWidth: 460, idealWidth: 540)

                // Right Live Preview
                VStack(spacing: 16) {
                    HStack {
                        Label("Canlı Önizleme", systemImage: "eye.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Baskı Görünümü")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    ScrollView {
                        LiveReceiptPreview(
                            kind: viewModel.receiptKind,
                            apartmentName: settings.apartmentName,
                            apartmentNumber: viewModel.selectedApartment,
                            showApartmentNumber: viewModel.printApartmentNumber,
                            period: viewModel.receiptDate.monthYearString,
                            issuer: viewModel.issuerName.isEmpty ? "—" : viewModel.issuerName,
                            receiver: viewModel.ownerName.isEmpty ? "—" : viewModel.ownerName,
                            amountString: viewModel.totalAmount,
                            sequenceNumber: viewModel.sequenceNumber,
                            notes: viewModel.notes,
                            signatureImage: settings.signatureImage
                        )
                        .padding(20)
                    }
                }
                .frame(minWidth: 420, idealWidth: 460)
                .background(Color(NSColor.underPageBackgroundColor).opacity(0.6))
            }
        }
        .onAppear {
            viewModel.syncWithSettings(settings)
        }
        .sheet(item: $viewModel.previewDraft) { draft in
            ReceiptPreviewSheet(draft: draft, settings: settings)
        }
        .sheet(isPresented: $viewModel.isPresentingSettings) {
            SettingsView(settings: settings)
                .frame(width: 660, height: 560)
        }
        .alert(item: $viewModel.validationError) { issue in
            Alert(
                title: Text("Doğrulama Hatası"),
                message: Text(issue.message),
                dismissButton: .default(Text("Tamam"))
            )
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                Image(systemName: "building.2.crop.circle.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("Apartman Makbuzu")
                        .font(.system(size: 20, weight: .bold))
                    if !settings.apartmentName.isEmpty {
                        Text(settings.apartmentName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                Text("Gelir ve gider makbuzlarınızı kolayca yönetin ve dışa aktarın")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                viewModel.isPresentingSettings = true
            } label: {
                Label("Tercihler", systemImage: "gearshape.fill")
                    .padding(.horizontal, 4)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
        }
    }

    // MARK: - Sections

    private var receiptTypeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Makbuz Türü", systemImage: "doc.plaintext.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)

            Picker("Makbuz Türü", selection: $viewModel.receiptKind) {
                ForEach(ReceiptKind.allCases) { kind in
                    HStack {
                        Image(systemName: kind.iconName)
                        Text(kind.title)
                    }
                    .tag(kind)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }

    private var apartmentAndPeriodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Daire ve Dönem", systemImage: "calendar.badge.clock")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Daire Numarası")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("", selection: $viewModel.selectedApartment) {
                        ForEach(settings.apartmentNumbers, id: \.self) { number in
                            Text("Daire \(number)").tag(number)
                        }
                    }
                    .labelsHidden()
                    .onChange(of: viewModel.selectedApartment) { newValue in
                        viewModel.updateApartment(newValue, settings: settings)
                    }
                }

                Spacer()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Dönem")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $viewModel.receiptDate, displayedComponents: .date)
                        .labelsHidden()
                }
            }

            Divider()

            Toggle(isOn: $viewModel.printApartmentNumber) {
                Label("Daire numarasını makbuz üzerine yazdır", systemImage: "checkmark.seal")
                    .font(.callout)
            }
            .toggleStyle(.checkbox)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }

    private var partiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Taraflar", systemImage: "person.2.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Tahsil Eden (Yönetici / Yetkili)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    Image(systemName: "person.badge.shield.checkmark.fill")
                        .foregroundColor(.secondary)
                    TextField("Örn: Ahmet Yılmaz", text: $viewModel.issuerName)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(NSColor.textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Ödeyen (Daire Sakini / Muhatap)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Kayıtlı Sakini Getir") {
                        viewModel.ownerName = settings.owner(for: viewModel.selectedApartment)
                    }
                    .buttonStyle(.link)
                    .font(.caption2)
                }

                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.secondary)
                    TextField("Örn: Mehmet Demir", text: $viewModel.ownerName)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(NSColor.textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }

    private var financialSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Mali Detaylar ve Açıklama", systemImage: "banknote.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)

            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tutar (₺)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        Text("₺")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $viewModel.totalAmount)
                            .textFieldStyle(.plain)
                    }
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Sıra No")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        Image(systemName: "number.square.fill")
                            .foregroundColor(.secondary)
                        TextField("1", text: $viewModel.sequenceNumber)
                            .textFieldStyle(.plain)
                    }
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Açıklama / Notlar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(alignment: .top) {
                    Image(systemName: "text.alignleft")
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                    TextField("Örn: 2026 Ekim ayı bina aidatı ve ortak alan gideri", text: $viewModel.notes)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(NSColor.textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(role: .destructive) {
                viewModel.resetForm(settings: settings)
            } label: {
                Label("Formu Temizle", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Spacer()

            Button {
                viewModel.createReceipt(settings: settings)
            } label: {
                Label("Makbuz Oluştur & Önizle", systemImage: "doc.badge.plus")
                    .padding(.horizontal, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.top, 6)
    }
}

// MARK: - Live Preview Widget

struct LiveReceiptPreview: View {
    let kind: ReceiptKind
    let apartmentName: String
    let apartmentNumber: Int
    let showApartmentNumber: Bool
    let period: String
    let issuer: String
    let receiver: String
    let amountString: String
    let sequenceNumber: String
    let notes: String
    let signatureImage: NSImage?

    private var formattedAmount: String {
        let normalized = amountString.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        if let val = Double(normalized) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = Locale(identifier: "tr_TR")
            return formatter.string(from: NSNumber(value: val)) ?? "₺\(amountString)"
        }
        return "₺ 0,00"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(apartmentName.isEmpty ? "APARTMAN YÖNETİMİ" : apartmentName.uppercased())
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                    Text(kind == .income ? "TAHSİLAT MAKBUZU" : "GİDER MAKBUZU")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(kind == .income ? .green : .orange)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Sıra No: #\(sequenceNumber)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                    Text(period)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Info rows
            VStack(spacing: 8) {
                previewRow(label: "Ödeyen / Sakin", value: receiver)
                if showApartmentNumber {
                    previewRow(label: "Daire No", value: "Daire \(apartmentNumber)")
                }
                previewRow(label: "Tahsil Eden", value: issuer)
                previewRow(label: "Tarih", value: Date().dayMonthYearString)
            }

            // Amount Highlight Box
            HStack {
                Text("Ödenen Tutar:")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text(formattedAmount)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.accentColor)
            }
            .padding(12)
            .background(Color.accentColor.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            // Notes
            if !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Açıklama:")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text(notes)
                        .font(.system(size: 11))
                        .foregroundColor(.primary)
                        .lineLimit(3)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // Signature area
            if let signature = signatureImage {
                HStack {
                    Spacer()
                    VStack(alignment: .center, spacing: 4) {
                        Image(nsImage: signature)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 44)
                        Text("Yetkili İmzası")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(NSColor.textBackgroundColor))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
        )
    }

    private func previewRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(width: 110, alignment: .leading)
            Text(value)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - View Model

@MainActor
final class MainScreenViewModel: ObservableObject {
    @Published var selectedApartment: Int = 1
    @Published var receiptDate: Date = Date()
    @Published var issuerName: String = ""
    @Published var ownerName: String = ""
    @Published var sequenceNumber: String = "1"
    @Published var totalAmount: String = ""
    @Published var notes: String = ""
    @Published var printApartmentNumber: Bool = true
    @Published var receiptKind: ReceiptKind = .income

    @Published var previewDraft: ReceiptDraft?
    @Published var isPresentingSettings: Bool = false
    @Published var validationError: ValidationError?

    func syncWithSettings(_ settings: ReceiptSettingsStore) {
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

    func updateApartment(_ number: Int, settings: ReceiptSettingsStore) {
        selectedApartment = number
        ownerName = settings.owner(for: number)
    }

    func resetForm(settings: ReceiptSettingsStore) {
        syncWithSettings(settings)
    }

    func createReceipt(settings: ReceiptSettingsStore) {
        let trimmedIssuer = issuerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedOwner = ownerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSequence = sequenceNumber.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedIssuer.isEmpty else {
            validationError = ValidationError(message: "Tahsil eden (yetkili) bilgisi zorunludur.")
            return
        }
        guard !trimmedOwner.isEmpty else {
            validationError = ValidationError(message: "Ödeyen (muhatap) bilgisi zorunludur.")
            return
        }
        guard let sequence = Int(trimmedSequence), sequence > 0 else {
            validationError = ValidationError(message: "Sıra numarası pozitif bir tam sayı olmalıdır.")
            return
        }
        guard let amount = parseAmount(totalAmount), amount >= 0 else {
            validationError = ValidationError(message: "Tutar geçerli bir sayı olmalıdır.")
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

// MARK: - Models

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
            return "Gelir (Tahsilat)"
        case .outcome:
            return "Gider (Tediye)"
        }
    }

    var iconName: String {
        switch self {
        case .income:
            return "arrow.down.left.circle.fill"
        case .outcome:
            return "arrow.up.right.circle.fill"
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

// MARK: - Store

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
        panel.allowedContentTypes = [.png, .jpeg]

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

// MARK: - Extensions

extension Date {
    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }

    var dayMonthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.setLocalizedDateFormatFromTemplate("d MMMM yyyy")
        return formatter.string(from: self)
    }
}
