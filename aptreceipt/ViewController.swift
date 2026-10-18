import AppKit
import SwiftUI

// MARK: - Language & Theme Enums

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case english = "en"
    case turkish = "tr"
    case romanian = "ro"

    var id: String { rawValue }

    func title(l10n: L10n) -> String {
        switch self {
        case .system:
            return l10n.langSystem
        case .english:
            return "English"
        case .turkish:
            return "Türkçe"
        case .romanian:
            return "Română"
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

    var resolvedLanguage: AppLanguage {
        if language != .system {
            return language
        }
        // Locale dependent, defaults to English
        let preferred = Locale.preferredLanguages.first?.prefix(2).lowercased() ?? ""
        if preferred == "tr" {
            return .turkish
        } else if preferred == "ro" {
            return .romanian
        } else {
            return .english
        }
    }

    var isTurkish: Bool { resolvedLanguage == .turkish }
    var isRomanian: Bool { resolvedLanguage == .romanian }
    var isEnglish: Bool { resolvedLanguage == .english }

    var locale: Locale {
        switch resolvedLanguage {
        case .turkish: return Locale(identifier: "tr_TR")
        case .romanian: return Locale(identifier: "ro_RO")
        default: return Locale(identifier: "en_US")
        }
    }

    private func tr(_ en: String, _ tr: String, _ ro: String) -> String {
        switch resolvedLanguage {
        case .turkish: return tr
        case .romanian: return ro
        default: return en
        }
    }

    // App Header & Base
    var appTitle: String { tr("Apartment Receipt", "Apartman Makbuzu", "Chitanță Asociație") }
    var appSubtitle: String { tr("Easily manage and export apartment income and expense receipts", "Gelir ve gider makbuzlarınızı kolayca yönetin ve dışa aktarın", "Gestionați și exportați cu ușurință chitanțele de încasări și plăți") }
    var preferences: String { tr("Preferences", "Tercihler", "Preferințe") }
    var settingsTitle: String { tr("Preferences & Settings", "Tercihler & Ayarlar", "Preferințe & Setări") }
    var settingsSubtitle: String { tr("Configure building details, language, theme, and signature", "Apartman bilgileri, dil, tema ve imzanızı düzenleyin", "Configurați datele imobilului, limba, tema și semnătura") }

    // Receipt Type
    var receiptType: String { tr("Receipt Type", "Makbuz Türü", "Tip Chitanță") }
    var incomeTitle: String { tr("Income (Collection)", "Gelir (Tahsilat)", "Încasare (Întreținere)") }
    var outcomeTitle: String { tr("Expense (Disbursement)", "Gider (Tediye)", "Plată (Cheltuială)") }
    var incomeBadge: String { tr("INCOME RECEIPT", "TAHSİLAT MAKBUZU", "CHITANȚĂ DE ÎNCASARE") }
    var outcomeBadge: String { tr("EXPENSE RECEIPT", "GİDER / TEDİYE MAKBUZU", "DISPOZIȚIE DE PLATĂ") }

    // Flat & Period
    var flatAndPeriod: String { tr("Apartment & Period", "Daire ve Dönem", "Apartament & Perioadă") }
    var flatNumber: String { tr("Apartment Number", "Daire Numarası", "Număr Apartament") }
    var flatPrefix: String { tr("Flat", "Daire", "Ap.") }
    var period: String { tr("Period", "Dönem", "Perioadă") }
    var printFlatNumber: String { tr("Print apartment number on receipt", "Daire numarasını makbuz üzerine yazdır", "Includeți numărul apartamentului pe chitanță") }

    // Parties
    var parties: String { tr("Parties", "Taraflar", "Părți Implicate") }
    var issuerLabel: String { tr("Collector (Manager / Authorized):", "Tahsil Eden (Yönetici / Yetkili):", "Casier / Administrator:") }
    var issuerPlaceholder: String { tr("e.g. John Doe", "Örn: Ahmet Yılmaz", "Ex: Ion Popescu") }
    var receiverLabel: String { tr("Payer (Resident / Recipient):", "Ödeyen (Daire Sakini / Muhatap):", "Plătitor (Locatar / Proprietar):") }
    var receiverPlaceholder: String { tr("e.g. Jane Smith", "Örn: Mehmet Demir", "Ex: Maria Ionescu") }
    var fetchSavedResident: String { tr("Load Saved Resident", "Kayıtlı Sakini Getir", "Selectează Locatar Înregistrat") }

    // Financial & Notes
    var financialDetails: String { tr("Financial Details & Description", "Mali Detaylar ve Açıklama", "Detalii Financiare & Descriere") }
    var amount: String { tr("Amount (₺)", "Tutar (₺)", "Sumă (₺)") }
    var sequenceNo: String { tr("Sequence No", "Sıra No", "Nr. Chitanță") }
    var notesLabel: String { tr("Description / Notes", "Açıklama / Notlar", "Descriere / Mențiuni") }
    var notesPlaceholder: String { tr("e.g. October 2026 monthly dues and maintenance fee", "Örn: 2026 Ekim ayı aidatı ve ortak alan gideri", "Ex: Cotă întreținere octombrie 2026 și fond reparații") }

    // Actions
    var clearForm: String { tr("Clear Form", "Formu Temizle", "Resetează Formularul") }
    var createReceipt: String { tr("Create & Preview Receipt", "Makbuz Oluştur & Önizle", "Generează & Previzualizează") }

    // Live Preview & Document
    var livePreview: String { tr("Live Preview", "Canlı Önizleme", "Previzualizare în Timp Real") }
    var printViewBadge: String { tr("Print View", "Baskı Görünümü", "Format Tipărire") }
    var totalPaid: String { tr("Total Paid:", "Ödenen Tutar:", "Sumă Plătită:") }
    var totalCollected: String { tr("Collected Amount:", "Tahsil Edilen Tutar:", "Sumă Încasată:") }
    var descriptionHeader: String { tr("Description:", "Açıklama:", "Descriere:") }
    var receiptNo: String { tr("Receipt No:", "Makbuz No:", "Chitanță Nr.:") }
    var issueDate: String { tr("Issue Date:", "Düzenleme Tarihi:", "Data Emiterii:") }
    var dateLabel: String { tr("Date", "Tarih", "Dată") }
    var authorizedSignature: String { tr("Authorized Signature", "Yetkili İmzası", "Semnătura Autorizată") }
    var electronicDisclaimer: String { tr("This document has been issued electronically pursuant to building management records.", "Bu belge apartman yönetimi kayıtları uyarınca elektronik ortamda tanzim edilmiştir.", "Acest document a fost emis electronic conform evidențelor asociației de proprietari.") }
    var defaultBuildingName: String { tr("BUILDING MANAGEMENT", "APARTMAN YÖNETİMİ", "ASOCIAȚIA DE PROPRIETARI") }

    // Sheet Actions
    var previewTitle: String { tr("Receipt Preview", "Makbuz Önizleme", "Previzualizare Chitanță") }
    var previewSubtitle: String { tr("Review the receipt in A4 invoice format, export as PDF or JPEG", "A4 fatura formatında oluşturulan makbuzu inceleyin, PDF veya JPEG olarak kaydedin", "Examinați chitanța în format A4 și exportați ca PDF sau JPEG") }
    var close: String { tr("Close", "Kapat", "Închide") }
    var cancel: String { tr("Cancel", "İptal", "Anulează") }
    var saveAndClose: String { tr("Save & Close", "Kaydet ve Kapat", "Salvează și Închide") }
    var saveAsJPEG: String { tr("Save as JPEG", "JPEG Olarak Kaydet", "Salvare ca JPEG") }
    var saveAsPDF: String { tr("Save as PDF", "PDF Olarak Kaydet", "Salvare ca PDF") }
    var saveSuccess: String { tr("Receipt saved successfully!", "Makbuz başarıyla kaydedildi!", "Chitanța a fost salvată cu succes!") }
    var saveSuccessPDF: String { tr("PDF document saved successfully!", "PDF belgesi başarıyla kaydedildi!", "Documentul PDF a fost salvat cu succes!") }
    var saveSuccessJPEG: String { tr("JPEG image saved successfully!", "JPEG görseli başarıyla kaydedildi!", "Imaginea JPEG a fost salvată cu succes!") }

    // Invoice Specific Strings
    var invoiceDocumentTitle: String { tr("DUES & EXPENSE RECEIPT", "AİDAT VE GİDER MAKBUZU", "CHITANȚĂ COTE ÎNTREȚINERE") }
    var invoiceSubHeader: String { tr("Official Property & Building Management Document", "Apartman ve Site Yönetimi Resmi İşletme Belgesi", "Document Oficial de Gestiune al Asociației de Proprietari") }
    var invoiceTypeLabel: String { tr("DOCUMENT TYPE", "BELGE TÜRÜ", "TIP DOCUMENT") }
    var serialLabel: String { tr("SERIAL NO", "SERİ NO", "SERIE DOCUMENT") }
    var managerSectionTitle: String { tr("ISSUER / MANAGEMENT", "DÜZENLEYEN / YÖNETİM", "EMITENT / ADMINISTRAȚIE") }
    var payerSectionTitle: String { tr("PAYER / RESIDENT", "MUHATAP / SAKİN", "DESTINATAR / LOCATAR") }
    var itemNo: String { tr("Item", "S.No", "Nr.") }
    var itemDescription: String { tr("Service & Description Item", "Hizmet ve Açıklama Kalemi", "Denumire Serviciu / Cheltuială") }
    var itemPeriod: String { tr("Period", "Dönem", "Lună") }
    var itemUnit: String { tr("Unit", "Birim", "Unitate") }
    var unitMonth: String { tr("1 Month", "1 Ay", "1 Lună") }
    var itemAmount: String { tr("Amount", "Tutar", "Sumă") }
    var subtotal: String { tr("Subtotal:", "Ara Toplam:", "Subtotal:") }
    var vatTax: String { tr("VAT / Tax Exemption:", "KDV / Vergi Muafiyeti:", "TVA / Scutire:") }
    var vatExempt: String { tr("0% (Exempt)", "%0 (Muaf)", "0% (Scutit de TVA)") }
    var grandTotal: String { tr("GRAND TOTAL:", "GENEL TOPLAM:", "TOTAL GENERAL:") }
    var inWordsPrefix: String { tr("In Words:", "Yalnız:", "În litere:") }
    var signatureStamp: String { tr("AUTHORIZED STAMP & SIGNATURE", "YÖNETİCİ KAŞE / İMZA", "ȘTAMPILĂ ȘI SEMNĂTURĂ") }
    var barcodeSerialText: String { tr("ELECTRONIC OFFICIAL RECORD", "ELEKTRONİK RESMİ KAYIT BELGESİ", "DOCUMENT ELECTRONIC OFICIAL") }
    var legalStatutoryNotice: String { tr("Issued in accordance with Property Ownership Law as an official management receipt.", "634 Sayılı Kat Mülkiyeti Kanunu uyarınca bina işletme ve aidat hesabına mahsuben düzenlenmiştir.", "Emis în conformitate cu legislația privind asociațiile de proprietari pentru evidența cheltuielilor comune.") }
    var statutoryTaxNotice: String { tr("Exempt from VAT under Property Management Law.", "634 sayılı KMK uyarınca bina işletme gider ve aidatları KDV'den muaftır.", "Scutit de TVA conform normelor asociațiilor de proprietari.") }
    var incomeDocumentType: String { tr("Collection Receipt", "Tahsilat Makbuzu", "Chitanță Încasare") }
    var expenseDocumentType: String { tr("Operating Expense Receipt", "İşletme Gider Makbuzu", "Dispoziție de Plată") }
    var defaultItemNameIncome: String { tr("Common Expense & Dues Contribution", "Ortak Gider ve Aidat Avans Katılım Payı", "Cotă întreținere și fond de rulment") }
    var defaultItemNameExpense: String { tr("Building Maintenance & Operating Expense", "Apartman İşletme ve Bakım Hizmet Gideri", "Servicii de întreținere și reparații imobil") }
    var commonAreaLabel: String { tr("Common Area / General", "Ortak Alan / Genel", "Spații Comune / General") }
    var invoiceBuildingLabel: String { tr("Building:", "Bina / Site:", "Imobil / Asociație:") }
    var invoiceManagerLabel: String { tr("Manager:", "Yönetici:", "Administrator:") }
    var invoicePayerResidentLabel: String { tr("Resident / Payer:", "Sakin / Muhatap:", "Locatar / Proprietar:") }
    var invoiceVendorLabel: String { tr("Payee / Vendor:", "Ödeme Yapılan:", "Furnizor / Beneficiar:") }
    var invoiceUnitLabel: String { tr("Unit / Flat:", "Bağımsız Bölüm:", "Apartament:") }

    // Settings Tabs
    var tabBuilding: String { tr("Building", "Apartman", "Imobil") }
    var tabResidents: String { tr("Residents", "Sakinler", "Locatari") }
    var tabAppearance: String { tr("Appearance & Language", "Görünüm & Dil", "Aspect & Limbă") }
    var tabSignature: String { tr("Signature", "İmza", "Semnătură") }
    var tabAbout: String { tr("About", "Hakkında", "Despre") }

    // Settings Form Fields
    var buildingDetails: String { tr("Building Information", "Apartman Bilgileri", "Informații Imobil / Asociație") }
    var buildingName: String { tr("Building Name:", "Apartman Adı:", "Nume Imobil / Asociație:") }
    var defaultManager: String { tr("Default Manager (Collector):", "Varsayılan Yönetici (Tahsil Eden):", "Administrator Implicit (Casier):") }
    var totalFlats: String { tr("Total Number of Flats:", "Toplam Daire Sayısı:", "Număr Total Apartamente:") }
    var financialSettings: String { tr("Financial & Receipt Defaults", "Mali & Makbuz Değerleri", "Setări Financiare & Valori Implicite") }
    var defaultDues: String { tr("Default Dues Amount (₺):", "Varsayılan Aidat Tutarı (₺):", "Sumă Cotă Implicită (₺):") }
    var nextReceiptNo: String { tr("Next Receipt No:", "Sıradaki Makbuz No:", "Număr Următor Chitanță:") }

    // Appearance & Language Tab
    var appearanceSection: String { tr("Appearance and Theme", "Görünüm ve Tema", "Aspect și Temă") }
    var themeSelection: String { tr("Theme Selection:", "Tema Seçimi:", "Selectare Temă:") }
    var themeSystem: String { tr("System (Automatic)", "Sistem (Otomatik)", "Sistem (Automat)") }
    var themeLight: String { tr("Light Theme", "Açık Tema", "Temă Luminoasă") }
    var themeDark: String { tr("Dark Theme", "Koyu Tema", "Temă Întunecată") }

    var languageSection: String { tr("Application Language", "Uygulama Dili", "Limba Aplicației") }
    var languageSelection: String { tr("Language Selection:", "Dil Seçimi:", "Selectare Limbă:") }
    var langSystem: String { tr("System Default (Automatic)", "Sistem Dili (Otomatik)", "Sistem (Automat)") }

    // Residents Directory
    var residentsDirectoryTitle: String { tr("Residents Directory", "Daire Sakinleri Rehberi", "Registru Locatari") }
    var residentsDirectoryDesc: String { tr("Assign resident or owner names for each flat. Selecting a flat will automatically fill in their name.", "Her daire için kayıtlı ev sahibi veya kiracı ismini belirleyin. Makbuz oluştururken daire seçildiğinde otomatik doldurulacaktır.", "Înregistrați numele locatarilor pentru fiecare apartament.") }
    var flatLabel: String { tr("Flat:", "Daire:", "Apartament:") }
    var residentNamePlaceholder: String { tr("Resident Full Name", "Daire Sakini Adı Soyadı", "Nume și Prenume Locatar") }
    var saveButton: String { tr("Save", "Kaydet", "Salvează") }
    var residentSavedFeedback: String { tr("resident saved successfully.", "sakini başarıyla kaydedildi.", "locatarul a fost salvat cu succes.") }

    // Signature Tab
    var signatureTitle: String { tr("Authorized Signature", "Yetkili İmzası", "Semnătură Autorizată") }
    var signatureDesc: String { tr("Upload the signature image (PNG or JPG) to appear at the bottom of receipts.", "Makbuzların alt kısmında yer alacak imza görselini (PNG veya JPG) yükleyin.", "Încărcați imaginea semnăturii pentru a apărea pe chitanțe.") }
    var uploadSignatureButton: String { tr("Upload Signature Image...", "İmza Görseli Yükle...", "Încarcă Imagine Semnătură...") }
    var removeSignatureButton: String { tr("Remove Signature", "İmzayı Kaldır", "Șterge Semnătura") }
    var loadedSignature: String { tr("Loaded Signature", "Yüklü İmza", "Semnătură Încărcată") }
    var noSignatureYet: String { tr("No signature uploaded yet", "Henüz imza yüklenmedi", "Nicio semnătură încărcată încă") }

    // About Tab & License
    var appVersionText: String { tr("Version 3.2.0 (Build 5)", "Sürüm 3.2.0 (Yapı 5)", "Versiunea 3.2.0 (Build 5)") }
    var publisher: String { tr("Publisher: berkbb", "Yayıncı: berkbb", "Editor: berkbb") }
    var license: String { tr("License: GNU General Public License v3.0 (GPL-3.0)", "Lisans: GNU Genel Kamu Lisansı v3.0 (GPL-3.0)", "Licență: GNU General Public License v3.0 (GPL-3.0)") }
    var copyright: String { tr("Copyright © 2023-2026 berkbb. All rights reserved.", "Copyright © 2023-2026 berkbb. Tüm hakları saklıdır.", "Copyright © 2023-2026 berkbb. Toate drepturile rezervate.") }
    var viewLicenseButton: String { tr("View License (GNU GPL v3)", "Lisansı Görüntüle (GNU GPL v3)", "Vizualizează Licența (GNU GPL v3)") }
    var licenseViewerTitle: String { tr("GNU General Public License v3.0", "GNU Genel Kamu Lisansı v3.0", "Licența Publică Generală GNU v3.0") }
    var licenseViewerSubtitle: String { tr("Free and open-source software license. Publisher: berkbb", "Özgür ve açık kaynak kodlu yazılım lisansı. Yayıncı: berkbb", "Licență software liberă și cu sursă deschisă. Editor: berkbb") }
    var copyLicenseText: String { tr("Copy License Text", "Lisans Metnini Kopyala", "Copiază Textul Licenței") }
    var licenseCopied: String { tr("Copied!", "Kopyalandı!", "Copiat!") }

    // Validation Messages
    var validationErrorTitle: String { tr("Validation Error", "Doğrulama Hatası", "Eroare de Validare") }
    var okButton: String { tr("OK", "Tamam", "OK") }
    var errIssuerRequired: String { tr("Collector information is required.", "Tahsil eden (yetkili) bilgisi zorunludur.", "Informațiile administratorului/casierului sunt obligatorii.") }
    var errReceiverRequired: String { tr("Payer information is required.", "Ödeyen (muhatap) bilgisi zorunludur.", "Informațiile plătitorului sunt obligatorii.") }
    var errSequenceInvalid: String { tr("Sequence number must be a positive integer.", "Sıra numarası pozitif bir tam sayı olmalıdır.", "Numărul de serie trebuie să fie un număr întreg pozitiv.") }
    var errAmountInvalid: String { tr("Amount must be a valid number.", "Tutar geçerli bir sayı olmalıdır.", "Suma trebuie să fie un număr valid.") }
    var errBuildingIssuerRequired: String { tr("Building name and default manager cannot be empty.", "Apartman adı ve varsayılan yönetici boş bırakılamaz.", "Numele imobilului și administratorul nu pot fi goale.") }
    var errFlatCountInvalid: String { tr("Flat count must be a positive integer.", "Daire sayısı pozitif bir tam sayı olmalıdır.", "Numărul de apartamente trebuie să fie pozitiv.") }
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
        .sheet(isPresented: $settings.showLicenseViewer) {
            LicenseViewerSheet(l10n: l10n)
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
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(2)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .help(l10n.preferences)
            .accessibilityLabel(l10n.preferences)
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
        didSet {
            defaults.set(theme.rawValue, forKey: Keys.theme)
            applyTheme(theme)
        }
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
    @Published var showLicenseViewer: Bool = false

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
        let resolvedTheme = AppTheme(rawValue: savedTheme) ?? .system
        theme = resolvedTheme
        applyTheme(resolvedTheme)

        signatureData = defaults.data(forKey: Keys.signature)
    }

    func applyTheme(_ targetTheme: AppTheme) {
        switch targetTheme {
        case .system:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
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

// MARK: - Read-Only License Viewer Sheet

struct LicenseViewerSheet: View {
    let l10n: L10n
    @Environment(\.presentationMode) private var presentationMode
    @State private var copied = false

    private let licenseText = """
                    GNU GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007

 Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.

                            Preamble

  The GNU General Public License is a free, copyleft license for
software and other kinds of works.

  The licenses for most software and other practical works are designed
to take away your freedom to share and change the works.  By contrast,
the GNU General Public License is intended to guarantee your freedom to
share and change all versions of a program--to make sure it remains free
software for all its users.  We, the Free Software Foundation, use the
GNU General Public License for most of our software; it applies also to
any other work released this way by its authors.  You can apply it to
your programs, too.

  When we speak of free software, we are referring to freedom, not
price.  Our General Public Licenses are designed to make sure that you
have the freedom to distribute copies of free software (and charge for
them if you wish), that you receive source code or can get it if you
want it, that you can change the software or use pieces of it in new
free programs, and that you know you can do these things.

  To protect your rights, we need to prevent others from denying you
these rights or asking you to surrender the rights.  Therefore, you have
certain responsibilities if you distribute copies of the software, or if
you modify it: responsibilities to respect the freedom of others.

  For example, if you distribute copies of such a program, whether
gratis or for a fee, you must pass on to the recipients the same
freedoms that you received.  You must make sure that they, too, receive
or can get the source code.  And you must show them these terms so they
know their rights.

  Developers that use the GNU GPL protect your rights with two steps:
(1) assert copyright on the software, and (2) offer you this License
giving you legal permission to copy, distribute and/or modify it.

                       TERMS AND CONDITIONS

  0. Definitions.
  "This License" refers to version 3 of the GNU General Public License.
  "Copyright" also means copyright-like laws that apply to other kinds of works.
  "The Program" refers to any copyrightable work licensed under this License.
  "Publisher" refers to berkbb.

  1. Source Code.
  The "source code" for a work means the preferred form of the work
for making modifications to it. "Object code" means any non-source
form of a work.

  2. Basic Permissions.
  All rights granted under this License are granted for the term of
copyright on the Program, and are irrevocable provided the stated
conditions are met.

  3. Protecting Users' Legal Rights From Anti-Circumvention Law.
  No covered work shall be deemed part of an effective technological
measure under any applicable law fulfilling obligations under article 11
of the WIPO copyright treaty adopted on 20 December 1996.

  4. Conveying Verbatim Copies.
  You may convey verbatim copies of the Program's source code as you
receive it, in any medium, provided that you conspicuously and
appropriately publish on each copy an appropriate copyright notice;
keep intact all notices stating that this License applies to it.

  5. Conveying Modified Source Versions.
  You may convey a work based on the Program, or the modifications to
produce it from the Program, in the form of source code under the
terms of section 4, provided that you also meet all of these conditions:
    a) The work must carry prominent notices stating that you modified it.
    b) The work must carry prominent notices stating that it is released
       under this License.

  NO WARRANTY
  BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND.
"""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.title2)
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(l10n.licenseViewerTitle)
                        .font(.headline)
                    Text(l10n.licenseViewerSubtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Publisher & License Banner
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "person.badge.shield.checkmark.fill")
                        .foregroundColor(.accentColor)
                    Text("Publisher:")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    Text("berkbb")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15))
                        .clipShape(Capsule())
                }

                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.green)
                    Text("License:")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    Text("GNU GPL v3.0")
                        .font(.caption.bold())
                }

                Spacer()

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(licenseText, forType: .string)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copied = false
                    }
                } label: {
                    Label(copied ? l10n.licenseCopied : l10n.copyLicenseText, systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))

            Divider()

            // Scrollable Read-Only License Text
            ScrollView {
                Text(licenseText)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color(NSColor.textColor))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .textSelection(.enabled)
            }
            .background(Color(NSColor.textBackgroundColor))

            Divider()

            // Footer
            HStack {
                Text(l10n.copyright)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Button(l10n.close) {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 640, height: 540)
    }
}

