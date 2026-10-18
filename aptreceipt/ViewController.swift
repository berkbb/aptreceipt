import AppKit
import SwiftUI

// MARK: - Language & Theme Enums

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case turkish = "tr"
    case english = "en"

    var id: String { rawValue }

    func title(l10n: L10n) -> String {
        switch self {
        case .system:
            return l10n.langSystem
        case .turkish:
            return "Türkçe"
        case .english:
            return "English"
        }
    }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var id: String { rawValue }

    func title(l10n: L10n) -> String {
        switch self {
        case .system:
            return l10n.themeSystem
        case .light:
            return l10n.themeLight
        case .dark:
            return l10n.themeDark
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - 1-to-1 Localization Store (L10n)

struct L10n {
    let language: AppLanguage

    init(_ language: AppLanguage = .system) {
        self.language = language
    }

    var isTurkish: Bool {
        if language == .system {
            let preferred = Locale.preferredLanguages.first?.prefix(2) ?? "tr"
            return preferred == "tr"
        }
        return language == .turkish
    }

    var locale: Locale {
        isTurkish ? Locale(identifier: "tr_TR") : Locale(identifier: "en_US")
    }

    // App Header & Base
    var appTitle: String { isTurkish ? "Apartman Makbuzu" : "Apartment Receipt" }
    var appSubtitle: String { isTurkish ? "Gelir ve gider makbuzlarınızı kolayca yönetin ve dışa aktarın" : "Easily manage and export apartment income and expense receipts" }
    var preferences: String { isTurkish ? "Tercihler" : "Preferences" }
    var settingsTitle: String { isTurkish ? "Tercihler & Ayarlar" : "Preferences & Settings" }
    var settingsSubtitle: String { isTurkish ? "Apartman bilgileri, dil, tema ve imzanızı düzenleyin" : "Configure building details, language, theme, and signature" }

    // Receipt Type
    var receiptType: String { isTurkish ? "Makbuz Türü" : "Receipt Type" }
    var incomeTitle: String { isTurkish ? "Gelir (Tahsilat)" : "Income (Collection)" }
    var outcomeTitle: String { isTurkish ? "Gider (Tediye)" : "Expense (Payment)" }
    var incomeBadge: String { isTurkish ? "TAHSİLAT MAKBUZU" : "INCOME RECEIPT" }
    var outcomeBadge: String { isTurkish ? "GİDER / TEDİYE MAKBUZU" : "EXPENSE RECEIPT" }

    // Flat & Period
    var flatAndPeriod: String { isTurkish ? "Daire ve Dönem" : "Apartment & Period" }
    var flatNumber: String { isTurkish ? "Daire Numarası" : "Apartment Number" }
    var flatPrefix: String { isTurkish ? "Daire" : "Flat" }
    var period: String { isTurkish ? "Dönem" : "Period" }
    var printFlatNumber: String { isTurkish ? "Daire numarasını makbuz üzerine yazdır" : "Print apartment number on receipt" }

    // Parties
    var parties: String { isTurkish ? "Taraflar" : "Parties" }
    var issuerLabel: String { isTurkish ? "Tahsil Eden (Yönetici / Yetkili)" : "Collector (Manager / Authorized)" }
    var issuerPlaceholder: String { isTurkish ? "Örn: Ahmet Yılmaz" : "e.g. John Doe" }
    var receiverLabel: String { isTurkish ? "Ödeyen (Daire Sakini / Muhatap)" : "Payer (Resident / Recipient)" }
    var receiverPlaceholder: String { isTurkish ? "Örn: Mehmet Demir" : "e.g. Jane Smith" }
    var fetchSavedResident: String { isTurkish ? "Kayıtlı Sakini Getir" : "Load Saved Resident" }

    // Financial & Notes
    var financialDetails: String { isTurkish ? "Mali Detaylar ve Açıklama" : "Financial Details & Description" }
    var amount: String { isTurkish ? "Tutar (₺)" : "Amount (₺)" }
    var sequenceNo: String { isTurkish ? "Sıra No" : "Sequence No" }
    var notesLabel: String { isTurkish ? "Açıklama / Notlar" : "Description / Notes" }
    var notesPlaceholder: String { isTurkish ? "Örn: 2026 Ekim ayı aidatı ve ortak alan gideri" : "e.g. October 2026 monthly dues and maintenance fee" }

    // Actions
    var clearForm: String { isTurkish ? "Formu Temizle" : "Clear Form" }
    var createReceipt: String { isTurkish ? "Makbuz Oluştur & Önizle" : "Create & Preview Receipt" }

    // Live Preview & Document
    var livePreview: String { isTurkish ? "Canlı Önizleme" : "Live Preview" }
    var printViewBadge: String { isTurkish ? "Baskı Görünümü" : "Print View" }
    var totalPaid: String { isTurkish ? "Ödenen Tutar:" : "Total Paid:" }
    var totalCollected: String { isTurkish ? "Tahsil Edilen Tutar:" : "Collected Amount:" }
    var descriptionHeader: String { isTurkish ? "Açıklama:" : "Description:" }
    var receiptNo: String { isTurkish ? "Makbuz No:" : "Receipt No:" }
    var issueDate: String { isTurkish ? "Düzenleme Tarihi:" : "Issue Date:" }
    var dateLabel: String { isTurkish ? "Tarih" : "Date" }
    var authorizedSignature: String { isTurkish ? "Yetkili İmzası" : "Authorized Signature" }
    var electronicDisclaimer: String { isTurkish ? "Bu belge apartman yönetimi kayıtları uyarınca elektronik ortamda tanzim edilmiştir." : "This document has been issued electronically pursuant to building management records." }
    var defaultBuildingName: String { isTurkish ? "APARTMAN YÖNETİMİ" : "BUILDING MANAGEMENT" }

    // Sheet Actions
    var previewTitle: String { isTurkish ? "Makbuz Önizleme" : "Receipt Preview" }
    var previewSubtitle: String { isTurkish ? "Oluşturulan makbuzu inceleyin ve cihazınıza kaydedin" : "Review the generated receipt and save to your device" }
    var close: String { isTurkish ? "Kapat" : "Close" }
    var cancel: String { isTurkish ? "İptal" : "Cancel" }
    var saveAndClose: String { isTurkish ? "Kaydet ve Kapat" : "Save & Close" }
    var saveAsJPEG: String { isTurkish ? "JPEG Olarak Kaydet" : "Save as JPEG" }
    var saveSuccess: String { isTurkish ? "Makbuz başarıyla kaydedildi!" : "Receipt saved successfully!" }

    // Settings Tabs
    var tabBuilding: String { isTurkish ? "Apartman" : "Building" }
    var tabResidents: String { isTurkish ? "Sakinler" : "Residents" }
    var tabAppearance: String { isTurkish ? "Görünüm & Dil" : "Appearance & Language" }
    var tabSignature: String { isTurkish ? "İmza" : "Signature" }
    var tabAbout: String { isTurkish ? "Hakkında" : "About" }

    // Settings Form Fields
    var buildingDetails: String { isTurkish ? "Apartman Bilgileri" : "Building Information" }
    var buildingName: String { isTurkish ? "Apartman Adı:" : "Building Name:" }
    var defaultManager: String { isTurkish ? "Varsayılan Yönetici (Tahsil Eden):" : "Default Manager (Collector):" }
    var totalFlats: String { isTurkish ? "Toplam Daire Sayısı:" : "Total Number of Flats:" }
    var financialSettings: String { isTurkish ? "Mali & Makbuz Değerleri" : "Financial & Receipt Defaults" }
    var defaultDues: String { isTurkish ? "Varsayılan Aidat Tutarı (₺):" : "Default Dues Amount (₺):" }
    var nextReceiptNo: String { isTurkish ? "Sıradaki Makbuz No:" : "Next Receipt No:" }

    // Appearance & Language Tab
    var appearanceSection: String { isTurkish ? "Görünüm ve Tema" : "Appearance & Theme" }
    var themeSelection: String { isTurkish ? "Tema Seçimi:" : "Theme Selection:" }
    var themeSystem: String { isTurkish ? "Sistem (Otomatik)" : "System (Automatic)" }
    var themeLight: String { isTurkish ? "Açık Tema" : "Light Theme" }
    var themeDark: String { isTurkish ? "Koyu Tema" : "Dark Theme" }

    var languageSection: String { isTurkish ? "Uygulama Dili" : "Application Language" }
    var languageSelection: String { isTurkish ? "Dil Seçimi:" : "Language Selection:" }
    var langSystem: String { isTurkish ? "Sistem Dili (Otomatik)" : "System Default (Automatic)" }

    // Residents Directory
    var residentsDirectoryTitle: String { isTurkish ? "Daire Sakinleri Rehberi" : "Residents Directory" }
    var residentsDirectoryDesc: String { isTurkish ? "Her daire için kayıtlı ev sahibi veya kiracı ismini belirleyin. Makbuz oluştururken daire seçildiğinde otomatik doldurulacaktır." : "Assign resident or owner names for each flat. Selecting a flat will automatically fill in their name." }
    var flatLabel: String { isTurkish ? "Daire:" : "Flat:" }
    var residentNamePlaceholder: String { isTurkish ? "Daire Sakini Adı Soyadı" : "Resident Full Name" }
    var saveButton: String { isTurkish ? "Kaydet" : "Save" }
    var residentSavedFeedback: String { isTurkish ? "sakini başarıyla kaydedildi." : "resident saved successfully." }

    // Signature Tab
    var signatureTitle: String { isTurkish ? "Yetkili İmzası" : "Authorized Signature" }
    var signatureDesc: String { isTurkish ? "Makbuzların alt kısmında yer alacak imza görselini (PNG veya JPG) yükleyin." : "Upload the signature image (PNG or JPG) to appear at the bottom of receipts." }
    var uploadSignatureButton: String { isTurkish ? "İmza Görseli Yükle..." : "Upload Signature Image..." }
    var removeSignatureButton: String { isTurkish ? "İmzayı Kaldır" : "Remove Signature" }
    var loadedSignature: String { isTurkish ? "Yüklü İmza" : "Loaded Signature" }
    var noSignatureYet: String { isTurkish ? "Henüz imza yüklenmedi" : "No signature uploaded yet" }

    // About Tab
    var appVersionText: String { isTurkish ? "Sürüm 3.2.0" : "Version 3.2.0" }
    var publisher: String { isTurkish ? "Yayıncı: berkbb" : "Publisher: berkbb" }
    var license: String { isTurkish ? "Lisans: GNU General Public License v3.0 (GPL-3.0)" : "License: GNU General Public License v3.0 (GPL-3.0)" }
    var copyright: String { isTurkish ? "Copyright © 2023-2026 berkbb. Tüm hakları saklıdır." : "Copyright © 2023-2026 berkbb. All rights reserved." }

    // Validation Messages
    var validationErrorTitle: String { isTurkish ? "Doğrulama Hatası" : "Validation Error" }
    var okButton: String { isTurkish ? "Tamam" : "OK" }
    var errIssuerRequired: String { isTurkish ? "Tahsil eden (yetkili) bilgisi zorunludur." : "Collector information is required." }
    var errReceiverRequired: String { isTurkish ? "Ödeyen (muhatap) bilgisi zorunludur." : "Payer information is required." }
    var errSequenceInvalid: String { isTurkish ? "Sıra numarası pozitif bir tam sayı olmalıdır." : "Sequence number must be a positive integer." }
    var errAmountInvalid: String { isTurkish ? "Tutar geçerli bir sayı olmalıdır." : "Amount must be a valid number." }
    var errBuildingIssuerRequired: String { isTurkish ? "Apartman adı ve varsayılan yönetici boş bırakılamaz." : "Building name and default manager cannot be empty." }
    var errFlatCountInvalid: String { isTurkish ? "Daire sayısı pozitif bir tam sayı olmalıdır." : "Flat count must be a positive integer." }
}

// MARK: - Main Screen

struct MainScreen: View {
    @ObservedObject var settings: ReceiptSettingsStore
    @StateObject private var viewModel = MainScreenViewModel()

    private var l10n: L10n { settings.l10n }

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
                        Label(l10n.livePreview, systemImage: "eye.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(l10n.printViewBadge)
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
                            period: viewModel.receiptDate.monthYearString(locale: settings.currentLocale),
                            issuer: viewModel.issuerName.isEmpty ? "—" : viewModel.issuerName,
                            receiver: viewModel.ownerName.isEmpty ? "—" : viewModel.ownerName,
                            amountString: viewModel.totalAmount,
                            sequenceNumber: viewModel.sequenceNumber,
                            notes: viewModel.notes,
                            signatureImage: settings.signatureImage,
                            l10n: l10n
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
                .frame(width: 680, height: 580)
        }
        .alert(item: $viewModel.validationError) { issue in
            Alert(
                title: Text(l10n.validationErrorTitle),
                message: Text(issue.message),
                dismissButton: .default(Text(l10n.okButton))
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
                    Text(l10n.appTitle)
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
                Text(l10n.appSubtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                openSettingsWindow()
            } label: {
                Label(l10n.preferences, systemImage: "gearshape.fill")
                    .padding(.horizontal, 4)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .keyboardShortcut(",", modifiers: .command)
        }
    }

    private func openSettingsWindow() {
        if #available(macOS 14.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
        // If window wasn't opened (e.g. headless or older lifecycle), fallback to sheet
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let hasSettingsWindow = NSApp.windows.contains { $0.title.contains("Tercihler") || $0.title.contains("Settings") || $0.title.contains("Preferences") }
            if !hasSettingsWindow {
                viewModel.isPresentingSettings = true
            }
        }
    }

    // MARK: - Sections

    private var receiptTypeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(l10n.receiptType, systemImage: "doc.plaintext.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)

            Picker("", selection: $viewModel.receiptKind) {
                ForEach(ReceiptKind.allCases) { kind in
                    HStack {
                        Image(systemName: kind.iconName)
                        Text(kind.title(l10n: l10n))
                    }
                    .tag(kind)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }

    private var apartmentAndPeriodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(l10n.flatAndPeriod, systemImage: "calendar.badge.clock")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(l10n.flatNumber)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("", selection: $viewModel.selectedApartment) {
                        ForEach(settings.apartmentNumbers, id: \.self) { number in
                            Text("\(l10n.flatPrefix) \(number)").tag(number)
                        }
                    }
                    .labelsHidden()
                    .onChange(of: viewModel.selectedApartment) { newValue in
                        viewModel.updateApartment(newValue, settings: settings)
                    }
                }

                Spacer()

                VStack(alignment: .leading, spacing: 6) {
                    Text(l10n.period)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $viewModel.receiptDate, displayedComponents: .date)
                        .labelsHidden()
                }
            }

            Divider()

            Toggle(isOn: $viewModel.printApartmentNumber) {
                Label(l10n.printFlatNumber, systemImage: "checkmark.seal")
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
            Label(l10n.parties, systemImage: "person.2.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text(l10n.issuerLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    Image(systemName: "person.badge.shield.checkmark.fill")
                        .foregroundColor(.secondary)
                    TextField(l10n.issuerPlaceholder, text: $viewModel.issuerName)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(NSColor.textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(l10n.receiverLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(l10n.fetchSavedResident) {
                        viewModel.ownerName = settings.owner(for: viewModel.selectedApartment)
                    }
                    .buttonStyle(.link)
                    .font(.caption2)
                }

                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.secondary)
                    TextField(l10n.receiverPlaceholder, text: $viewModel.ownerName)
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
            Label(l10n.financialDetails, systemImage: "banknote.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)

            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(l10n.amount)
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
                    Text(l10n.sequenceNo)
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
                Text(l10n.notesLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(alignment: .top) {
                    Image(systemName: "text.alignleft")
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                    TextField(l10n.notesPlaceholder, text: $viewModel.notes)
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
                Label(l10n.clearForm, systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Spacer()

            Button {
                viewModel.createReceipt(settings: settings)
            } label: {
                Label(l10n.createReceipt, systemImage: "doc.badge.plus")
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
    let l10n: L10n

    private var formattedAmount: String {
        let normalized = amountString.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        if let val = Double(normalized) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = l10n.locale
            return formatter.string(from: NSNumber(value: val)) ?? "₺\(amountString)"
        }
        return "₺ 0,00"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(apartmentName.isEmpty ? l10n.defaultBuildingName : apartmentName.uppercased())
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                    Text(kind == .income ? l10n.incomeBadge : l10n.outcomeBadge)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(kind == .income ? .green : .orange)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(l10n.sequenceNo): #\(sequenceNumber)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                    Text(period)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Info rows
            VStack(spacing: 8) {
                previewRow(label: l10n.receiverLabel, value: receiver)
                if showApartmentNumber {
                    previewRow(label: l10n.flatNumber, value: "\(l10n.flatPrefix) \(apartmentNumber)")
                }
                previewRow(label: l10n.issuerLabel, value: issuer)
                previewRow(label: l10n.dateLabel, value: Date().dayMonthYearString(locale: l10n.locale))
            }

            // Amount Highlight Box
            HStack {
                Text(l10n.totalPaid)
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
                    Text(l10n.descriptionHeader)
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
                        Text(l10n.authorizedSignature)
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
        let l10n = settings.l10n
        let trimmedIssuer = issuerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedOwner = ownerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSequence = sequenceNumber.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedIssuer.isEmpty else {
            validationError = ValidationError(message: l10n.errIssuerRequired)
            return
        }
        guard !trimmedOwner.isEmpty else {
            validationError = ValidationError(message: l10n.errReceiverRequired)
            return
        }
        guard let sequence = Int(trimmedSequence), sequence > 0 else {
            validationError = ValidationError(message: l10n.errSequenceInvalid)
            return
        }
        guard let amount = parseAmount(totalAmount), amount >= 0 else {
            validationError = ValidationError(message: l10n.errAmountInvalid)
            return
        }

        previewDraft = ReceiptDraft(
            receiver: trimmedOwner.localizedCapitalized,
            issuer: trimmedIssuer.localizedCapitalized,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "-" : notes,
            monthYear: receiptDate.monthYearString(locale: settings.currentLocale),
            apartmentNumber: selectedApartment,
            amount: amount,
            sequenceNumber: sequence,
            createdDate: Date().dayMonthYearString(locale: settings.currentLocale),
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

    func title(l10n: L10n) -> String {
        switch self {
        case .income:
            return l10n.incomeTitle
        case .outcome:
            return l10n.outcomeTitle
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
    @Published var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: Keys.language) }
    }
    @Published var theme: AppTheme {
        didSet { defaults.set(theme.rawValue, forKey: Keys.theme) }
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

    var l10n: L10n {
        L10n(language)
    }

    var currentLocale: Locale {
        l10n.locale
    }

    private let defaults = UserDefaults.standard

    init() {
        apartmentName = defaults.string(forKey: Keys.apartmentName) ?? ""
        issuer = defaults.string(forKey: Keys.issuer) ?? ""
        defaultPayment = defaults.string(forKey: Keys.defaultPayment) ?? ""
        flatCount = max(1, ReceiptSettingsStore.readInt(defaults, key: Keys.flatCount, fallback: 1))
        seqNumber = max(1, ReceiptSettingsStore.readInt(defaults, key: Keys.seqNumber, fallback: 1))

        let savedLang = defaults.string(forKey: Keys.language) ?? AppLanguage.system.rawValue
        language = AppLanguage(rawValue: savedLang) ?? .system

        let savedTheme = defaults.string(forKey: Keys.theme) ?? AppTheme.system.rawValue
        theme = AppTheme(rawValue: savedTheme) ?? .system

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
        static let language = "app_language"
        static let theme = "app_theme"

        static func owner(_ number: Int) -> String {
            "homeowner_\(number)"
        }
    }
}

// MARK: - Extensions

extension Date {
    func monthYearString(locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }

    func dayMonthYearString(locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("d MMMM yyyy")
        return formatter.string(from: self)
    }
}
