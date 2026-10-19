import AppKit
import SwiftUI
import CoreImage
@preconcurrency import Vision
import PDFKit
import UniformTypeIdentifiers

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

enum AppCurrency: String, CaseIterable, Identifiable, Codable {
    case turkishLira = "TRY"
    case romanianLeu = "RON"
    case usDollar = "USD"
    case euro = "EUR"
    case britishPound = "GBP"

    var id: String { rawValue }

    var code: String { rawValue }

    var symbol: String {
        switch self {
        case .turkishLira: return "₺"
        case .romanianLeu: return "Lei"
        case .usDollar: return "$"
        case .euro: return "€"
        case .britishPound: return "£"
        }
    }

    func title(l10n: L10n) -> String {
        switch self {
        case .turkishLira:
            return "\(l10n.currencyTRY) (\(symbol))"
        case .romanianLeu:
            return "\(l10n.currencyRON) (\(symbol))"
        case .usDollar:
            return "\(l10n.currencyUSD) (\(symbol))"
        case .euro:
            return "\(l10n.currencyEUR) (\(symbol))"
        case .britishPound:
            return "\(l10n.currencyGBP) (\(symbol))"
        }
    }

    static func `default`(for language: AppLanguage) -> AppCurrency {
        switch language {
        case .turkish:
            return .turkishLira
        case .romanian:
            return .romanianLeu
        case .english, .system:
            return .usDollar
        }
    }
}

// MARK: - Late Payment Compensation Country Profile

enum LateFeeCountryProfile: String, CaseIterable, Identifiable, Codable {
    case turkey = "turkey"
    case romania = "romania"
    case international = "international"
    case custom = "custom"

    var id: String { rawValue }

    var flagEmoji: String {
        switch self {
        case .turkey: return "🇹🇷"
        case .romania: return "🇷🇴"
        case .international: return "🌐"
        case .custom: return "⚙️"
        }
    }

    func title(l10n: L10n) -> String {
        switch self {
        case .turkey:
            return l10n.isTurkish ? "Türkiye (KMK Md. 20/c)" : (l10n.isRomanian ? "Turcia (KMK Art. 20)" : "Turkey (KMK Art. 20)")
        case .romania:
            return l10n.isTurkish ? "Romanya (Legea 196/2018)" : (l10n.isRomanian ? "România (Legea 196/2018)" : "Romania (Law 196/2018)")
        case .international:
            return l10n.isTurkish ? "Uluslararası / Genel (HOA)" : (l10n.isRomanian ? "Internațional / General (HOA)" : "International / General (HOA)")
        case .custom:
            return l10n.isTurkish ? "Özel Yapılandırma" : (l10n.isRomanian ? "Personalizat" : "Custom Jurisdiction")
        }
    }

    var defaultRate: Double {
        switch self {
        case .turkey: return 5.0
        case .romania: return 6.0
        case .international: return 5.0
        case .custom: return 5.0
        }
    }

    var defaultDueDay: Int {
        switch self {
        case .turkey: return 15
        case .romania: return 20
        case .international: return 10
        case .custom: return 15
        }
    }

    var defaultGraceDays: Int {
        switch self {
        case .turkey: return 0
        case .romania: return 30
        case .international: return 10
        case .custom: return 0
        }
    }

    var quickPresets: [Double] {
        switch self {
        case .turkey: return [3.0, 5.0, 7.5, 10.0]
        case .romania: return [3.0, 5.0, 6.0, 10.0]
        case .international: return [2.5, 5.0, 7.5, 10.0]
        case .custom: return [3.0, 5.0, 7.5, 10.0]
        }
    }

    func defaultFootnote(for language: AppLanguage) -> String {
        switch self {
        case .turkey:
            switch language {
            case .turkish: return "* 634 Sayılı Kat Mülkiyeti Kanunu Madde 20/c uyarınca hesaplanmıştır."
            case .romanian: return "* Calculat conform art. 20/c din legislația asociațiilor de proprietari."
            default: return "* Calculated pursuant to Article 20/c of Property Law No. 634."
            }
        case .romania:
            switch language {
            case .turkish: return "* Romanya 196/2018 Sayılı Kanun Madde 77 (azami %0.2/gün) uyarınca hesaplanmıştır."
            case .romanian: return "* Calculat conform Legii 196/2018 Art. 77 privind asociațiile de proprietari (max. 0.2%/zi)."
            default: return "* Calculated pursuant to Romanian Law No. 196/2018 Art. 77 on Owners Associations."
            }
        case .international:
            switch language {
            case .turkish: return "* Bina yönetim planı ve işletme projesi gecikme hükümleri uyarınca hesaplanmıştır."
            case .romanian: return "* Calculat conform regulamentului de ordine interioară al asociației."
            default: return "* Calculated in accordance with condominium property association late fee regulations."
            }
        case .custom:
            switch language {
            case .turkish: return "* İlgili yönetim kurulu kararı ve gecikme tazminatı esasları uyarınca hesaplanmıştır."
            case .romanian: return "* Calculat conform deciziei comitetului executiv privind penalitățile."
            default: return "* Calculated in accordance with management board late penalty resolutions."
            }
        }
    }

    func defaultLegalNotice(for language: AppLanguage) -> String {
        switch self {
        case .turkey:
            switch language {
            case .turkish: return "634 sayılı Kat Mülkiyeti Kanunu Madde 20/c gereği vaktinde ödenmeyen aidata aylık %5 kanuni gecikme tazminatı uygulanır."
            case .romanian: return "Conform art. 20/c din Legea Asociațiilor, se aplică 5% penalizare lunară pentru restanțe."
            default: return "Under Article 20/c of Property Law No. 634, a 5% monthly compensation is legally applied to overdue dues."
            }
        case .romania:
            switch language {
            case .turkish: return "Romanya 196/2018 Sayılı Kanun Md. 77 gereği, 30 günlük son ödeme süresini aşan aidatlara günlük azami %0.2 (aylık yakl. %6) ceza uygulanabilir."
            case .romanian: return "Conform Legii 196/2018 Art. 77, asociația poate stabili penalizări de până la 0.2%/zi după un termen de grație de 30 de zile."
            default: return "Under Romanian Law 196/2018 Art. 77, associations may apply late penalties up to 0.2% per day after a 30-day grace period."
            }
        case .international:
            switch language {
            case .turkish: return "Bina ve site yönetim kuralları uyarınca vaktinde ödenmeyen aidatlara aylık gecikme bedeli işletilir."
            case .romanian: return "Penalitățile de întârziere se aplică în conformitate cu regulamentul asociației de proprietari."
            default: return "Late fees and penalties are applied to overdue dues in accordance with condominium HOA regulations."
            }
        case .custom:
            switch language {
            case .turkish: return "Özel gecikme oranı, son ödeme günü ve makbuz dipnotunu serbestçe belirleyebilirsiniz."
            case .romanian: return "Puteți defini liber rata penalizării, scadența și nota legală de pe chitanță."
            default: return "Freely configure your custom penalty rate, payment due threshold, and receipt legal citation."
            }
        }
    }

    static func `default`(for language: AppLanguage) -> LateFeeCountryProfile {
        switch language {
        case .turkish: return .turkey
        case .romanian: return .romania
        default: return .international
        }
    }
}

// MARK: - Late Payment Compensation Calculator

enum LateFeeCalculator {
    /// Late fee for `base` at `monthlyRate` percent per month over `months`, rounded to cents.
    static func fee(base: Double, monthlyRate: Double, months: Int) -> Double {
        roundedToCents(base * (monthlyRate / 100.0) * Double(months))
    }

    /// Dues plus late fee, rounded to cents.
    static func grandTotal(base: Double, lateFee: Double) -> Double {
        roundedToCents(base + lateFee)
    }

    static func roundedToCents(_ value: Double) -> Double {
        (value * 100.0).rounded() / 100.0
    }
}

// MARK: - Vendor & Service Models

struct VendorRecord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var category: String = ""
    var contactInfo: String = ""
}

struct ExpenseServicePreset: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var defaultDescription: String
    var iconName: String = "briefcase.fill"
    var suggestedVendor: String? = nil
}

// MARK: - Language Default Sample Data

struct SampleData {
    let apartmentName: String
    let issuer: String
    let defaultPayment: String
    let flatCount: Int
    let currency: AppCurrency
    let residents: [Int: String]
    let sampleNotes: String
    let defaultVendors: [VendorRecord]
    let defaultServices: [ExpenseServicePreset]

    static func defaults(for language: AppLanguage) -> SampleData {
        switch language {
        case .turkish:
            return SampleData(
                apartmentName: "Güleryüz Apartmanı",
                issuer: "Ahmet Yılmaz",
                defaultPayment: "1750",
                flatCount: 12,
                currency: .turkishLira,
                residents: [
                    1: "Mehmet Kaya",
                    2: "Ayşe Demir",
                    3: "Mustafa Çelik",
                    4: "Fatma Şahin",
                    5: "Ali Öztürk",
                    6: "Zeynep Arslan",
                    7: "Emre Koç",
                    8: "Hatice Aydın",
                    9: "Burak Doğan",
                    10: "Elif Yıldız",
                    11: "Serkan Şimşek",
                    12: "Gamze Kurt"
                ],
                sampleNotes: "2026 Ekim ayı aidatı ve asansör periyodik bakım gider payı",
                defaultVendors: [
                    VendorRecord(name: "Kaya Asansör Ltd. Şti.", category: "Asansör Bakımı", contactInfo: "0312 444 01 23"),
                    VendorRecord(name: "Pırıl Temizlik Hizmetleri", category: "Temizlik & Sarf", contactInfo: "0532 111 22 33"),
                    VendorRecord(name: "Başkent Ortak Elektrik A.Ş.", category: "Ortak Elektrik", contactInfo: "Abone No: 98412"),
                    VendorRecord(name: "Usta Tesisat & Onarım (Ahmet Usta)", category: "Tesisat & Onarım", contactInfo: "0555 987 65 43"),
                    VendorRecord(name: "Yeşil Vadi Peyzaj & Bahçe", category: "Bahçe & Peyzaj", contactInfo: "0312 321 00 11")
                ],
                defaultServices: [
                    ExpenseServicePreset(name: "Asansör Bakımı", defaultDescription: "2026 periyodik bina asansörü bakım, yağlama ve kontrol bedeli", iconName: "arrow.up.and.down.circle.fill", suggestedVendor: "Kaya Asansör Ltd. Şti."),
                    ExpenseServicePreset(name: "Temizlik & Malzeme", defaultDescription: "Bina ortak alan temizliği ve hijyen sarf malzeme bedeli", iconName: "sparkles", suggestedVendor: "Pırıl Temizlik Hizmetleri"),
                    ExpenseServicePreset(name: "Ortak Elektrik / Su", defaultDescription: "Merdiven otomatiği, hidrofor ve çevre aydınlatma ortak elektrik gideri", iconName: "bolt.fill", suggestedVendor: "Başkent Ortak Elektrik A.Ş."),
                    ExpenseServicePreset(name: "Tesisat & Onarım", defaultDescription: "Bina ortak su tesisatı, çatı izolasyonu ve onarım işçiliği", iconName: "wrench.and.screwdriver.fill", suggestedVendor: "Usta Tesisat & Onarım (Ahmet Usta)"),
                    ExpenseServicePreset(name: "Bahçe & Peyzaj", defaultDescription: "Site çevre düzenlemesi, bahçe çim biçme ve budama hizmeti", iconName: "leaf.fill", suggestedVendor: "Yeşil Vadi Peyzaj & Bahçe")
                ]
            )
        case .romanian:
            return SampleData(
                apartmentName: "Asociația Parcul Tineretului",
                issuer: "Andrei Popescu",
                defaultPayment: "1750",
                flatCount: 12,
                currency: .romanianLeu,
                residents: [
                    1: "Elena Radu",
                    2: "Ion Ionescu",
                    3: "Maria Dumitrescu",
                    4: "Mihai Stan",
                    5: "Alexandru Georgescu",
                    6: "Andreea Ilie",
                    7: "Cristian Vasile",
                    8: "Ana Marin",
                    9: "Florin Tudor",
                    10: "Gabriela Dobre",
                    11: "Dan Barbu",
                    12: "Simona Nistor"
                ],
                sampleNotes: "Cotă întreținere octombrie 2026 și fond reparații ascensor",
                defaultVendors: [
                    VendorRecord(name: "Ascensor Servicii SRL", category: "Întreținere Lift", contactInfo: "021 334 55 66"),
                    VendorRecord(name: "Curățenie Totală SRL", category: "Curățenie & Consumabile", contactInfo: "0722 111 222"),
                    VendorRecord(name: "Enel Energie Muntenia SA", category: "Energie Electrică", contactInfo: "Cod Client: 88412"),
                    VendorRecord(name: "Instalații Sanitare (Ion Meșter)", category: "Instalații & Reparații", contactInfo: "0744 987 654"),
                    VendorRecord(name: "Spații Verzi & Grădinărit SRL", category: "Peisagistică", contactInfo: "021 456 78 90")
                ],
                defaultServices: [
                    ExpenseServicePreset(name: "Întreținere Lift", defaultDescription: "Revizie tehnică lunară, gresare și verificare periodică ascensor", iconName: "arrow.up.and.down.circle.fill", suggestedVendor: "Ascensor Servicii SRL"),
                    ExpenseServicePreset(name: "Curățenie Spații Comune", defaultDescription: "Servicii de curățenie scară bloc și produse igienico-sanitare", iconName: "sparkles", suggestedVendor: "Curățenie Totală SRL"),
                    ExpenseServicePreset(name: "Energie Electrică Spații Comune", defaultDescription: "Factură energie electrică iluminat casa scării și hidrofor", iconName: "bolt.fill", suggestedVendor: "Enel Energie Muntenia SA"),
                    ExpenseServicePreset(name: "Reparații & Instalații", defaultDescription: "Lucrări de reparații instalații sanitare comune și hidroizolație", iconName: "wrench.and.screwdriver.fill", suggestedVendor: "Instalații Sanitare (Ion Meșter)"),
                    ExpenseServicePreset(name: "Întreținere Spații Verzi", defaultDescription: "Tuns gazon, toaletare arbuști și curățenie curte bloc", iconName: "leaf.fill", suggestedVendor: "Spații Verzi & Grădinărit SRL")
                ]
            )
        case .english, .system:
            return SampleData(
                apartmentName: "Sunshine Residence",
                issuer: "John Doe",
                defaultPayment: "1750",
                flatCount: 12,
                currency: .usDollar,
                residents: [
                    1: "Jane Smith",
                    2: "Robert Johnson",
                    3: "Emily Davis",
                    4: "Michael Brown",
                    5: "Sarah Wilson",
                    6: "David Miller",
                    7: "Jessica Taylor",
                    8: "James Anderson",
                    9: "Laura Thomas",
                    10: "Daniel Martinez",
                    11: "Olivia White",
                    12: "Matthew Harris"
                ],
                sampleNotes: "October 2026 monthly dues and elevator maintenance fee",
                defaultVendors: [
                    VendorRecord(name: "Apex Elevator Services Inc.", category: "Elevator Maintenance", contactInfo: "+1 (555) 019-2834"),
                    VendorRecord(name: "CleanPro Facilities LLC", category: "Janitorial & Supplies", contactInfo: "+1 (555) 014-9988"),
                    VendorRecord(name: "City Power & Utilities Co.", category: "Common Utilities", contactInfo: "Acct: #94018"),
                    VendorRecord(name: "Mastercraft Plumbing & Repairs", category: "Repairs & Maintenance", contactInfo: "+1 (555) 018-7722"),
                    VendorRecord(name: "GreenThumb Grounds & Landscaping", category: "Grounds & Lawn", contactInfo: "+1 (555) 012-3344")
                ],
                defaultServices: [
                    ExpenseServicePreset(name: "Elevator Maintenance", defaultDescription: "Monthly periodic elevator safety inspection, lubrication, and service", iconName: "arrow.up.and.down.circle.fill", suggestedVendor: "Apex Elevator Services Inc."),
                    ExpenseServicePreset(name: "Janitorial & Supplies", defaultDescription: "Common area janitorial cleaning services and hygiene supplies", iconName: "sparkles", suggestedVendor: "CleanPro Facilities LLC"),
                    ExpenseServicePreset(name: "Common Utilities & Power", defaultDescription: "Common stairwell lighting, water booster pump, and outdoor electric bill", iconName: "bolt.fill", suggestedVendor: "City Power & Utilities Co."),
                    ExpenseServicePreset(name: "Facility Repairs & Plumbing", defaultDescription: "Facility maintenance, emergency plumbing, and common repairs labor", iconName: "wrench.and.screwdriver.fill", suggestedVendor: "Mastercraft Plumbing & Repairs"),
                    ExpenseServicePreset(name: "Grounds & Landscaping", defaultDescription: "Garden upkeep, lawn mowing, and exterior landscaping service", iconName: "leaf.fill", suggestedVendor: "GreenThumb Grounds & Landscaping")
                ]
            )
        }
    }
}

// MARK: - 1-to-1 Localization Store (L10n)

struct L10n {
    let language: AppLanguage

    init(_ language: AppLanguage = .english) {
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
    var appTitle: String { "AptReceipt" }
    var appSubtitle: String { tr("Easily manage and export apartment income and expense receipts", "Gelir ve gider makbuzlarınızı kolayca yönetin ve dışa aktarın", "Gestionați și exportați cu ușurință chitanțele de încasări și plăți") }
    var preferences: String { tr("Preferences", "Tercihler", "Preferințe") }
    var settingsTitle: String { tr("Preferences & Settings", "Tercihler & Ayarlar", "Preferințe & Setări") }
    var settingsSubtitle: String { tr("Configure building details, language, theme, and signature", "Apartman bilgileri, dil, tema ve imzanızı düzenleyin", "Configurați datele imobilului, limba, tema și semnătura") }

    // Receipt Type
    var receiptType: String { tr("Receipt Type", "Makbuz Türü", "Tip Chitanță") }
    var incomeTitle: String { tr("Income (Collection)", "Gelir (Tahsilat)", "Încasare (Întreținere)") }
    var outcomeTitle: String { tr("Resident Refund", "Sakin İadesi", "Restituire Locatar") }
    var managementExpenseTitle: String { tr("Management Expense", "Yönetim Harcaması", "Cheltuieli Administrație") }
    var incomeBadge: String { tr("INCOME RECEIPT", "TAHSİLAT MAKBUZU", "CHITANȚĂ DE ÎNCASARE") }
    var outcomeBadge: String { tr("REFUND RECEIPT", "GİDER / İADE MAKBUZU", "DISPOZIȚIE DE PLATĂ") }
    var managementExpenseBadge: String { tr("OPERATING EXPENSE", "İŞLETME GİDERİ", "CHELTUIALĂ ADMINISTRAȚIE") }

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
    var amount: String { tr("Amount", "Tutar", "Sumă") }
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
    var expenseDocumentType: String { tr("Resident Refund Voucher", "Sakin İade / Tediye Makbuzu", "Dispoziție de Plată Locatar") }
    var managementExpenseDocumentType: String { tr("Operating Expenditure Voucher", "Yönetim İşletme Gider Belgesi", "Dispoziție de Plată Cheltuieli Administrative") }
    var defaultItemNameIncome: String { tr("Common Expense & Dues Contribution", "Ortak Gider ve Aidat Avans Katılım Payı", "Cotă întreținere și fond de rulment") }
    var defaultItemNameExpense: String { tr("Resident Expense Reimbursement / Refund", "Sakin İade ve Mahsup Ödemesi", "Restituire avans / decont locatar") }
    var defaultItemNameManagementExpense: String { tr("Building Maintenance & Operating Expense", "Bina İşletme, Bakım ve Hizmet Alım Gideri", "Servicii de întreținere și reparații imobil") }
    var commonAreaLabel: String { tr("Common Area / General", "Ortak Alan / Genel", "Spații Comune / General") }
    var invoiceBuildingLabel: String { tr("Building:", "Bina / Site:", "Imobil / Asociație:") }
    var invoiceManagerLabel: String { tr("Manager:", "Yönetici:", "Administrator:") }
    var invoicePayerResidentLabel: String { tr("Resident / Payer:", "Sakin / Muhatap:", "Locatar / Proprietar:") }
    var invoiceVendorLabel: String { tr("Payee / Vendor:", "Ödeme Yapılan:", "Furnizor / Beneficiar:") }
    var invoiceUnitLabel: String { tr("Unit / Flat:", "Bağımsız Bölüm:", "Apartament:") }
    var vendorLabel: String { tr("Vendor / Service Provider (Payee):", "Firma / Usta / Hizmet Sağlayıcı (Alacaklı):", "Furnizor / Prestator Servicii (Beneficiar):") }
    var vendorPlaceholder: String { tr("e.g. Acme Elevator Ltd. / John Technician", "Örn: Kaya Asansör Ltd. / Ahmet Usta", "Ex: Lift Service SRL / Ion Tehnician") }
    var managerPayerLabel: String { tr("Payer (Manager / Building Management):", "Ödeyen (Yönetici / Apartman Yönetimi):", "Plătitor (Administrator / Asociație):") }
    var vendorSectionTitle: String { tr("PAYEE / VENDOR & SERVICE PROVIDER", "ALACAKLI / FİRMA & HİZMET SAĞLAYICI", "BENEFICIAR / FURNIZOR SERVICII") }

    // Quick Expense Presets
    var quickPresetsLabel: String { tr("Quick Expense Presets:", "Hızlı Harcama Şablonları:", "Categorii Rapide de Cheltuieli:") }
    var presetElevator: String { tr("Elevator", "Asansör Bakımı", "Lift") }
    var presetElevatorDesc: String { tr("Elevator periodic maintenance and safety inspection", "Asansör periyodik bakım ve kontrol hizmeti", "Întreținere periodică și revizie lift") }
    var presetCleaning: String { tr("Cleaning", "Temizlik & Malzeme", "Curățenie") }
    var presetCleaningDesc: String { tr("Common area cleaning and hygiene supplies", "Apartman ortak alan temizliği ve sarf malzeme bedeli", "Curățenie spații comune și consumabile") }
    var presetUtilities: String { tr("Utilities", "Ortak Elektrik / Su", "Utilități") }
    var presetUtilitiesDesc: String { tr("Building common electricity, lighting, and utilities", "Apartman ortak alan elektrik ve aydınlatma gideri", "Utilități și energie electrică spații comune") }
    var presetRepairs: String { tr("Repairs", "Tesisat & Onarım", "Reparații") }
    var presetRepairsDesc: String { tr("Plumbing, roof, and facility repair labor", "Bina ortak tesisat bakım ve onarım işçilik bedeli", "Reparații și întreținere instalații imobil") }
    var presetGardening: String { tr("Gardening", "Bahçe & Peyzaj", "Curte & Grădină") }
    var presetGardeningDesc: String { tr("Garden, landscaping, and outdoor maintenance", "Bahçe düzenleme ve çevre bakım hizmeti", "Întreținere curte și spații verzi") }

    // Settings Tabs
    var tabBuilding: String { tr("Building", "Apartman", "Imobil") }
    var tabResidents: String { tr("Residents", "Sakinler", "Locatari") }
    var tabAppearance: String { tr("Appearance", "Görünüm", "Aspect") }
    var tabSignature: String { tr("Signature", "İmza", "Semnătură") }
    var tabBackup: String { tr("Backup", "Yedekleme", "Copie") }
    var tabAbout: String { tr("About", "Hakkında", "Despre") }

    // Archive & History Strings
    var archiveTitle: String { tr("Receipt Archive & History", "Makbuz Arşivi ve Geçmişi", "Arhivă și Istoric Chitanțe") }
    var archiveSubtitle: String { tr("Search, review, re-print, and share previously generated receipts", "Daha önce kesilen makbuzları görüntüleyin, filtreleyin, yazdırın ve paylaşın", "Vizualizați, filtrați, tipăriți și partajați chitanțele emise") }
    var archiveSearchPlaceholder: String { tr("Search flat, person, company, or notes…", "Daire no, kişi, firma veya notlarda ara…", "Caută apartament, persoană, furnizor sau notă…") }
    var filterAll: String { tr("All", "Tümü", "Toate") }
    var filterIncome: String { tr("Income", "Gelir", "Încasări") }
    var filterOutcome: String { tr("Refund", "İade", "Restituiri") }
    var filterManagement: String { tr("Management", "İşletme", "Administrație") }
    var totalArchived: String { tr("Total Archived", "Toplam Arşiv", "Total Arhivate") }
    var openReceipt: String { tr("Open Receipt", "Makbuzu Aç", "Deschide Chitanța") }
    var deleteReceipt: String { tr("Delete from Archive", "Arşivden Sil", "Șterge din Arhivă") }
    var exportCSV: String { tr("Export as CSV", "CSV Olarak Dışa Aktar", "Exportă ca CSV") }
    var archiveEmpty: String { tr("No archived receipts yet. Generated receipts will automatically appear here.", "Henüz arşivlenmiş makbuz yok. Oluşturulan makbuzlar otomatik olarak burada listelenecektir.", "Nicio chitanță arhivată încă.") }
    var archiveButton: String { tr("Archive", "Arşiv", "Arhivă") }

    // WhatsApp & Sharing Strings
    var shareWhatsApp: String { tr("Share via WhatsApp", "WhatsApp ile Paylaş", "Trimite pe WhatsApp") }
    var shareEmail: String { tr("Send via Email", "E-posta ile Gönder", "Trimite prin Email") }
    var residentPhone: String { tr("Phone / WhatsApp:", "Telefon / WhatsApp:", "Telefon / WhatsApp:") }
    var residentPhonePlaceholder: String { tr("e.g. +90 532 123 45 67", "Örn: 0532 123 45 67", "Ex: +40 721 123 456") }

    // Invoice Import & Attachment Strings
    var importInvoice: String { tr("Import Invoice / Receipt (PDF or Image)", "Fatura / Fiş İçe Aktar (PDF veya Görsel)", "Importă Factură / Bon (PDF sau Imagine)") }
    var dropInvoiceSubtitle: String { tr("Choose or drag & drop PDF/image • Auto-fills via Apple Vision", "PDF veya görsel seçin • Apple Vision ile otomatik doldurulur", "Alegeți PDF sau imagine • Se completează automat prin Apple Vision") }
    var scanningInvoice: String { tr("Scanning & analyzing invoice via Apple Vision…", "Apple Vision ile fatura taranıyor ve analiz ediliyor…", "Se scanează și se analizează factura prin Apple Vision…") }
    var invoiceScanSuccess: String { tr("Invoice imported", "Fatura içe aktarıldı", "Factură importată") }
    var attachedInvoice: String { tr("Attached Invoice", "Ekli Fatura", "Factură Atașată") }
    var viewInvoice: String { tr("View", "Görüntüle", "Vizualizează") }
    var removeInvoice: String { tr("Remove Invoice", "Faturayı Kaldır", "Elimină Factura") }
    var invoiceNumberPrefix: String { tr("Invoice No", "Fatura No", "Factura Nr") }
    var viewAttachedInvoice: String { tr("Attached Invoice", "Ekli Faturayı Aç", "Deschide Factura") }

    // QR Code Verification Strings
    var qrVerificationNotice: String { tr("Scan with phone camera to verify receipt authenticity", "Belge doğruluğunu teyit etmek için telefon kamerasıyla okutunuz", "Scanați cu camera telefonului pentru a verifica autenticitatea chitanței") }
    var qrCodeActive: String { tr("Verifiable QR Code Active", "Doğrulanabilir QR Kod Aktif", "Cod QR de Verificare Activ") }

    // Backup & Restore Strings
    var backupTitle: String { tr("Data Backup & Restore", "Veri Yedekleme ve Geri Yükleme", "Salvare & Restaurare Date") }
    var backupSubtitle: String { tr("Export your entire apartment configuration, residents, vendors, and receipt archive to a single JSON file, or restore from a previous backup", "Tüm apartman ayarları, sakinler, firmalar ve makbuz arşivinizi tek bir JSON dosyasına yedekleyin veya geri yükleyin", "Exportați sau restaurați configurările, locatarii, furnizorii și arhiva într-un singur fișier JSON") }
    var exportBackupButton: String { tr("Export Full System Backup (.json)…", "Tam Sistem Yedeğini Dışa Aktar (.json)…", "Exportă Copie de Siguranță (.json)…") }
    var importBackupButton: String { tr("Restore from Backup File (.json)…", "Yedek Dosyasından Geri Yükle (.json)…", "Restaurează din Fișier (.json)…") }
    var backupExportSuccess: String { tr("Backup exported successfully.", "Yedekleme başarıyla dışa aktarıldı.", "Copie salvată cu succes.") }
    var backupImportSuccess: String { tr("All data and archive restored successfully.", "Tüm veriler ve arşiv başarıyla geri yüklendi.", "Datele și arhiva au fost restaurate cu succes.") }
    var backupImportError: String { tr("Failed to read backup file or invalid format.", "Yedek dosyası okunamadı veya dosya biçimi geçersiz.", "Eroare la citirea copiei de siguranță.") }
    var backupNotice: String { tr("Backups contain all resident records, custom vendors, expense services, and receipt history in a portable format.", "Yedek dosyası tüm sakin kayıtlarını, firma listesini, işletme hizmetlerini ve makbuz geçmişini taşınabilir formatta içerir.", "Fișierul de siguranță conține toți locatarii, furnizorii și istoricul chitanțelor.") }

    // Financial Report & Bulletin Board Strings
    var financialReportTitle: String { tr("Financial Report & Cash Balance", "Mali Rapor & Kasa Özeti", "Raport Financiar & Sold Casierie") }
    var financialReportSubtitle: String { tr("Monthly cash flow statement, income vs expense balance, dues status, and bulletin board notice", "Aylık gelir-gider bilançosu, kasa mevcudu, aidat takip çetelesi ve apartman pano ilanı", "Situație financiară lunară, venituri vs cheltuieli, evidență întreținere și afiș avizier") }
    var exportBulletinBoardPDF: String { tr("Export Notice Board PDF (A4)", "Pano İlanı PDF İndir (A4)", "Exportă Afiș Avizier PDF (A4)") }
    var totalIncome: String { tr("Total Income", "Toplam Gelir", "Total Încasări") }
    var totalExpenses: String { tr("Total Expenses", "Toplam Harcama", "Total Cheltuieli") }
    var netCashBalance: String { tr("Net Cash Balance", "Net Kasa Bakiyesi", "Sold Net Casierie") }
    var allMonths: String { tr("All Months (Total)", "Tüm Aylar (Genel)", "Toate Lunile (Total)") }
    var duesTrackingTab: String { tr("Dues Status Check", "Aidat Çetelesi", "Evidență Întreținere") }
    var financialSummaryTab: String { tr("Cash Summary", "Kasa Özeti", "Sumar Casierie") }
    var allTransactionsTab: String { tr("Transactions", "Tüm İşlemler", "Toate Operațiunile") }
    var paidStatus: String { tr("Paid", "Ödendi", "Achitat") }
    var unpaidStatus: String { tr("Pending / Unpaid", "Ödenmedi / Bekliyor", "Neachitat / În Așteptare") }
    var remindWhatsApp: String { tr("Remind via WhatsApp", "WhatsApp ile Hatırlat", "Amintește pe WhatsApp") }
    var duesPaidCount: String { tr("Paid Flats", "Ödeyen Daireler", "Apartamente Achitate") }
    var duesPendingCount: String { tr("Pending Flats", "Bekleyen Daireler", "Apartamente În Așteptare") }
    var bulletinBoardNoticeTitle: String { tr("APARTMENT FINANCIAL BULLETIN BOARD NOTICE", "APARTMAN YÖNETİMİ MALİ BİLANÇO VE KASA RAPORU", "RAPORT FINANCIAR ȘI SITUAȚIE CASIERIE") }
    var bulletinBoardNoticeFooter: String { tr("Presented for the information of all residents.", "Tüm apartman sakinlerimizin bilgisine saygıyla sunulur.", "Prezentat spre informarea tuturor locatarilor.") }
    var managerSignatureTitle: String { tr("Building Manager", "Bina / Site Yöneticisi", "Administrator Imobil") }

    // Batch Dues Generation Strings
    var batchDuesTitle: String { tr("Batch Dues Generator", "Toplu Aidat Makbuzu Kes", "Generare Colectivă Chitanțe") }
    var batchDuesSubtitle: String { tr("Generate dues receipts for all registered flats for the selected month in one click", "Seçilen ay için tüm kayıtlı dairelere tek tıkla ardışık aidat makbuzu oluşturun", "Generați chitanțe de întreținere pentru toate apartamentele într-un singur clic") }
    var startSequenceNumber: String { tr("Starting Receipt #:", "Başlangıç Makbuz No:", "Număr Inițial Chitanță:") }
    var duesAmountPerFlat: String { tr("Dues Amount per Flat:", "Daire Başı Aidat Tutarı:", "Sumă Întreținere per Apartament:") }
    var generateBatchReceipts: String { tr("Generate Receipts & Add to Archive", "Makbuzları Kes ve Arşive Ekle", "Generează Chitanțele și Salvează") }
    var batchSuccessMessage: String { tr("receipts generated and added to archive successfully.", "adet makbuz başarıyla kesilip arşive eklendi.", "chitanțe au fost generate și adăugate în arhivă cu succes.") }
    var selectAll: String { tr("Select All", "Tümünü Seç", "Selectează Tot") }
    var deselectAll: String { tr("Deselect All", "Seçimi Kaldır", "Deselectează Tot") }

    // MARK: - Late Payment Compensation & Penalty Strings
    var lateFeeTitle: String { tr("Late Payment Compensation & Penalty", "Gecikme Tazminatı & Faiz Oranları", "Penalități de Întârziere") }
    var lateFeeSubtitle: String { tr("Configure statutory or custom late payment rates, grace periods, and receipt citations by country", "Ülke bazlı yasal veya serbest gecikme faizi, ek süre ve makbuz dipnotlarını yapılandırın", "Configurați ratele de penalizare, perioadele de grație și notele legale specifice fiecărei țări") }
    var lateFeeEnabledToggle: String { tr("Enable Late Compensation Calculation", "Gecikme Tazminatı Hesaplama", "Activare Calcul Penalități Întârziere") }
    var lateFeeCountryProfileTitle: String { tr("Jurisdiction & Country Profile:", "Yargı Alanı ve Ülke Profili:", "Jurisdicție & Profil Țară:") }
    var lateFeeMonthlyRateTitle: String { tr("Monthly Late Fee Rate (%):", "Aylık Gecikme Oranı (%):", "Rată Lunară Penalizare (%):") }
    var lateFeeDueDayTitle: String { tr("Payment Due Day of Month:", "Son Ödeme Günü (Vade):", "Zi Limită de Plată:") }
    var lateFeeGracePeriodTitle: String { tr("Grace Period (Days):", "Ek Süre / Tolerans (Gün):", "Perioadă de Grație (Zile):") }
    var lateFeeCustomFootnoteTitle: String { tr("Receipt Legal Footnote:", "Makbuz Hukuki Dipnot Metni:", "Notă Legală pe Chitanță:") }
    var lateFeeResetFootnoteButton: String { tr("Reset to Country Default", "Ülke Varsayılanına Sıfırla", "Revenire la Textul Implicit") }
    var lateFeeShortBadge: String { tr("Late Fee", "Gecikme", "Penalizare") }
    var lateFeeDisabledInSettingsNotice: String { tr("Late payment compensation is disabled in Preferences.", "Gecikme tazminatı hesaplaması Tercihler'den kapatılmıştır.", "Calculul penalităților este dezactivat din Preferințe.") }
    var lateFeeLegalNotice: String { tr("Under Article 20/c of Property Law No. 634, a 5% monthly compensation is legally applied to overdue dues. You can customize the rate manually above.", "634 sayılı Kat Mülkiyeti Kanunu Madde 20/c gereği vaktinde ödenmeyen aidata aylık %5 kanuni gecikme tazminatı uygulanır. Dilediğiniz takdirde oranı ve vadeyi buradan manuel değiştirebilirsiniz.", "Conform art. 20/c din Legea Asociațiilor, se aplică 5% penalizare lunară. Puteți modifica manual procentul de mai sus.") }
    var lateFeeApplyCheckbox: String { tr("Apply Late Payment Compensation", "Gecikme Tazminatı Ekle", "Aplică Penalități de Întârziere") }
    var overdueMonthsCount: String { tr("Overdue Duration:", "Gecikme Süresi:", "Durată Întârziere:") }
    var monthUnit: String { tr("Month", "Ay", "Lună") }
    var monthsUnit: String { tr("Months", "Ay", "Luni") }
    var autoDetectOverdue: String { tr("Auto-Detect Delay", "Gecikmeyi Otomatik Hesapla", "Detectare Automată") }
    var baseDuesAmount: String { tr("Base Dues:", "Aidat Ana Para:", "Cotă de Bază:") }
    var lateFeeCalculated: String { tr("Late Fee:", "Gecikme Tazminatı:", "Penalitate:") }
    var totalWithLateFee: String { tr("Total Collected:", "Toplam Tahsilat:", "Total Încasat:") }
    var statutoryRateChip: String { tr("%5.0 (Statutory)", "%5.0 (Kanuni)", "%5.0 (Legal)") }
    var dueDayDayPrefix: String { tr("Day", "Ayın", "Ziua") }
    var dueDayDaySuffix: String { tr("of each month", ". gününe kadar", "a fiecărei luni") }
    func lateFeeItemName(rate: Double, months: Int) -> String {
        tr("Late Fee (%\(String(format: "%.1f", rate)) × \(months) \(months > 1 ? "Months" : "Month"))",
           "Gecikme Tazminatı (%\(String(format: "%.1f", rate)) × \(months) Ay)",
           "Penalități Întârziere (%\(String(format: "%.1f", rate)) × \(months) \(months > 1 ? "Luni" : "Lună"))")
    }
    var lateFeeStatutoryFootnote: String {
        tr("* Calculated pursuant to Article 20/c of Property Law No. 634.",
           "* 634 Sayılı Kat Mülkiyeti Kanunu Madde 20/c uyarınca hesaplanmıştır.",
           "* Calculat conform art. 20/c din legislația asociațiilor de proprietari.")
    }

    // Settings Form Fields
    var buildingDetails: String { tr("Building Information", "Apartman Bilgileri", "Informații Imobil / Asociație") }
    var buildingName: String { tr("Building Name:", "Apartman Adı:", "Nume Imobil / Asociație:") }
    var defaultManager: String { tr("Default Manager (Collector):", "Varsayılan Yönetici (Tahsil Eden):", "Administrator Implicit (Casier):") }
    var totalFlats: String { tr("Total Number of Flats:", "Toplam Daire Sayısı:", "Număr Total Apartamente:") }
    var financialSettings: String { tr("Financial & Receipt Defaults", "Mali & Makbuz Değerleri", "Setări Financiare & Valori Implicite") }
    var defaultDues: String { tr("Default Dues Amount:", "Varsayılan Aidat Tutarı:", "Sumă Cotă Implicită:") }
    var nextReceiptNo: String { tr("Next Receipt No:", "Sıradaki Makbuz No:", "Număr Următor Chitanță:") }

    // Currency Strings
    var currencySection: String { tr("Currency & Formatting", "Para Birimi ve Biçimlendirme", "Monedă & Formatare") }
    var currencySelection: String { tr("Default Currency:", "Varsayılan Para Birimi:", "Monedă Implicită:") }
    var currencyTRY: String { tr("Turkish Lira", "Türk Lirası", "Liră Turcească") }
    var currencyRON: String { tr("Romanian Leu", "Rumen Leyi", "Leu Românesc") }
    var currencyUSD: String { tr("US Dollar", "Amerikan Doları", "Dolar SUA") }
    var currencyEUR: String { tr("Euro", "Euro", "Euro") }
    var currencyGBP: String { tr("British Pound", "İngiliz Sterlini", "Liră Sterlină") }

    // MARK: - Menu Bar Strings
    var menuApp: String { "AptReceipt" }
    var menuFile: String { tr("File", "Dosya", "Fișier") }
    var menuEdit: String { tr("Edit", "Düzenle", "Editare") }
    var menuView: String { tr("View", "Görünüm", "Vizualizare") }
    var menuWindow: String { tr("Window", "Pencere", "Fereastră") }
    var menuHelp: String { tr("Help", "Yardım", "Ajutor") }

    // App Submenu
    var menuAboutApp: String { tr("About AptReceipt", "AptReceipt Hakkında", "Despre AptReceipt") }
    var menuSettings: String { tr("Settings…", "Ayarlar…", "Configurări…") }
    var menuServices: String { tr("Services", "Servisler", "Servicii") }
    var menuHideApp: String { tr("Hide AptReceipt", "AptReceipt'i Gizle", "Ascunde AptReceipt") }
    var menuHideOthers: String { tr("Hide Others", "Diğerlerini Gizle", "Ascunde celelalte") }
    var menuShowAll: String { tr("Show All", "Tümünü Göster", "Afișează toate") }
    var menuQuitApp: String { tr("Quit AptReceipt", "AptReceipt'ten Çık", "Închide AptReceipt") }

    // File Submenu
    var menuNewWindow: String { tr("New Receipt", "Yeni Makbuz", "Chitanță nouă") }
    var menuCloseWindow: String { tr("Close Window", "Pencereyi Kapat", "Închide fereastra") }

    // Edit Submenu
    var menuUndo: String { tr("Undo", "Geri Al", "Anulează") }
    var menuRedo: String { tr("Redo", "Yinele", "Refă") }
    var menuCut: String { tr("Cut", "Kes", "Decupează") }
    var menuCopy: String { tr("Copy", "Kopyala", "Copiază") }
    var menuPaste: String { tr("Paste", "Yapıştır", "Lipește") }
    var menuPasteAndMatch: String { tr("Paste and Match Style", "Yapıştır ve Stili Eşleştir", "Lipește și potrivește stilul") }
    var menuDelete: String { tr("Delete", "Sil", "Șterge") }
    var menuSelectAll: String { tr("Select All", "Tümünü Seç", "Selectează tot") }

    // View Submenu
    var menuFullScreen: String { tr("Toggle Full Screen", "Tam Ekrana Geç", "Comută pe ecran complet") }

    // Window Submenu
    var menuMinimize: String { tr("Minimize", "Simge Durumuna Küçült", "Minimizează") }
    var menuZoom: String { tr("Zoom", "Büyüt", "Zoom") }
    var menuBringAllToFront: String { tr("Bring All to Front", "Tümünü Öne Getir", "Adu toate în față") }

    // Help Submenu
    var menuHelpItem: String { tr("AptReceipt Help", "AptReceipt Yardımı", "Ajutor AptReceipt") }

    // Language Restart Warning Strings
    var restartWarningTitle: String { tr("Application Restart Recommended", "Uygulamanın Yeniden Başlatılması Önerilir", "Repornirea Aplicației Recomandată") }
    var restartMenuBarNotice: String { tr("Menubar and interface are dynamically translated. Restarting the application is recommended to also reload system-level dialogs.", "Menü çubuğu ve arayüz dinamik olarak çevrilir. Sistem düzeyindeki iletişim kutularının da güncellenmesi için uygulamanın yeniden başlatılması önerilir.", "Bara de meniu și interfața sunt traduse dinamic. Se recomandă repornirea aplicației pentru actualizarea ferestrelor de dialog de sistem.") }

    // Sample Defaults Strings
    var sampleDefaultsSection: String { tr("Sample Defaults", "Örnek Değerler", "Valori Exemplu") }
    var sampleDefaultsDesc: String { tr("Quickly populate building, manager, and resident data with realistic samples for the selected language.", "Seçilen dile uygun gerçekçi apartman, yönetici ve sakin örnek verilerini forma yükleyin.", "Completați rapid datele imobilului, administratorului și locatarilor cu valori exemplu.") }
    var loadSampleDefaultsButton: String { tr("Load Sample Defaults", "Varsayılan Örnek Değerleri Yükle", "Încarcă Valori Exemplu") }
    var sampleDefaultsLoadedFeedback: String { tr("Sample defaults loaded successfully.", "Örnek değerler başarıyla yüklendi.", "Valorile exemplu au fost încărcate cu succes.") }

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
    var totalFlatsBadge: String { tr("Total Flats", "Toplam Daire", "Total Apartamente") }
    var registeredResidentsBadge: String { tr("Registered", "Kayıtlı", "Înregistrați") }
    var vacantFlatsBadge: String { tr("Unassigned", "Boş / İsimsiz", "Neatribuiți") }
    var searchNeighborsPlaceholder: String { tr("Search flat or resident…", "Daire no veya sakin adıyla ara…", "Caută apartament sau locatar…") }
    var fillSampleResidentsButton: String { tr("Fill Sample Residents", "Örnek Sakinleri Doldur", "Completează locatari exemplu") }
    var clearAllResidentsButton: String { tr("Clear All", "Tümünü Temizle", "Șterge toți") }
    var flatUnassigned: String { tr("No resident assigned", "Sakin ismi girilmedi", "Niciun locatar înregistrat") }
    var flatAssigned: String { tr("Registered Resident", "Kayıtlı Sakin", "Locatar Înregistrat") }
    var noMatchingResidents: String { tr("No matching flats found.", "Aramanızla eşleşen daire bulunamadı.", "Niciun apartament găsit.") }

    // Signature Tab
    var signatureTitle: String { tr("Authorized Signature", "Yetkili İmzası", "Semnătură Autorizată") }
    var signatureDesc: String { tr("Upload the signature image (PNG or JPG) to appear at the bottom of receipts.", "Makbuzların alt kısmında yer alacak imza görselini (PNG veya JPG) yükleyin.", "Încărcați imaginea semnăturii pentru a apărea pe chitanțe.") }
    var uploadSignatureButton: String { tr("Upload Signature Image...", "İmza Görseli Yükle...", "Încarcă Imagine Semnătură...") }
    var removeSignatureButton: String { tr("Remove Signature", "İmzayı Kaldır", "Șterge Semnătura") }
    var loadedSignature: String { tr("Loaded Signature", "Yüklü İmza", "Semnătură Încărcată") }
    var noSignatureYet: String { tr("No signature uploaded yet", "Henüz imza yüklenmedi", "Nicio semnătură încărcată încă") }

    // About Tab & License
    var appVersionText: String { tr("Version 3.3.0 (Build 6)", "Sürüm 3.3.0 (Yapı 6)", "Versiunea 3.3.0 (Build 6)") }
    var publisher: String { tr("Publisher: Babadogan Tech and Edu", "Yayıncı: Babadogan Tech and Edu", "Editor: Babadogan Tech and Edu") }
    var license: String { tr("License: GNU General Public License v3.0 (GPL-3.0)", "Lisans: GNU Genel Kamu Lisansı v3.0 (GPL-3.0)", "Licență: GNU General Public License v3.0 (GPL-3.0)") }
    var copyright: String { tr("Copyright © 2023-2026 Babadogan Tech and Edu. All rights reserved.", "Copyright © 2023-2026 Babadogan Tech and Edu. Tüm hakları saklıdır.", "Copyright © 2023-2026 Babadogan Tech and Edu. Toate drepturile rezervate.") }
    var viewLicenseButton: String { tr("View License (GNU GPL v3)", "Lisansı Görüntüle (GNU GPL v3)", "Vizualizează Licența (GNU GPL v3)") }
    var licenseViewerTitle: String { tr("GNU General Public License v3.0", "GNU Genel Kamu Lisansı v3.0", "Licența Publică Generală GNU v3.0") }
    var licenseViewerSubtitle: String { tr("Free and open-source software license. Publisher: Babadogan Tech and Edu", "Özgür ve açık kaynak kodlu yazılım lisansı. Yayıncı: Babadogan Tech and Edu", "Licență software liberă și cu sursă deschisă. Editor: Babadogan Tech and Edu") }
    var copyLicenseText: String { tr("Copy License Text", "Lisans Metnini Kopyala", "Copiază Textul Licenței") }
    var licenseCopied: String { tr("Copied!", "Kopyalandı!", "Copiat!") }
    var aboutWindowHeader: String { tr("About AptReceipt", "AptReceipt Hakkında", "Despre AptReceipt") }
    var githubRepository: String { tr("GitHub Repository", "GitHub Deposu", "Depozit GitHub") }
    var appDescription: String { tr("Modern, secure and trilingual apartment dues & expense receipt generator.", "Modern, güvenli ve üç dilli apartman aidat ve gider makbuzu oluşturucu.", "Generator modern, sigur și trilingv de chitanțe de încasare și dispoziții de plată.") }

    // Software Update Strings
    var checkForUpdates: String { tr("Check for Updates...", "Güncellemeleri Denetle...", "Caută Actualizări...") }
    var checkForUpdatesButton: String { tr("Check for Updates", "Güncellemeleri Denetle", "Caută Actualizări") }
    var checkingForUpdates: String { tr("Checking for updates...", "Güncellemeler denetleniyor...", "Se caută actualizări...") }
    var updateAvailableTitle: String { tr("New Version Available!", "Yeni Bir Sürüm Mevcut!", "O Nouă Versiune este Disponibilă!") }
    var upToDateTitle: String { tr("You're Up to Date", "AptReceipt Güncel", "Aplicația este la Zi") }
    var upToDateMessage: String { tr("AptReceipt %@ is currently the newest version.", "AptReceipt %@ şu anda en güncel sürümdür.", "AptReceipt %@ este în prezent cea mai recentă versiune.") }
    var downloadUpdate: String { tr("Download Update", "Güncellemeyi İndir", "Descarcă Actualizarea") }
    var laterButton: String { tr("Later", "Daha Sonra", "Mai Târziu") }
    var updateCheckFailedTitle: String { tr("Update Check Failed", "Güncelleme Denetlenemedi", "Verificarea Actualizării a Eșuat") }
    var updateCheckFailedMessage: String { tr("Unable to reach GitHub Releases. Please check your internet connection.", "GitHub Releases sunucusuna bağlanılamadı. Lütfen internet bağlantınızı kontrol edin.", "Nu s-a putut contacta serverul GitHub. Verificați conexiunea la internet.") }
    var openReleasesPage: String { tr("View Releases on GitHub", "GitHub Sürümler Sayfasını Aç", "Deschide Pagina de Lansări") }
    var isNowAvailableText: String { tr("is now available", "artık indirilebilir", "este acum disponibilă") }
    var currentVersionPrefix: String { tr("you have", "mevcut sürümünüz", "aveți versiunea") }
    var lastChecked: String { tr("Last checked:", "Son denetleme:", "Ultima verificare:") }
    var neverChecked: String { tr("Never", "Henüz yapılmadı", "Niciodată") }
    var softwareUpdateSection: String { tr("Software Updates", "Yazılım Güncellemeleri", "Actualizări Software") }
    var softwareUpdateDesc: String { tr("Check GitHub for official AptReceipt releases, new features, and bug fixes.", "En son AptReceipt sürümleri, yeni özellikler ve hata düzeltmeleri için GitHub'ı denetleyin.", "Verificați GitHub pentru cele mai recente versiuni AptReceipt.") }
    var downloadingUpdateTitle: String { tr("Downloading Update", "Güncelleme İndiriliyor", "Se Descarcă Actualizarea") }
    var cancelDownloadButton: String { tr("Cancel", "İptal", "Anulează") }
    var updateDownloadedTitle: String { tr("Update Downloaded", "Güncelleme İndirildi", "Actualizare Descărcată") }
    var updateDownloadedMessage: String { tr("%@ was saved to your Downloads folder and opened.\n\nQuit AptReceipt, drag the new version onto Applications and choose Replace, then open it again.\n\nIf macOS blocks the first launch, allow it in System Settings → Privacy & Security → Open Anyway.", "%@ İndirilenler klasörüne kaydedildi ve açıldı.\n\nAptReceipt'ten çıkın, yeni sürümü Applications (Uygulamalar) klasörüne sürükleyip Değiştir'i seçin, ardından yeniden açın.\n\nmacOS ilk açılışı engellerse Sistem Ayarları → Gizlilik ve Güvenlik → Yine de Aç ile izin verin.", "%@ a fost salvat în dosarul Descărcări și deschis.\n\nÎnchideți AptReceipt, trageți noua versiune în Applications (Aplicații) și alegeți Înlocuire, apoi deschideți-o din nou.\n\nDacă macOS blochează prima lansare, permiteți-o din Configurări sistem → Confidențialitate și securitate → Deschide oricum.") }
    var updateDownloadedNotOpenedMessage: String { tr("%@ was saved to your Downloads folder, but macOS blocked opening it because the update is not notarized by Apple.\n\nOpen System Settings → Privacy & Security and click Open Anyway for the disk image (or run xattr -d com.apple.quarantine on it in Terminal). Then quit AptReceipt, drag the new version onto Applications and choose Replace.", "%@ İndirilenler klasörüne kaydedildi, ancak güncelleme Apple tarafından notarize edilmediği için macOS açılmasını engelledi.\n\nSistem Ayarları → Gizlilik ve Güvenlik bölümünde disk görüntüsü için Yine de Aç'a tıklayın (veya Terminal'de dosyaya xattr -d com.apple.quarantine uygulayın). Ardından AptReceipt'ten çıkın, yeni sürümü Applications (Uygulamalar) klasörüne sürükleyip Değiştir'i seçin.", "%@ a fost salvat în dosarul Descărcări, dar macOS a blocat deschiderea deoarece actualizarea nu este notarizată de Apple.\n\nDeschideți Configurări sistem → Confidențialitate și securitate și apăsați Deschide oricum pentru imaginea de disc (sau rulați xattr -d com.apple.quarantine pe fișier în Terminal). Apoi închideți AptReceipt, trageți noua versiune în Applications (Aplicații) și alegeți Înlocuire.") }
    var quitAndInstallButton: String { tr("Quit AptReceipt", "AptReceipt'ten Çık", "Închide AptReceipt") }
    var showInFinderButton: String { tr("Show in Finder", "Finder'da Göster", "Arată în Finder") }
    var updateDownloadFailedTitle: String { tr("Update Download Failed", "Güncelleme İndirilemedi", "Descărcarea Actualizării a Eșuat") }
    var updateDownloadFailedMessage: String { tr("The update could not be downloaded or verified. You can download it manually from GitHub.", "Güncelleme indirilemedi veya doğrulanamadı. GitHub üzerinden elle indirebilirsiniz.", "Actualizarea nu a putut fi descărcată sau verificată. O puteți descărca manual de pe GitHub.") }

    // Validation Messages
    var validationErrorTitle: String { tr("Validation Error", "Doğrulama Hatası", "Eroare de Validare") }
    var okButton: String { tr("OK", "Tamam", "OK") }
    var errIssuerRequired: String { tr("Collector information is required.", "Tahsil eden (yetkili) bilgisi zorunludur.", "Informațiile administratorului/casierului sunt obligatorii.") }
    var errReceiverRequired: String { tr("Payer information is required.", "Ödeyen (muhatap) bilgisi zorunludur.", "Informațiile plătitorului sunt obligatorii.") }
    var errSequenceInvalid: String { tr("Sequence number must be a positive integer.", "Sıra numarası pozitif bir tam sayı olmalıdır.", "Numărul de serie trebuie să fie un număr întreg pozitiv.") }
    var errAmountInvalid: String { tr("Amount must be a valid number.", "Tutar geçerli bir sayı olmalıdır.", "Suma trebuie să fie un număr valid.") }
    var errBuildingIssuerRequired: String { tr("Building name and default manager cannot be empty.", "Apartman adı ve varsayılan yönetici boş bırakılamaz.", "Numele imobilului și administratorul nu pot fi goale.") }
    var errFlatCountInvalid: String { tr("Flat count must be a positive integer.", "Daire sayısı pozitif bir tam sayı olmalıdır.", "Numărul de apartamente trebuie să fie pozitiv.") }

    // Placeholders & Labels
    var buildingNamePlaceholder: String { tr("e.g. Sunshine Residence", "Örn: Güleryüz Apartmanı", "Ex: Asociația Parcul Tineretului") }
    var defaultManagerPlaceholder: String { tr("e.g. John Doe", "Örn: Ahmet Yılmaz", "Ex: Andrei Popescu") }
    var totalFlatsPlaceholder: String { tr("e.g. 12", "Örn: 12", "Ex: 12") }
    var publisherLabel: String { tr("Publisher", "Yayıncı", "Editor") }
    var licenseLabel: String { tr("License", "Lisans", "Licență") }

    // Building Logo
    var buildingLogoSection: String { tr("Building / Site Logo", "Bina / Site Logosu", "Siglă / Logo Imobil") }
    var buildingLogoDesc: String { tr("Upload your building or community logo (PNG or JPG). If none is uploaded, a clean default 2D logo will be displayed on receipts.", "Makbuzlarda yer alacak bina veya site logosunu (PNG veya JPG) yükleyin. Yüklenmezse şık bir varsayılan 2D logo kullanılır.", "Încărcați sigla asociației sau a imobilului (PNG sau JPG). Dacă nu este adăugată, pe chitanțe va apărea o siglă 2D implicită.") }
    var uploadLogoButton: String { tr("Upload Building Logo...", "Site Logosu Yükle...", "Încarcă Siglă Imobil...") }
    var removeLogoButton: String { tr("Remove Logo", "Logoyu Kaldır", "Șterge Sigla") }
    var activeLogoBadge: String { tr("Custom Logo Active", "Özel Logo Yüklendi", "Siglă Personalizată Activă") }
    var default2DLogoBadge: String { tr("Default 2D Logo Active", "Varsayılan 2D Logo Aktif", "Siglă 2D Implicită Activă") }

    // Settings Hero Strings
    var buildingHeroBadge: String { tr("BUILDING PROFILE", "BİNA PROFİLİ", "PROFIL IMOBIL") }
    var heroQuickFlats: String { tr("Quick Presets:", "Hızlı Daire Seçimi:", "Presetări Rapide:") }
    var heroStatsFlats: String { tr("Flats", "Daire", "Apartamente") }
    var heroStatsManager: String { tr("Manager", "Yönetici", "Administrator") }
    var heroStatsDues: String { tr("Monthly Dues", "Aylık Aidat", "Cotă Lunară") }
    var heroStatsNextReceipt: String { tr("Next No", "Sonraki No", "Număr Următor") }
    var heroNotSpecified: String { tr("Not specified", "Belirtilmedi", "Nespecificat") }
    var quickScenarioTitle: String { tr("Starter Scenarios & Presets", "Hızlı Başlangıç Senaryoları", "Scenarii Rapide de Pornire") }
    var quickScenarioSubtitle: String { tr("Populate full realistic building data sets for quick testing or onboarding", "Hızlı deneme veya ilk kurulum için hazır örnek verileri tek tıkla yükleyin", "Completați seturi complete de date reale pentru testare rapidă") }
    var sampleScenarioTR: String { tr("Turkey / Turkish Condominium", "Türkiye / Türkçe Apartman", "Turcia / Asociație Turcă") }
    var sampleScenarioEN: String { tr("International / English Condominium", "Uluslararası / İngilizce Apartman", "Internațional / Asociație Engleză") }
    var sampleScenarioRO: String { tr("Romania / Asociație de Proprietari", "Romanya / Asociație de Proprietari", "România / Asociație de Proprietari") }
    var sampleScenarioDescTR: String { tr("Güleryüz Apt • 12 flats • 1,750 ₺ • Ahmet Yılmaz", "Güleryüz Apt • 12 daire • 1.750 ₺ • Ahmet Yılmaz", "Güleryüz Apt • 12 ap. • 1.750 ₺ • Ahmet Yılmaz") }
    var sampleScenarioDescEN: String { tr("Sunshine Residence • 12 units • $1,750 • John Doe", "Sunshine Residence • 12 daire • 1.750 $ • John Doe", "Sunshine Residence • 12 ap. • 1.750 $ • John Doe") }
    var sampleScenarioDescRO: String { tr("Asociația Parcul Tineretului • 12 ap. • 1,750 lei • Andrei Popescu", "Asociația Parcul Tineretului • 12 daire • 1.750 lei • Andrei Popescu", "Asociația Parcul Tineretului • 12 ap. • 1.750 lei • Andrei Popescu") }
    var applyScenarioButton: String { tr("Apply Preset", "Şablonu Uygula", "Aplică Șablonul") }

    // Vendors & Services Tab Strings
    var tabVendors: String { tr("Vendors", "Firmalar", "Furnizori") }
    var vendorsTitle: String { tr("Vendor Directory & Services", "Tedarikçi & Hizmet Yönetimi", "Gestiune Furnizori & Servicii") }
    var vendorsSubtitle: String { tr("Manage regular vendors, contractors, and preset operating expense services", "Düzenli çalıştığınız firma, usta ve hazır işletme gider kalemlerini yönetin", "Gestionați furnizorii uzuali și serviciile de întreținere") }
    var registeredVendorsBadge: String { tr("Registered Vendors", "Kayıtlı Firma", "Furnizori Înregistrați") }
    var presetServicesBadge: String { tr("Preset Services", "Hazır Servis", "Servicii Predefinite") }
    var addVendorButton: String { tr("Add New Vendor", "Yeni Firma Ekle", "Adaugă Furnizor Nou") }
    var vendorNameField: String { tr("Company / Vendor Name:", "Firma / Usta Adı:", "Nume Furnizor:") }
    var vendorCategoryField: String { tr("Service Category:", "Hizmet Kategorisi:", "Categorie Serviciu:") }
    var vendorContactField: String { tr("Contact / Phone / Tax ID:", "İletişim / Telefon / Vergi No:", "Contact / Telefon / CUI:") }
    var saveVendorButton: String { tr("Save Vendor", "Firmayı Kaydet", "Salvează Furnizor") }
    var deleteButton: String { tr("Delete", "Sil", "Șterge") }
    var vendorListHeader: String { tr("Saved Vendors & Contractors", "Kayıtlı Firmalar ve Ustalar", "Furnizori și Meșteri Înregistrați") }
    var serviceListHeader: String { tr("Ready-Made Expense Services", "Hazır Harcama Hizmetleri", "Servicii Predefinite de Cheltuieli") }
    var serviceNameField: String { tr("Service Title:", "Hizmet Adı:", "Denumire Serviciu:") }
    var serviceDescriptionField: String { tr("Default Description:", "Varsayılan Açıklama:", "Descriere Implicită:") }
    var serviceSuggestedVendorField: String { tr("Suggested Vendor (Optional):", "Önerilen Firma (İsteğe Bağlı):", "Furnizor Sugerat (Opțional):") }
    var addServiceButton: String { tr("Add New Service", "Yeni Servis Ekle", "Adaugă Serviciu Nou") }
    var saveServiceButton: String { tr("Save Service", "Servisi Kaydet", "Salvează Serviciu") }
    var loadSampleVendorsButton: String { tr("Restore Sample Vendors", "Örnek Tedarikçileri Yükle", "Încarcă Furnizori Exemplu") }
    var sampleVendorsLoadedFeedback: String { tr("Sample vendors and services loaded successfully.", "Örnek firma ve servisler başarıyla yüklendi.", "Furnizorii și serviciile exemplu au fost încărcate cu succes.") }
    var selectSavedVendor: String { tr("Select from Saved Vendors…", "Kayıtlı Firmalardan Seç…", "Selectează din Furnizori…") }
    var selectSavedService: String { tr("Select from Ready Services…", "Hazır Servislerden Seç…", "Selectează din Servicii…") }
    var searchVendorsPlaceholder: String { tr("Search vendor or category…", "Firma adı veya kategori ara…", "Caută furnizor sau categorie…") }
    var noVendorsFound: String { tr("No vendors found.", "Kayıtlı firma bulunamadı.", "Niciun furnizor găsit.") }
    var noServicesFound: String { tr("No preset services found.", "Kayıtlı hazır servis bulunamadı.", "Niciun serviciu găsit.") }
    var commonAreaOperatingBadge: String { tr("COMMON AREA / OPERATING EXPENDITURE", "ORTAK ALAN / BİNA İŞLETME GİDERİ", "SPAȚII COMUNE / CHELTUIELI ADMINISTRATIVE") }
    var payeeVendorCardTitle: String { tr("PAYEE (VENDOR / CONTRACTOR / SERVICE PROVIDER)", "ÖDEME YAPILAN (FİRMA / TEDARİKÇİ / USTA)", "BENEFICIAR (FURNIZOR / PRESTATOR SERVICII)") }
    var serviceExpenseCardTitle: String { tr("EXPENSE SERVICE & DESCRIPTION", "HİZMET KALEMİ VE HARCAMA AÇIKLAMASI", "SERVICIU & DESCRIERE CHELTUIALĂ") }
    var quickServicesLabel: String { tr("Ready Services (1-Click):", "Hazır Servisler (Tek Tık):", "Servicii Rapide:") }
    var customExpenseNotePlaceholder: String { tr("Describe expense or enter invoice number…", "Harcama açıklaması veya fatura no yazın…", "Descrieți cheltuiala sau introduceți numărul facturii…") }
    var langDescTR: String { tr("Turkish Lira (₺) • Turkish condominium standard", "Türk Lirası (₺) • Türkiye apartman standardı", "Liră Turcească (₺) • Standard asociație Turcia") }
    var langDescEN: String { tr("US Dollar ($) • International condominium standard", "Amerikan Doları ($) • Uluslararası apartman standardı", "Dolar SUA ($) • Standard internațional condominiu") }
    var langDescRO: String { tr("Romanian Leu (Lei) • Romanian association standard", "Rumen Leyi (Lei) • Romanya asociație de proprietari", "Leu Românesc (Lei) • Standard asociație România") }
    var langDescSystem: String { tr("Follows macOS system language and locale", "macOS sistem dilini ve bölgesini takip eder", "Urmează limba și regiunea sistemului macOS") }
}

// MARK: - Main Screen

struct MainScreen: View {
    @ObservedObject var settings: ReceiptSettingsStore
    @StateObject private var viewModel = MainScreenViewModel()
    @State private var isInvoiceDropTargeted: Bool = false

    init(settings: ReceiptSettingsStore, initialKind: ReceiptKind = .income, initialVendor: String? = nil, initialNotes: String? = nil) {
        self.settings = settings
        let vm = MainScreenViewModel()
        vm.syncWithSettings(settings)
        if initialKind != .income {
            vm.setReceiptKind(initialKind, settings: settings)
            if let vendor = initialVendor {
                vm.ownerName = vendor
            }
            if let notes = initialNotes {
                vm.notes = notes
            }
        }
        _viewModel = StateObject(wrappedValue: vm)
    }

    private var l10n: L10n { settings.l10n }

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            headerBar
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Main Content Area: Left Form + Right Live Preview
            HSplitView {
                // Left Form (Hero Deck)
                ScrollView {
                    VStack(spacing: 12) {
                        heroReceiptTypeSelector
                        propertyAndPartiesHeroSection
                        financialAndNotesHeroSection
                        actionButtons
                    }
                    .padding(16)
                }
                .frame(minWidth: 440, idealWidth: 500)

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
                            amountString: String(format: "%.2f", viewModel.grandTotalAmount(settings: settings)),
                            sequenceNumber: viewModel.sequenceNumber,
                            notes: viewModel.notes,
                            signatureImage: settings.signatureImage,
                            currency: settings.currency,
                            l10n: l10n,
                            logoImage: settings.logoImage,
                            isLateFeeApplied: viewModel.isLateFeeApplied && viewModel.receiptKind == .income,
                            baseAmount: viewModel.baseDuesAmount(),
                            lateFeeAmount: viewModel.calculatedLateFee(settings: settings),
                            lateFeeRate: viewModel.effectiveLateRate(settings: settings),
                            lateMonths: viewModel.lateMonths
                        )
                        .padding(20)
                    }
                }
                .frame(minWidth: 420, idealWidth: 460)
                .background(Color(NSColor.underPageBackgroundColor).opacity(0.6))
            }
        }
        .onAppear {
            if viewModel.receiptKind == .income && viewModel.ownerName.isEmpty {
                viewModel.syncWithSettings(settings)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .settingsDidSave)) { _ in
            viewModel.updateLiveFromSettings(settings)
        }
        .onReceive(settings.objectWillChange) { _ in
            DispatchQueue.main.async {
                viewModel.updateLiveFromSettings(settings)
            }
        }
        .sheet(item: $viewModel.previewDraft) { draft in
            ReceiptPreviewSheet(draft: draft, settings: settings)
        }
        .sheet(isPresented: $viewModel.isPresentingArchive) {
            ReceiptArchiveSheet(settings: settings) { selectedDraft in
                viewModel.previewDraft = selectedDraft
            }
            .frame(width: 860, height: 640)
        }
        .sheet(isPresented: $viewModel.isPresentingFinancialReport) {
            ApartmentFinancialReportSheet(settings: settings)
                .frame(width: 880, height: 660)
        }
        .sheet(isPresented: $viewModel.isPresentingBatchDues) {
            BatchDuesGeneratorSheet(settings: settings) {
                viewModel.updateLiveFromSettings(settings)
            }
            .frame(width: 720, height: 580)
        }
        .sheet(isPresented: $viewModel.isPresentingSettings) {
            SettingsView(settings: settings)
                .frame(width: 840, height: 640)
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
        HStack(spacing: 12) {
            if let logo = settings.logoImage {
                Image(nsImage: logo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
            } else if let icon = NSApplication.shared.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .shadow(color: Color.black.opacity(0.12), radius: 3, x: 0, y: 1)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(l10n.appTitle)
                        .font(.system(size: 18, weight: .bold))
                    if !settings.apartmentName.isEmpty {
                        Text(settings.apartmentName)
                            .font(.system(size: 11, weight: .semibold))
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

            // Financial Report & Cash Balance Button
            Button {
                viewModel.isPresentingFinancialReport = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))
                    Text(l10n.financialSummaryTab)
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .help(l10n.financialReportTitle)

            // Batch Dues Button
            Button {
                viewModel.isPresentingBatchDues = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.orange)
                    Text(l10n.batchDuesTitle)
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .help(l10n.batchDuesSubtitle)

            // Archive Button
            Button {
                viewModel.isPresentingArchive = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "archivebox.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text(l10n.archiveButton)
                        .font(.system(size: 12, weight: .medium))
                    if !ReceiptArchiveStore.shared.records.isEmpty {
                        Text("\(ReceiptArchiveStore.shared.records.count)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .help(l10n.archiveTitle)

            // Settings Button
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
        SettingsWindowManager.shared.show(settings: settings)
    }

    // MARK: - Hero Sections (Left Side)

    // 1. Hero Mode Switcher (Income vs Expense vs Management Spending)
    private var heroReceiptTypeSelector: some View {
        HStack(spacing: 8) {
            // Income
            modeHeroCard(
                kind: .income,
                title: l10n.incomeTitle,
                subtitle: l10n.incomeBadge,
                icon: "arrow.down.left",
                activeColor: Color.green
            )

            // Resident Refund
            modeHeroCard(
                kind: .outcome,
                title: l10n.outcomeTitle,
                subtitle: l10n.outcomeBadge,
                icon: "arrow.up.right",
                activeColor: Color.orange
            )

            // Management Operating Expense
            modeHeroCard(
                kind: .managementExpense,
                title: l10n.managementExpenseTitle,
                subtitle: l10n.managementExpenseBadge,
                icon: "briefcase.fill",
                activeColor: Color(red: 0.22, green: 0.42, blue: 0.88)
            )
        }
    }

    private func modeHeroCard(kind: ReceiptKind, title: String, subtitle: String, icon: String, activeColor: Color) -> some View {
        let isSelected = viewModel.receiptKind == kind
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                viewModel.setReceiptKind(kind, settings: settings)
            }
        } label: {
            HStack(spacing: 7) {
                ZStack {
                    Circle()
                        .fill(isSelected ? activeColor : Color.secondary.opacity(0.12))
                        .frame(width: 26, height: 26)
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isSelected ? .white : .secondary)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isSelected ? .primary : .secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(subtitle)
                        .font(.system(size: 8.5, weight: .semibold))
                        .foregroundColor(isSelected ? activeColor : .secondary.opacity(0.6))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? activeColor.opacity(0.12) : Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? activeColor.opacity(0.55) : Color.secondary.opacity(0.15), lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // 2. Property & Parties Hero Section
    private var propertyAndPartiesHeroSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if viewModel.receiptKind == .managementExpense {
                // Header Row for Management Expense (No flat toggle, dedicated operating badge)
                HStack {
                    Label(l10n.managementExpenseTitle, systemImage: "briefcase.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))

                    Spacer()

                    // Date Picker
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                        Text(l10n.period)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        DatePicker("", selection: $viewModel.receiptDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color(NSColor.textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                    )
                }

                // Operating badge
                HStack(spacing: 6) {
                    Image(systemName: "building.2.fill")
                        .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))
                        .font(.system(size: 11))
                    Text(l10n.commonAreaOperatingBadge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(red: 0.22, green: 0.42, blue: 0.88).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 7))

                Divider()

                // Invoice / Receipt OCR & Attachment Hero Card
                invoiceImportHeroCard

                // Parties Fields: Vendor (Payee) & Manager (Payer)
                VStack(spacing: 8) {
                    // Vendor / Payee
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(l10n.payeeVendorCardTitle)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                            Spacer()

                            if !viewModel.ownerName.isEmpty {
                                Button(l10n.clearForm) {
                                    viewModel.ownerName = ""
                                }
                                .font(.system(size: 10, weight: .semibold))
                                .buttonStyle(.link)
                            }

                            if !settings.vendors.isEmpty {
                                Menu {
                                    ForEach(settings.vendors) { vendor in
                                        Button {
                                            viewModel.ownerName = vendor.name
                                        } label: {
                                            if vendor.category.isEmpty {
                                                Text(vendor.name)
                                            } else {
                                                Text("\(vendor.name) (\(vendor.category))")
                                            }
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 3) {
                                        Image(systemName: "list.bullet.rectangle.portrait")
                                        Text(l10n.selectSavedVendor)
                                    }
                                    .font(.system(size: 10, weight: .semibold))
                                }
                                .menuStyle(.borderlessButton)
                            }
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "building.2.fill")
                                .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))
                                .font(.system(size: 12))
                            TextField(l10n.vendorPlaceholder, text: $viewModel.ownerName)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color(NSColor.textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                        )
                    }

                    // Manager / Payer
                    VStack(alignment: .leading, spacing: 3) {
                        Text(l10n.managerPayerLabel)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            Image(systemName: "person.badge.shield.checkmark.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                            TextField(l10n.issuerPlaceholder, text: $viewModel.issuerName)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color(NSColor.textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                        )
                    }

                    // Ready-Made Expense Services Row
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(l10n.quickServicesLabel)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                            Spacer()
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(settings.expenseServices) { service in
                                    Button {
                                        viewModel.applyPreset(notesText: service.defaultDescription, suggestedVendor: service.suggestedVendor)
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: service.iconName.isEmpty ? "briefcase.fill" : service.iconName)
                                                .font(.system(size: 9))
                                            Text(service.name)
                                                .font(.system(size: 10, weight: .medium))
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.secondary.opacity(0.1))
                                        .foregroundColor(.primary)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.secondary.opacity(0.2), lineWidth: 0.8)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            } else {
                // Header Row: Property & Print Flat Toggle
                HStack {
                    Label(l10n.flatAndPeriod, systemImage: "building.2.crop.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)

                    Spacer()

                    Toggle(isOn: $viewModel.printApartmentNumber) {
                        Text(l10n.printFlatNumber)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .toggleStyle(.checkbox)
                }

                // Flat & Period Row
                HStack(spacing: 10) {
                    // Flat Selector
                    HStack(spacing: 6) {
                        Image(systemName: "door.left.hand.closed")
                            .foregroundColor(.accentColor)
                            .font(.system(size: 12))
                        Text(l10n.flatNumber)
                            .font(.system(size: 11, weight: .medium))
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
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color(NSColor.textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                    )

                    Spacer()

                    // Date Picker
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                        Text(l10n.period)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        DatePicker("", selection: $viewModel.receiptDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color(NSColor.textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                    )
                }

                Divider()

                // Income & Resident Refund Modes
                VStack(spacing: 8) {
                    // Resident / Payer
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(l10n.receiverLabel)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            Button {
                                viewModel.ownerName = settings.owner(for: viewModel.selectedApartment)
                            } label: {
                                HStack(spacing: 3) {
                                    Image(systemName: "person.crop.circle.badge.checkmark")
                                    Text(l10n.fetchSavedResident)
                                }
                                .font(.system(size: 10, weight: .semibold))
                            }
                            .buttonStyle(.link)
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "person.fill")
                                .foregroundColor(.accentColor)
                                .font(.system(size: 12))
                            TextField(l10n.receiverPlaceholder, text: $viewModel.ownerName)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color(NSColor.textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                        )
                    }

                    // Issuer / Collector
                    VStack(alignment: .leading, spacing: 3) {
                        Text(l10n.issuerLabel)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            Image(systemName: "person.badge.shield.checkmark.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                            TextField(l10n.issuerPlaceholder, text: $viewModel.issuerName)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color(NSColor.textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // Invoice Import Hero Card with Drag & Drop and Apple Vision OCR
    private var invoiceImportHeroCard: some View {
        VStack(spacing: 6) {
            if viewModel.isScanningInvoice {
                HStack(spacing: 10) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(l10n.scanningInvoice)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(red: 0.22, green: 0.42, blue: 0.88).opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(red: 0.22, green: 0.42, blue: 0.88).opacity(0.25), lineWidth: 1)
                )
            } else if let path = viewModel.attachedInvoicePath {
                HStack(spacing: 10) {
                    Image(systemName: "doc.badge.arrow.up.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.green)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(l10n.attachedInvoice)
                                .font(.system(size: 11, weight: .bold))
                            Text(URL(fileURLWithPath: path).lastPathComponent)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        if let banner = viewModel.invoiceScanBanner {
                            Text(banner)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // View invoice button
                    Button {
                        InvoiceAttachmentManager.shared.openAttachment(at: path)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "eye.fill")
                            Text(l10n.viewInvoice)
                        }
                        .font(.system(size: 10, weight: .semibold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    // Remove invoice button
                    Button {
                        viewModel.removeAttachedInvoice()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(l10n.removeInvoice)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
            } else {
                Button {
                    chooseInvoiceFile()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "doc.viewfinder.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(l10n.importInvoice)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))
                            Text(l10n.dropInvoiceSubtitle)
                                .font(.system(size: 9.5))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "arrow.up.doc.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        isInvoiceDropTargeted
                        ? Color(red: 0.22, green: 0.42, blue: 0.88).opacity(0.15)
                        : Color(red: 0.22, green: 0.42, blue: 0.88).opacity(0.06)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                Color(red: 0.22, green: 0.42, blue: 0.88).opacity(isInvoiceDropTargeted ? 0.7 : 0.3),
                                style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                            )
                    )
                }
                .buttonStyle(.plain)
                .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isInvoiceDropTargeted) { providers in
                    guard let provider = providers.first else { return false }
                    _ = provider.loadObject(ofClass: URL.self) { url, _ in
                        if let validURL = url {
                            DispatchQueue.main.async {
                                viewModel.importInvoice(from: validURL, settings: settings)
                            }
                        }
                    }
                    return true
                }
            }
        }
    }

    private func chooseInvoiceFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if #available(macOS 11.0, *) {
            panel.allowedContentTypes = [.pdf, .png, .jpeg, .tiff]
        }
        panel.prompt = l10n.importInvoice
        if panel.runModal() == .OK, let url = panel.url {
            viewModel.importInvoice(from: url, settings: settings)
        }
    }

    private func expensePresetChip(title: String, icon: String, text: String) -> some View {
        Button {
            viewModel.applyPreset(notesText: text)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.1))
            .foregroundColor(.primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }

    // 3. Financial & Description Hero Section
    private var financialAndNotesHeroSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(l10n.financialDetails, systemImage: "banknote.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                // Hero Amount
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(l10n.amount) (\(settings.currency.symbol))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)

                    HStack(spacing: 6) {
                        Text(settings.currency.symbol)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.accentColor)
                        TextField("0.00", text: $viewModel.totalAmount)
                            .textFieldStyle(.plain)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(NSColor.textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color.accentColor.opacity(0.35), lineWidth: 1.2)
                    )
                }

                // Sequence No
                VStack(alignment: .leading, spacing: 3) {
                    Text(l10n.sequenceNo)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)

                    HStack(spacing: 6) {
                        Image(systemName: "number.square.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 13))
                        TextField("1", text: $viewModel.sequenceNumber)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .background(Color(NSColor.textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                    )
                }
                .frame(width: 120)
            }

            // Description / Notes
            VStack(alignment: .leading, spacing: 3) {
                Text(l10n.notesLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "text.alignleft")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                        .padding(.top, 2)
                    TextField(viewModel.receiptKind == .managementExpense ? l10n.customExpenseNotePlaceholder : l10n.notesPlaceholder, text: $viewModel.notes)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(NSColor.textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                )
            }

            // Optional Late Fee Section (Income Only, enabled in Settings)
            if viewModel.receiptKind == .income && settings.isLateFeeEnabled {
                lateFeeHeroCard
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var lateFeeHeroCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Toggle(isOn: $viewModel.isLateFeeApplied) {
                    HStack(spacing: 5) {
                        Image(systemName: "scalemass.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                        Text(l10n.lateFeeApplyCheckbox)
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(.primary)
                        Text(settings.lateFeeCountryProfile.flagEmoji)
                            .font(.system(size: 11))
                    }
                }
                .toggleStyle(.checkbox)

                Spacer()

                if viewModel.isLateFeeApplied {
                    Button {
                        viewModel.autoDetectOverdueMonths(settings: settings)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "wand.and.stars")
                            Text(l10n.autoDetectOverdue)
                        }
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }

            if viewModel.isLateFeeApplied {
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        // Months
                        HStack(spacing: 6) {
                            Text(l10n.overdueMonthsCount)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)

                            Picker("", selection: $viewModel.lateMonths) {
                                ForEach(1...24, id: \.self) { m in
                                    Text("\(m) \(m > 1 ? l10n.monthsUnit : l10n.monthUnit)").tag(m)
                                }
                            }
                            .frame(width: 85)
                        }

                        // Rate field (manuel oran düzenlenebilir)
                        HStack(spacing: 4) {
                            Text(l10n.lateFeeMonthlyRateTitle)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Text("%")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                            TextField("5.0", text: $viewModel.customLateFeeRate)
                                .textFieldStyle(.plain)
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .frame(width: 45)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color(NSColor.textBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                        }

                        Spacer()
                    }

                    // Calculation Breakdown
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(l10n.baseDuesAmount)
                                .font(.system(size: 9.5))
                                .foregroundColor(.secondary)
                            Text(String(format: "%.2f %@", viewModel.baseDuesAmount(), settings.currency.symbol))
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        }

                        Text("+")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.orange)

                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(l10n.lateFeeCalculated) (%\(String(format: "%.1f", viewModel.effectiveLateRate(settings: settings))) × \(viewModel.lateMonths))")
                                .font(.system(size: 9.5))
                                .foregroundColor(.orange)
                            Text(String(format: "+%.2f %@", viewModel.calculatedLateFee(settings: settings), settings.currency.symbol))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.orange)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 1) {
                            Text(l10n.totalWithLateFee)
                                .font(.system(size: 9.5))
                                .foregroundColor(.secondary)
                            Text(String(format: "%.2f %@", viewModel.grandTotalAmount(settings: settings), settings.currency.symbol))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                        }
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(.top, 4)
            }
        }
        .padding(10)
        .background(Color(NSColor.textBackgroundColor).opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
    }

    // 4. Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(role: .destructive) {
                viewModel.resetForm(settings: settings)
            } label: {
                Label(l10n.clearForm, systemImage: "arrow.counterclockwise")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)

            Spacer()

            Button {
                viewModel.createReceipt(settings: settings)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "doc.badge.plus")
                    Text(l10n.createReceipt)
                }
                .font(.system(size: 13, weight: .bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.top, 2)
    }
}

// MARK: - Default 2D Building Logo

struct Default2DBuildingLogo: View {
    var size: CGFloat = 48
    var foregroundColor: Color = Color(red: 0.12, green: 0.18, blue: 0.28)
    var backgroundColor: Color = Color(red: 0.94, green: 0.96, blue: 0.98)
    var borderColor: Color = Color(red: 0.82, green: 0.86, blue: 0.90)

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .fill(backgroundColor)
            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .stroke(borderColor, lineWidth: 1)

            VStack(spacing: 0) {
                Image(systemName: "building.2.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.56, height: size * 0.56)
                    .foregroundColor(foregroundColor)
            }
        }
        .frame(width: size, height: size)
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
    let currency: AppCurrency
    let l10n: L10n
    var logoImage: NSImage? = nil
    var isLateFeeApplied: Bool = false
    var baseAmount: Double = 0.0
    var lateFeeAmount: Double = 0.0
    var lateFeeRate: Double = 0.0
    var lateMonths: Int = 0

    private var formattedAmount: String {
        let normalized = amountString.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        if let val = Double(normalized) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = l10n.locale
            formatter.currencySymbol = currency.symbol
            formatter.currencyCode = currency.code
            return formatter.string(from: NSNumber(value: val)) ?? "\(currency.symbol) \(amountString)"
        }
        return "\(currency.symbol) 0,00"
    }

    private var badgeText: String {
        switch kind {
        case .income: return l10n.incomeBadge
        case .outcome: return l10n.outcomeBadge
        case .managementExpense: return l10n.managementExpenseBadge
        }
    }

    private var badgeColor: Color {
        switch kind {
        case .income: return .green
        case .outcome: return .orange
        case .managementExpense: return Color(red: 0.22, green: 0.42, blue: 0.88)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(alignment: .top, spacing: 10) {
                if let logo = logoImage {
                    Image(nsImage: logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 0.8)
                        )
                } else {
                    Default2DBuildingLogo(size: 36)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(apartmentName.isEmpty ? l10n.defaultBuildingName : apartmentName.uppercased())
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                    Text(badgeText)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(badgeColor)
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
                if kind == .managementExpense {
                    previewRow(label: l10n.invoiceVendorLabel, value: receiver)
                    previewRow(label: l10n.managerPayerLabel, value: issuer)
                } else {
                    previewRow(label: l10n.receiverLabel, value: receiver)
                    if showApartmentNumber {
                        previewRow(label: l10n.flatNumber, value: "\(l10n.flatPrefix) \(apartmentNumber)")
                    }
                    previewRow(label: l10n.issuerLabel, value: issuer)
                }
                previewRow(label: l10n.dateLabel, value: Date().dayMonthYearString(locale: l10n.locale))
            }

            // Late Fee Breakdown Preview
            if isLateFeeApplied && lateFeeAmount > 0 {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(l10n.baseDuesAmount)
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text(String(format: "%.2f %@", baseAmount, currency.symbol))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                    }

                    Spacer()

                    Text("+")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.orange)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(l10n.lateFeeCalculated) (%\(String(format: "%.1f", lateFeeRate)) × \(lateMonths))")
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundColor(.orange)
                        Text(String(format: "+%.2f %@", lateFeeAmount, currency.symbol))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // Amount Highlight Box
            HStack {
                Text(l10n.totalPaid)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text(formattedAmount)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(badgeColor)
            }
            .padding(12)
            .background(badgeColor.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(badgeColor.opacity(0.25), lineWidth: 1)
            )

            // Verifiable QR Indicator
            HStack(spacing: 6) {
                Image(systemName: "qrcode")
                    .font(.system(size: 11, weight: .bold))
                Text(l10n.qrCodeActive)
                    .font(.system(size: 10, weight: .semibold))
                Spacer()
                Text(l10n.qrVerificationNotice)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .foregroundColor(badgeColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(badgeColor.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 6))

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
    @Published var isPresentingArchive: Bool = false
    @Published var isPresentingFinancialReport: Bool = false
    @Published var isPresentingBatchDues: Bool = false
    @Published var validationError: ValidationError?

    @Published var attachedInvoicePath: String? = nil
    @Published var isScanningInvoice: Bool = false
    @Published var invoiceScanBanner: String? = nil

    @Published var isLateFeeApplied: Bool = false
    @Published var lateMonths: Int = 1
    @Published var customLateFeeRate: String = ""

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
        attachedInvoicePath = nil
        invoiceScanBanner = nil
        isLateFeeApplied = false
        lateMonths = 1
        customLateFeeRate = String(format: "%.1f", settings.lateFeeMonthlyRate)
    }

    func effectiveLateRate(settings: ReceiptSettingsStore) -> Double {
        let cleaned = customLateFeeRate.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        if let val = Double(cleaned), val >= 0 {
            return val
        }
        return settings.lateFeeMonthlyRate
    }

    func baseDuesAmount() -> Double {
        parseAmount(totalAmount) ?? 0.0
    }

    func calculatedLateFee(settings: ReceiptSettingsStore) -> Double {
        guard isLateFeeApplied && receiptKind == .income else { return 0.0 }
        let base = baseDuesAmount()
        let rate = effectiveLateRate(settings: settings)
        return LateFeeCalculator.fee(base: base, monthlyRate: rate, months: lateMonths)
    }

    func grandTotalAmount(settings: ReceiptSettingsStore) -> Double {
        let base = baseDuesAmount()
        if isLateFeeApplied && receiptKind == .income {
            return LateFeeCalculator.grandTotal(base: base, lateFee: calculatedLateFee(settings: settings))
        }
        return base
    }

    func autoDetectOverdueMonths(settings: ReceiptSettingsStore) {
        let calendar = Calendar.current
        let now = Date()
        let comp = calendar.dateComponents([.month], from: receiptDate, to: now)
        let months = comp.month ?? 0
        if months > 0 {
            self.lateMonths = max(1, months)
        } else {
            self.lateMonths = 1
        }
        self.isLateFeeApplied = true
    }

    func importInvoice(from url: URL, settings: ReceiptSettingsStore) {
        isScanningInvoice = true
        invoiceScanBanner = nil

        let savedPath = InvoiceAttachmentManager.shared.saveAttachment(from: url)
        self.attachedInvoicePath = savedPath

        Task {
            let result = await InvoiceOCRParser.parse(fileURL: url, knownVendors: settings.vendors.map { $0.name })
            await MainActor.run {
                self.isScanningInvoice = false
                if let vendor = result.vendorName, !vendor.isEmpty {
                    self.ownerName = vendor
                }
                if let amt = result.amount, amt > 0 {
                    self.totalAmount = String(format: "%.2f", amt)
                }
                if let date = result.invoiceDate {
                    self.receiptDate = date
                }
                if let invNo = result.invoiceNumber, !invNo.isEmpty {
                    let prefix = settings.l10n.invoiceNumberPrefix
                    let newNote = "\(prefix): \(invNo)"
                    if self.notes.isEmpty || self.notes == "-" {
                        self.notes = newNote
                    } else if !self.notes.contains(invNo) {
                        self.notes = "\(newNote) • \(self.notes)"
                    }
                }

                let l10n = settings.l10n
                let vendorStr = result.vendorName ?? l10n.importInvoice
                let amountStr = result.amount != nil ? String(format: "%.2f %@", result.amount!, settings.currency.symbol) : ""
                self.invoiceScanBanner = "\(l10n.invoiceScanSuccess): \(vendorStr) \(amountStr)".trimmingCharacters(in: .whitespaces)
            }
        }
    }

    func removeAttachedInvoice() {
        if let path = attachedInvoicePath {
            InvoiceAttachmentManager.shared.removeAttachment(at: path)
        }
        attachedInvoicePath = nil
        invoiceScanBanner = nil
    }

    func setReceiptKind(_ kind: ReceiptKind, settings: ReceiptSettingsStore) {
        receiptKind = kind
        if kind == .managementExpense {
            selectedApartment = 0
            printApartmentNumber = false
            if ownerName == settings.owner(for: selectedApartment) {
                ownerName = ""
            }
        } else {
            if selectedApartment == 0 {
                selectedApartment = settings.apartmentNumbers.first ?? 1
            }
            printApartmentNumber = true
            if ownerName.isEmpty {
                ownerName = settings.owner(for: selectedApartment)
            }
        }
    }

    func applyPreset(notesText: String, suggestedVendor: String? = nil) {
        notes = notesText
        if let vendor = suggestedVendor, ownerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ownerName = vendor
        }
    }

    func updateApartment(_ number: Int, settings: ReceiptSettingsStore) {
        selectedApartment = number
        if receiptKind != .managementExpense {
            ownerName = settings.owner(for: number)
        }
    }

    func updateLiveFromSettings(_ settings: ReceiptSettingsStore) {
        issuerName = settings.issuer
        sequenceNumber = String(settings.seqNumber)
        if receiptKind == .income {
            totalAmount = settings.defaultPayment
            ownerName = settings.owner(for: selectedApartment)
        } else if receiptKind == .outcome {
            ownerName = settings.owner(for: selectedApartment)
        }
        if selectedApartment > settings.flatCount {
            selectedApartment = max(1, settings.flatCount)
            if receiptKind != .managementExpense {
                ownerName = settings.owner(for: selectedApartment)
            }
        }
        objectWillChange.send()
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
        guard let baseAmt = parseAmount(totalAmount), baseAmt >= 0 else {
            validationError = ValidationError(message: l10n.errAmountInvalid)
            return
        }

        let effectiveApartment = receiptKind == .managementExpense ? 0 : selectedApartment
        let effectiveShowApartment = receiptKind == .managementExpense ? false : printApartmentNumber

        let effectiveLateFee = isLateFeeApplied && receiptKind == .income ? calculatedLateFee(settings: settings) : 0.0
        let effectiveGrandTotal = LateFeeCalculator.grandTotal(base: baseAmt, lateFee: effectiveLateFee)
        let effectiveRate = effectiveLateRate(settings: settings)

        let draft = ReceiptDraft(
            receiver: trimmedOwner.localizedCapitalized,
            issuer: trimmedIssuer.localizedCapitalized,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "-" : notes,
            monthYear: receiptDate.monthYearString(locale: settings.currentLocale),
            apartmentNumber: effectiveApartment,
            amount: effectiveGrandTotal,
            sequenceNumber: sequence,
            createdDate: Date().dayMonthYearString(locale: settings.currentLocale),
            showApartmentNumber: effectiveShowApartment,
            kind: receiptKind,
            currency: settings.currency,
            invoiceAttachmentPath: attachedInvoicePath,
            isLateFeeApplied: isLateFeeApplied && receiptKind == .income && effectiveLateFee > 0,
            lateFeeRate: effectiveRate,
            lateMonths: lateMonths,
            lateFeeAmount: effectiveLateFee,
            baseAmount: baseAmt,
            lateFeeFootnote: settings.effectiveLateFeeFootnote()
        )

        previewDraft = draft
        ReceiptArchiveStore.shared.add(draft: draft)

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

enum ReceiptKind: String, CaseIterable, Identifiable, Codable {
    case income
    case outcome
    case managementExpense = "management_expense"

    var id: String { rawValue }

    func title(l10n: L10n) -> String {
        switch self {
        case .income:
            return l10n.incomeTitle
        case .outcome:
            return l10n.outcomeTitle
        case .managementExpense:
            return l10n.managementExpenseTitle
        }
    }

    func badgeTitle(l10n: L10n) -> String {
        switch self {
        case .income:
            return l10n.filterIncome
        case .outcome:
            return l10n.filterOutcome
        case .managementExpense:
            return l10n.filterManagement
        }
    }

    var iconName: String {
        switch self {
        case .income:
            return "arrow.down.left.circle.fill"
        case .outcome:
            return "arrow.up.right.circle.fill"
        case .managementExpense:
            return "briefcase.fill"
        }
    }
}

struct ReceiptDraft: Identifiable, Codable {
    var id: UUID = UUID()
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
    var currency: AppCurrency = .turkishLira
    var invoiceAttachmentPath: String? = nil
    var isLateFeeApplied: Bool = false
    var lateFeeRate: Double = 0.0
    var lateMonths: Int = 0
    var lateFeeAmount: Double = 0.0
    var baseAmount: Double = 0.0
    var lateFeeFootnote: String? = nil

    enum CodingKeys: String, CodingKey {
        case id, receiver, issuer, notes, monthYear, apartmentNumber, amount
        case sequenceNumber, createdDate, showApartmentNumber, kind, currency
        case invoiceAttachmentPath, isLateFeeApplied, lateFeeRate, lateMonths, lateFeeAmount, baseAmount
        case lateFeeFootnote
    }

    init(
        id: UUID = UUID(),
        receiver: String,
        issuer: String,
        notes: String,
        monthYear: String,
        apartmentNumber: Int,
        amount: Double,
        sequenceNumber: Int,
        createdDate: String,
        showApartmentNumber: Bool,
        kind: ReceiptKind,
        currency: AppCurrency = .turkishLira,
        invoiceAttachmentPath: String? = nil,
        isLateFeeApplied: Bool = false,
        lateFeeRate: Double = 0.0,
        lateMonths: Int = 0,
        lateFeeAmount: Double = 0.0,
        baseAmount: Double = 0.0,
        lateFeeFootnote: String? = nil
    ) {
        self.id = id
        self.receiver = receiver
        self.issuer = issuer
        self.notes = notes
        self.monthYear = monthYear
        self.apartmentNumber = apartmentNumber
        self.amount = amount
        self.sequenceNumber = sequenceNumber
        self.createdDate = createdDate
        self.showApartmentNumber = showApartmentNumber
        self.kind = kind
        self.currency = currency
        self.invoiceAttachmentPath = invoiceAttachmentPath
        self.isLateFeeApplied = isLateFeeApplied
        self.lateFeeRate = lateFeeRate
        self.lateMonths = lateMonths
        self.lateFeeAmount = lateFeeAmount
        self.baseAmount = baseAmount > 0 ? baseAmount : (isLateFeeApplied ? max(0, amount - lateFeeAmount) : amount)
        self.lateFeeFootnote = lateFeeFootnote
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        receiver = try container.decode(String.self, forKey: .receiver)
        issuer = try container.decode(String.self, forKey: .issuer)
        notes = try container.decode(String.self, forKey: .notes)
        monthYear = try container.decode(String.self, forKey: .monthYear)
        apartmentNumber = try container.decode(Int.self, forKey: .apartmentNumber)
        amount = try container.decode(Double.self, forKey: .amount)
        sequenceNumber = try container.decode(Int.self, forKey: .sequenceNumber)
        createdDate = try container.decode(String.self, forKey: .createdDate)
        showApartmentNumber = try container.decode(Bool.self, forKey: .showApartmentNumber)
        kind = try container.decode(ReceiptKind.self, forKey: .kind)
        currency = try container.decodeIfPresent(AppCurrency.self, forKey: .currency) ?? .turkishLira
        invoiceAttachmentPath = try container.decodeIfPresent(String.self, forKey: .invoiceAttachmentPath)
        isLateFeeApplied = try container.decodeIfPresent(Bool.self, forKey: .isLateFeeApplied) ?? false
        lateFeeRate = try container.decodeIfPresent(Double.self, forKey: .lateFeeRate) ?? 0.0
        lateMonths = try container.decodeIfPresent(Int.self, forKey: .lateMonths) ?? 0
        let decodedLateFee = try container.decodeIfPresent(Double.self, forKey: .lateFeeAmount) ?? 0.0
        lateFeeAmount = decodedLateFee
        baseAmount = try container.decodeIfPresent(Double.self, forKey: .baseAmount) ?? (amount - decodedLateFee)
        lateFeeFootnote = try container.decodeIfPresent(String.self, forKey: .lateFeeFootnote)
    }
}

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

// MARK: - CoreImage QR Code Generator

enum QRCodeGenerator {
    static func generate(from string: String, size: CGFloat = 64) -> NSImage? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        let data = string.data(using: .utf8)
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage else { return nil }

        let extent = output.extent
        guard extent.width > 0, extent.height > 0 else { return nil }
        let scale = size / extent.width
        let transformed = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let rep = NSCIImageRep(ciImage: transformed)
        let image = NSImage(size: NSSize(width: size, height: size))
        image.addRepresentation(rep)
        return image
    }
}

// MARK: - WhatsApp & Sharing Helper

enum WhatsAppShareHelper {
    static func shareURL(phone: String?, message: String) -> URL? {
        let digits = (phone ?? "").filter { $0.isNumber }
        let encoded = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if !digits.isEmpty {
            return URL(string: "https://wa.me/\(digits)?text=\(encoded)")
        } else {
            return URL(string: "https://wa.me/?text=\(encoded)")
        }
    }

    static func emailURL(recipientEmail: String = "", subject: String, body: String) -> URL? {
        let encSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "mailto:\(recipientEmail)?subject=\(encSubject)&body=\(encBody)")
    }

    static func receiptSummary(draft: ReceiptDraft, buildingName: String, l10n: L10n) -> String {
        let currencySymbol = draft.currency.symbol
        let formattedAmount = String(format: "%.2f", draft.amount)
        switch l10n.resolvedLanguage {
        case .turkish:
            let kindText = draft.kind == .managementExpense ? "işletme harcaması belgesi" : (draft.kind == .outcome ? "iade makbuzu" : "aidat tahsilat makbuzu")
            let flatText = draft.showApartmentNumber ? "Daire \(draft.apartmentNumber) -" : ""
            return """
            Sayın *\(draft.receiver)*,
            *\(buildingName)* yönetimi tarafından \(draft.monthYear) dönemi için #\(draft.sequenceNumber) numaralı \(kindText) düzenlenmiştir.

            📍 Muhatap: \(flatText) \(draft.receiver)
            💰 Tutar: \(currencySymbol) \(formattedAmount)
            📅 Tarih: \(draft.createdDate)
            📝 Açıklama: \(draft.notes)

            Bilgilerinize sunarız.
            Yönetici: \(draft.issuer)
            """
        case .romanian:
            let kindText = draft.kind == .managementExpense ? "cheltuială administrație" : (draft.kind == .outcome ? "dispoziție de plată" : "chitanță întreținere")
            let flatText = draft.showApartmentNumber ? "Ap. \(draft.apartmentNumber) -" : ""
            return """
            Stimate/Stimată *\(draft.receiver)*,
            Asociația *\(buildingName)* a emis \(kindText) cu seria #\(draft.sequenceNumber) pentru perioada \(draft.monthYear).

            📍 Beneficiar: \(flatText) \(draft.receiver)
            💰 Sumă: \(currencySymbol) \(formattedAmount)
            📅 Data: \(draft.createdDate)
            📝 Detalii: \(draft.notes)

            Cu stimă,
            Administrator: \(draft.issuer)
            """
        default:
            let kindText = draft.kind == .managementExpense ? "operating expense voucher" : (draft.kind == .outcome ? "resident refund receipt" : "dues collection receipt")
            let flatText = draft.showApartmentNumber ? "Unit \(draft.apartmentNumber) -" : ""
            return """
            Dear *\(draft.receiver)*,
            *\(buildingName)* management has issued receipt #\(draft.sequenceNumber) (\(kindText)) for the period of \(draft.monthYear).

            📍 Payee/Unit: \(flatText) \(draft.receiver)
            💰 Amount: \(currencySymbol) \(formattedAmount)
            📅 Date: \(draft.createdDate)
            📝 Notes: \(draft.notes)

            Best regards,
            Manager: \(draft.issuer)
            """
        }
    }
}

// MARK: - Portable System Backup Model

struct SystemBackupPackage: Codable {
    var version: String = "2.1"
    var exportDate: Date = Date()
    var apartmentName: String
    var issuer: String
    var defaultPayment: String
    var flatCount: Int
    var seqNumber: Int
    var language: String
    var currency: String
    var residents: [Int: String]
    var residentPhones: [Int: String]
    var vendors: [VendorRecord]
    var expenseServices: [ExpenseServicePreset]
    var archivedReceipts: [ReceiptRecord]
    var isLateFeeEnabled: Bool? = false
    var lateFeeMonthlyRate: Double? = 5.0
    var lateFeeDueDay: Int? = 15
    var lateFeeCountryProfile: String? = "international"
    var lateFeeGracePeriodDays: Int? = 0
    var lateFeeCustomFootnote: String? = nil
}

// MARK: - Store

@MainActor
final class ReceiptSettingsStore: ObservableObject {
    static let shared = ReceiptSettingsStore()

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
        didSet {
            defaults.set(language.rawValue, forKey: Keys.language)
            let appleLang: String
            switch language {
            case .turkish: appleLang = "tr"
            case .romanian: appleLang = "ro"
            case .english, .system: appleLang = "en"
            }
            defaults.set([appleLang], forKey: "AppleLanguages")
            NotificationCenter.default.post(name: .appLanguageDidChange, object: nil)
        }
    }
    @Published var theme: AppTheme {
        didSet {
            defaults.set(theme.rawValue, forKey: Keys.theme)
            applyTheme(theme)
        }
    }
    @Published var currency: AppCurrency {
        didSet { defaults.set(currency.rawValue, forKey: Keys.currency) }
    }
    @Published var isLateFeeEnabled: Bool {
        didSet { defaults.set(isLateFeeEnabled, forKey: Keys.isLateFeeEnabled) }
    }
    @Published var lateFeeMonthlyRate: Double {
        didSet { defaults.set(lateFeeMonthlyRate, forKey: Keys.lateFeeMonthlyRate) }
    }
    @Published var lateFeeDueDay: Int {
        didSet { defaults.set(lateFeeDueDay, forKey: Keys.lateFeeDueDay) }
    }
    @Published var lateFeeCountryProfile: LateFeeCountryProfile {
        didSet { defaults.set(lateFeeCountryProfile.rawValue, forKey: Keys.lateFeeCountryProfile) }
    }
    @Published var lateFeeGracePeriodDays: Int {
        didSet { defaults.set(lateFeeGracePeriodDays, forKey: Keys.lateFeeGracePeriodDays) }
    }
    @Published var lateFeeCustomFootnote: String {
        didSet { defaults.set(lateFeeCustomFootnote, forKey: Keys.lateFeeCustomFootnote) }
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
    @Published var logoData: Data? {
        didSet {
            if let logoData {
                defaults.set(logoData, forKey: Keys.logo)
            } else {
                defaults.removeObject(forKey: Keys.logo)
            }
        }
    }
    @Published var vendors: [VendorRecord] {
        didSet {
            if let data = try? JSONEncoder().encode(vendors) {
                defaults.set(data, forKey: Keys.vendors)
            }
        }
    }
    @Published var expenseServices: [ExpenseServicePreset] {
        didSet {
            if let data = try? JSONEncoder().encode(expenseServices) {
                defaults.set(data, forKey: Keys.expenseServices)
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
        let savedLang = defaults.string(forKey: Keys.language) ?? AppLanguage.english.rawValue
        let resolvedLang = AppLanguage(rawValue: savedLang) ?? .english
        language = resolvedLang

        let savedCurrency = defaults.string(forKey: Keys.currency)
        let resolvedCurrency = savedCurrency.flatMap(AppCurrency.init(rawValue:)) ?? AppCurrency.default(for: resolvedLang)
        currency = resolvedCurrency

        let isConfigured = defaults.object(forKey: Keys.apartmentName) != nil
        let savedApt = defaults.string(forKey: Keys.apartmentName) ?? ""
        let isScreenshotPollution = (savedApt == "Asociația Parcul Tineretului" || savedApt.isEmpty) && (resolvedLang == .english || resolvedLang == .system)

        if !isConfigured || isScreenshotPollution {
            let samples = SampleData.defaults(for: resolvedLang)
            apartmentName = samples.apartmentName
            issuer = samples.issuer
            defaultPayment = samples.defaultPayment
            flatCount = samples.flatCount
            currency = samples.currency
            seqNumber = 1
            for (apt, name) in samples.residents {
                defaults.set(name, forKey: Keys.owner(apt))
            }
        } else {
            apartmentName = defaults.string(forKey: Keys.apartmentName) ?? ""
            issuer = defaults.string(forKey: Keys.issuer) ?? ""
            defaultPayment = defaults.string(forKey: Keys.defaultPayment) ?? ""
            flatCount = max(1, ReceiptSettingsStore.readInt(defaults, key: Keys.flatCount, fallback: 1))
            seqNumber = max(1, ReceiptSettingsStore.readInt(defaults, key: Keys.seqNumber, fallback: 1))
        }

        if let vendorData = defaults.data(forKey: Keys.vendors),
           let savedVendors = try? JSONDecoder().decode([VendorRecord].self, from: vendorData),
           !savedVendors.isEmpty {
            vendors = savedVendors
        } else {
            vendors = SampleData.defaults(for: resolvedLang).defaultVendors
        }

        if let serviceData = defaults.data(forKey: Keys.expenseServices),
           let savedServices = try? JSONDecoder().decode([ExpenseServicePreset].self, from: serviceData),
           !savedServices.isEmpty {
            expenseServices = savedServices
        } else {
            expenseServices = SampleData.defaults(for: resolvedLang).defaultServices
        }

        let savedTheme = defaults.string(forKey: Keys.theme) ?? AppTheme.system.rawValue
        let resolvedTheme = AppTheme(rawValue: savedTheme) ?? .system
        theme = resolvedTheme

        isLateFeeEnabled = defaults.bool(forKey: Keys.isLateFeeEnabled)
        let savedFeeRate = defaults.double(forKey: Keys.lateFeeMonthlyRate)
        lateFeeMonthlyRate = savedFeeRate > 0 ? savedFeeRate : 5.0
        let savedDueDay = defaults.integer(forKey: Keys.lateFeeDueDay)
        lateFeeDueDay = savedDueDay > 0 ? savedDueDay : 15

        let savedProfile = defaults.string(forKey: Keys.lateFeeCountryProfile)
        let resolvedProfile = savedProfile.flatMap(LateFeeCountryProfile.init(rawValue:)) ?? LateFeeCountryProfile.default(for: resolvedLang)
        lateFeeCountryProfile = resolvedProfile
        let savedGrace = defaults.integer(forKey: Keys.lateFeeGracePeriodDays)
        lateFeeGracePeriodDays = defaults.object(forKey: Keys.lateFeeGracePeriodDays) != nil ? savedGrace : resolvedProfile.defaultGraceDays
        lateFeeCustomFootnote = defaults.string(forKey: Keys.lateFeeCustomFootnote) ?? ""

        signatureData = defaults.data(forKey: Keys.signature)
        logoData = defaults.data(forKey: Keys.logo)

        applyTheme(resolvedTheme)
    }

    func effectiveLateFeeFootnote() -> String {
        let trimmed = lateFeeCustomFootnote.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed
        }
        return lateFeeCountryProfile.defaultFootnote(for: language)
    }

    func effectiveLateFeeLegalNotice() -> String {
        lateFeeCountryProfile.defaultLegalNotice(for: language)
    }

    func setLateFeeCountryProfile(_ profile: LateFeeCountryProfile, applyDefaults: Bool = true) {
        defaults.set(lateFeeMonthlyRate, forKey: Keys.lateFeeRate(for: lateFeeCountryProfile))
        lateFeeCountryProfile = profile

        if applyDefaults {
            let savedRate = defaults.double(forKey: Keys.lateFeeRate(for: profile))
            lateFeeMonthlyRate = savedRate > 0 ? savedRate : profile.defaultRate
            lateFeeDueDay = profile.defaultDueDay
            lateFeeGracePeriodDays = profile.defaultGraceDays
            lateFeeCustomFootnote = ""
        }
    }

    func loadSampleDefaults(for targetLang: AppLanguage? = nil) {
        let lang = targetLang ?? language
        let samples = SampleData.defaults(for: lang)
        apartmentName = samples.apartmentName
        issuer = samples.issuer
        defaultPayment = samples.defaultPayment
        flatCount = samples.flatCount
        currency = samples.currency
        for (apt, name) in samples.residents {
            saveOwner(name, apartmentNumber: apt)
        }
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

    var logoImage: NSImage? {
        guard let logoData else { return nil }
        return NSImage(data: logoData)
    }

    func clearLogo() {
        logoData = nil
    }

    func importLogo() {
        let panel = NSOpenPanel()
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.png, .jpeg]

        if panel.runModal() == .OK, let url = panel.url {
            do {
                logoData = try Data(contentsOf: url)
            } catch {
                logoData = nil
            }
        }
    }

    func addVendor(_ vendor: VendorRecord) {
        vendors.append(vendor)
    }

    func deleteVendor(id: UUID) {
        vendors.removeAll { $0.id == id }
    }

    func addExpenseService(_ service: ExpenseServicePreset) {
        expenseServices.append(service)
    }

    func deleteExpenseService(id: UUID) {
        expenseServices.removeAll { $0.id == id }
    }

    func loadSampleVendorsAndServices(for targetLang: AppLanguage? = nil) {
        let lang = targetLang ?? language
        let samples = SampleData.defaults(for: lang)
        vendors = samples.defaultVendors
        expenseServices = samples.defaultServices
    }

    func ownerPhone(for apartmentNumber: Int) -> String {
        defaults.string(forKey: Keys.ownerPhone(apartmentNumber)) ?? ""
    }

    func saveOwnerPhone(_ phone: String, apartmentNumber: Int) {
        defaults.set(phone, forKey: Keys.ownerPhone(apartmentNumber))
        objectWillChange.send()
    }

    func exportSystemBackup() -> Data? {
        var resMap: [Int: String] = [:]
        var phoneMap: [Int: String] = [:]
        for flat in 1...max(flatCount, 1) {
            let name = owner(for: flat)
            if !name.isEmpty { resMap[flat] = name }
            let phone = ownerPhone(for: flat)
            if !phone.isEmpty { phoneMap[flat] = phone }
        }

        let pkg = SystemBackupPackage(
            version: "2.1",
            exportDate: Date(),
            apartmentName: apartmentName,
            issuer: issuer,
            defaultPayment: defaultPayment,
            flatCount: flatCount,
            seqNumber: seqNumber,
            language: language.rawValue,
            currency: currency.rawValue,
            residents: resMap,
            residentPhones: phoneMap,
            vendors: vendors,
            expenseServices: expenseServices,
            archivedReceipts: ReceiptArchiveStore.shared.records,
            isLateFeeEnabled: isLateFeeEnabled,
            lateFeeMonthlyRate: lateFeeMonthlyRate,
            lateFeeDueDay: lateFeeDueDay,
            lateFeeCountryProfile: lateFeeCountryProfile.rawValue,
            lateFeeGracePeriodDays: lateFeeGracePeriodDays,
            lateFeeCustomFootnote: lateFeeCustomFootnote
        )
        return try? JSONEncoder().encode(pkg)
    }

    func importSystemBackup(from data: Data) throws {
        let decoder = JSONDecoder()
        let pkg = try decoder.decode(SystemBackupPackage.self, from: data)
        apartmentName = pkg.apartmentName
        issuer = pkg.issuer
        defaultPayment = pkg.defaultPayment
        flatCount = max(1, pkg.flatCount)
        seqNumber = max(1, pkg.seqNumber)
        if let lang = AppLanguage(rawValue: pkg.language) {
            language = lang
        }
        if let cur = AppCurrency(rawValue: pkg.currency) {
            currency = cur
        }
        if let feeEnabled = pkg.isLateFeeEnabled {
            isLateFeeEnabled = feeEnabled
        }
        if let feeRate = pkg.lateFeeMonthlyRate, feeRate >= 0 {
            lateFeeMonthlyRate = feeRate
        }
        if let feeDay = pkg.lateFeeDueDay, feeDay >= 1 && feeDay <= 31 {
            lateFeeDueDay = feeDay
        }
        if let profileStr = pkg.lateFeeCountryProfile, let prof = LateFeeCountryProfile(rawValue: profileStr) {
            lateFeeCountryProfile = prof
        }
        if let grace = pkg.lateFeeGracePeriodDays {
            lateFeeGracePeriodDays = grace
        }
        if let foot = pkg.lateFeeCustomFootnote {
            lateFeeCustomFootnote = foot
        }
        for (flat, name) in pkg.residents {
            saveOwner(name, apartmentNumber: flat)
        }
        for (flat, phone) in pkg.residentPhones {
            saveOwnerPhone(phone, apartmentNumber: flat)
        }
        vendors = pkg.vendors
        expenseServices = pkg.expenseServices
        ReceiptArchiveStore.shared.replaceRecords(pkg.archivedReceipts)
        NotificationCenter.default.post(name: .settingsDidSave, object: nil)
        objectWillChange.send()
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
        static let logo = "building_logo"
        static let language = "app_language"
        static let theme = "app_theme"
        static let currency = "app_currency"
        static let vendors = "vendors_list"
        static let expenseServices = "expense_services_list"
        static let isLateFeeEnabled = "is_late_fee_enabled"
        static let lateFeeMonthlyRate = "late_fee_monthly_rate"
        static let lateFeeDueDay = "late_fee_due_day"
        static let lateFeeCountryProfile = "late_fee_country_profile"
        static let lateFeeGracePeriodDays = "late_fee_grace_period_days"
        static let lateFeeCustomFootnote = "late_fee_custom_footnote"

        static func lateFeeRate(for profile: LateFeeCountryProfile) -> String {
            "late_fee_rate_\(profile.rawValue)"
        }

        static func owner(_ number: Int) -> String {
            "homeowner_\(number)"
        }

        static func ownerPhone(_ number: Int) -> String {
            "homeowner_phone_\(number)"
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
  "Publisher" refers to Babadogan Tech and Edu.

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
                    Text("\(l10n.publisherLabel):")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    Text("Babadogan Tech and Edu")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15))
                        .clipShape(Capsule())
                }

                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.green)
                    Text("\(l10n.licenseLabel):")
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

// MARK: - Receipt Archive Sheet

struct ReceiptArchiveSheet: View {
    @ObservedObject var settings: ReceiptSettingsStore
    @ObservedObject var archiveStore = ReceiptArchiveStore.shared
    @Environment(\.presentationMode) private var presentationMode
    var onSelectDraft: (ReceiptDraft) -> Void

    @State private var searchQuery: String = ""
    @State private var selectedFilter: String = "all"

    private var l10n: L10n { settings.l10n }

    private var filteredRecords: [ReceiptRecord] {
        archiveStore.records.filter { rec in
            // Filter by type
            if selectedFilter == "income" && rec.kind != .income { return false }
            if selectedFilter == "outcome" && rec.kind != .outcome { return false }
            if selectedFilter == "management" && rec.kind != .managementExpense { return false }

            // Filter by query
            if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return true }
            let q = searchQuery.lowercased()
            return rec.receiver.lowercased().contains(q)
                || rec.notes.lowercased().contains(q)
                || "\(rec.sequenceNumber)".contains(q)
                || "\(rec.apartmentNumber)".contains(q)
                || rec.monthYear.lowercased().contains(q)
        }
    }

    private var totalFilteredAmount: Double {
        filteredRecords.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Image(systemName: "archivebox.fill")
                            .foregroundColor(.accentColor)
                            .font(.system(size: 16))
                        Text(l10n.archiveTitle)
                            .font(.headline)
                    }
                    Text(l10n.archiveSubtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    exportArchiveCSV()
                } label: {
                    Label(l10n.exportCSV, systemImage: "arrow.down.doc.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .disabled(filteredRecords.isEmpty)

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

            // Filter & Search Deck
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    // Search field
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                        TextField(l10n.archiveSearchPlaceholder, text: $searchQuery)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                        if !searchQuery.isEmpty {
                            Button {
                                searchQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color(NSColor.textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )

                    // Type filter picker
                    Picker("", selection: $selectedFilter) {
                        Text(l10n.filterAll).tag("all")
                        Text(l10n.filterIncome).tag("income")
                        Text(l10n.filterOutcome).tag("outcome")
                        Text(l10n.filterManagement).tag("management")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 380)
                }

                // Stats Bar
                HStack {
                    HStack(spacing: 5) {
                        Image(systemName: "number.circle.fill")
                            .foregroundColor(.secondary)
                        Text("\(filteredRecords.count) \(l10n.totalArchived)")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())

                    Spacer()

                    Text(String(format: "%.2f %@", totalFilteredAmount, settings.currency.symbol))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // List of Receipts
            if filteredRecords.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text(l10n.archiveEmpty)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 60)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredRecords) { record in
                            archiveRecordRow(record)
                        }
                    }
                    .padding(20)
                }
            }

            Divider()

            // Footer
            HStack {
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
        .frame(minWidth: 800, idealWidth: 860, minHeight: 560, idealHeight: 640)
    }

    private func archiveRecordRow(_ record: ReceiptRecord) -> some View {
        let badgeColor: Color = {
            switch record.kind {
            case .income: return .green
            case .outcome: return .orange
            case .managementExpense: return Color(red: 0.22, green: 0.42, blue: 0.88)
            }
        }()

        return HStack(spacing: 12) {
            // Sequence & Kind Badge
            VStack(spacing: 2) {
                Text("#\(record.sequenceNumber)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(badgeColor)
                Text(record.kind.badgeTitle(l10n: l10n))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(badgeColor)
                    .lineLimit(1)
            }
            .frame(width: 86)
            .padding(.vertical, 6)
            .background(badgeColor.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            // Details
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(record.receiver)
                        .font(.system(size: 13, weight: .bold))
                        .lineLimit(1)
                    if record.showApartmentNumber && record.apartmentNumber > 0 {
                        Text("\(l10n.flatPrefix) \(record.apartmentNumber)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 8) {
                    Label(record.createdDate, systemImage: "calendar")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    if !record.notes.isEmpty && record.notes != "-" {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(record.notes)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // Amount
            Text(String(format: "%.2f %@", record.amount, record.currency.symbol))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(badgeColor)
                .frame(width: 130, alignment: .trailing)

            // Actions
            HStack(spacing: 6) {
                // Open Receipt Button
                Button {
                    let draft = record.toDraft()
                    presentationMode.wrappedValue.dismiss()
                    onSelectDraft(draft)
                } label: {
                    Image(systemName: "arrow.up.right.square.fill")
                        .font(.system(size: 14))
                }
                .buttonStyle(.borderless)
                .help(l10n.openReceipt)

                // WhatsApp Share Button
                Button {
                    shareViaWhatsApp(record)
                } label: {
                    Image(systemName: "message.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                }
                .buttonStyle(.borderless)
                .help(l10n.shareWhatsApp)

                // View Attached Invoice Button (If Available)
                if let path = record.invoiceAttachmentPath, !path.isEmpty {
                    Button {
                        InvoiceAttachmentManager.shared.openAttachment(at: path)
                    } label: {
                        Image(systemName: "paperclip.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))
                    }
                    .buttonStyle(.borderless)
                    .help(l10n.viewAttachedInvoice)
                }

                // Delete Button
                Button {
                    archiveStore.remove(id: record.id)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(.borderless)
                .help(l10n.deleteReceipt)
            }
        }
        .padding(10)
        .background(Color(NSColor.textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
        )
    }

    private func shareViaWhatsApp(_ record: ReceiptRecord) {
        let phone = record.apartmentNumber > 0 ? settings.ownerPhone(for: record.apartmentNumber) : nil
        let msg = WhatsAppShareHelper.receiptSummary(draft: record.toDraft(), buildingName: settings.apartmentName, l10n: l10n)
        if let url = WhatsAppShareHelper.shareURL(phone: phone, message: msg) {
            NSWorkspace.shared.open(url)
        }
    }

    private func exportArchiveCSV() {
        var csv = "Sequence,Kind,Receiver,Apartment,Period,Date,Amount,Currency,Notes,Issuer\n"
        for r in filteredRecords {
            let row = [
                "\(r.sequenceNumber)",
                "\"\(r.kind.rawValue)\"",
                "\"\(r.receiver)\"",
                "\(r.apartmentNumber)",
                "\"\(r.monthYear)\"",
                "\"\(r.createdDate)\"",
                String(format: "%.2f", r.amount),
                "\"\(r.currency.rawValue)\"",
                "\"\(r.notes.replacingOccurrences(of: "\"", with: "\"\""))\"",
                "\"\(r.issuer)\""
            ].joined(separator: ",")
            csv.append(row + "\n")
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "AptReceipt_Archive_\(Date().dayMonthYearString(locale: settings.currentLocale)).csv"
        if panel.runModal() == .OK, let url = panel.url {
            try? csv.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

// MARK: - Apartment Financial Report & Cash Balance Sheet

struct ApartmentFinancialReportSheet: View {
    @ObservedObject var settings: ReceiptSettingsStore
    @ObservedObject private var archiveStore = ReceiptArchiveStore.shared
    @Environment(\.presentationMode) private var presentationMode

    @State private var selectedPeriod: String = "all"
    @State private var selectedTab: Int = 0
    @State private var successNotice: String?

    private var l10n: L10n { settings.l10n }

    private var availablePeriods: [String] {
        let set = Set(archiveStore.records.map { $0.monthYear })
        return Array(set).sorted().reversed()
    }

    private var filteredRecords: [ReceiptRecord] {
        if selectedPeriod == "all" {
            return archiveStore.records
        }
        return archiveStore.records.filter { $0.monthYear == selectedPeriod }
    }

    private var totalIncome: Double {
        filteredRecords.filter { $0.kind == .income }.reduce(0) { $0 + $1.amount }
    }

    private var totalRefunds: Double {
        filteredRecords.filter { $0.kind == .outcome }.reduce(0) { $0 + $1.amount }
    }

    private var totalExpenses: Double {
        filteredRecords.filter { $0.kind == .managementExpense }.reduce(0) { $0 + $1.amount }
    }

    private var netCashBalance: Double {
        totalIncome - totalRefunds - totalExpenses
    }

    private var expenseCategories: [(category: String, amount: Double, percent: Double)] {
        let expenses = filteredRecords.filter { $0.kind == .managementExpense }
        guard !expenses.isEmpty else { return [] }
        var map: [String: Double] = [:]
        for exp in expenses {
            let cat = exp.notes.components(separatedBy: "•").first?.trimmingCharacters(in: .whitespaces) ?? exp.receiver
            let key = (cat.isEmpty || cat == "-") ? exp.receiver : cat
            map[key, default: 0.0] += exp.amount
        }
        let total = totalExpenses > 0 ? totalExpenses : 1.0
        return map.map { (category: $0.key, amount: $0.value, percent: ($0.value / total) * 100.0) }
            .sorted { $0.amount > $1.amount }
    }

    private var flatDuesStatusList: [(flat: Int, owner: String, phone: String, isPaid: Bool, record: ReceiptRecord?)] {
        let periodToMatch = selectedPeriod == "all" ? (availablePeriods.first ?? "") : selectedPeriod
        return settings.apartmentNumbers.map { flat in
            let owner = settings.owner(for: flat)
            let phone = settings.ownerPhone(for: flat)
            let matchingRecord = archiveStore.records.first {
                $0.kind == .income && $0.apartmentNumber == flat && (periodToMatch.isEmpty || $0.monthYear == periodToMatch)
            }
            return (flat: flat, owner: owner, phone: phone, isPaid: matchingRecord != nil, record: matchingRecord)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))

                VStack(alignment: .leading, spacing: 2) {
                    Text(l10n.financialReportTitle)
                        .font(.system(size: 16, weight: .bold))
                    Text(l10n.financialReportSubtitle)
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

            // Control Bar (Period Filter & View Selector)
            HStack(spacing: 16) {
                // Period Dropdown
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11))
                    Picker("", selection: $selectedPeriod) {
                        Text(l10n.allMonths).tag("all")
                        ForEach(availablePeriods, id: \.self) { period in
                            Text(period).tag(period)
                        }
                    }
                    .frame(width: 170)
                }

                Spacer()

                // Tab Switcher
                Picker("", selection: $selectedTab) {
                    Text(l10n.financialSummaryTab).tag(0)
                    Text(l10n.duesTrackingTab).tag(1)
                    Text(l10n.allTransactionsTab).tag(2)
                }
                .pickerStyle(.segmented)
                .frame(width: 380)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.6))

            Divider()

            // Active Tab Content
            ScrollView {
                VStack(spacing: 16) {
                    if selectedTab == 0 {
                        summaryTabContent
                    } else if selectedTab == 1 {
                        duesTrackingTabContent
                    } else {
                        transactionsTabContent
                    }
                }
                .padding(20)
            }
            .frame(maxHeight: .infinity)

            Divider()

            // Footer
            HStack {
                if let notice = successNotice {
                    Label(notice, systemImage: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.green)
                }

                Spacer()

                Button {
                    exportBulletinBoardPDF()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.richtext.fill")
                        Text(l10n.exportBulletinBoardPDF)
                    }
                }
                .buttonStyle(.borderedProminent)

                Button(l10n.close) {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 840, idealWidth: 880, minHeight: 600, idealHeight: 660)
        .onAppear {
            if let latest = availablePeriods.first {
                selectedPeriod = latest
            }
        }
    }

    // MARK: - Tab 0: Summary Content
    private var summaryTabContent: some View {
        VStack(spacing: 16) {
            // KPI Balance Cards
            HStack(spacing: 12) {
                kpiCard(title: l10n.totalIncome, amount: totalIncome, color: .green, icon: "arrow.down.left.circle.fill", subtitle: "\(filteredRecords.filter { $0.kind == .income }.count) \(l10n.archiveTitle)")
                kpiCard(title: l10n.totalExpenses, amount: totalExpenses, color: .red, icon: "arrow.up.right.circle.fill", subtitle: "\(filteredRecords.filter { $0.kind == .managementExpense }.count) \(l10n.managementExpenseTitle)")
                kpiCard(title: l10n.netCashBalance, amount: netCashBalance, color: netCashBalance >= 0 ? Color(red: 0.22, green: 0.42, blue: 0.88) : .red, icon: "banknote.fill", subtitle: l10n.commonAreaOperatingBadge)
            }

            // Dues Collection Rate Card
            let paidCount = flatDuesStatusList.filter { $0.isPaid }.count
            let totalFlats = max(1, settings.flatCount)
            let rate = (Double(paidCount) / Double(totalFlats)) * 100.0

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(l10n.duesTrackingTab, systemImage: "checkmark.seal.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.green)
                    Spacer()
                    Text(String(format: "%%%0.1f \(l10n.paidStatus) (%d / %d)", rate, paidCount, totalFlats))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.secondary.opacity(0.15))
                            .frame(height: 10)
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.green)
                            .frame(width: geo.size.width * CGFloat(rate / 100.0), height: 10)
                    }
                }
                .frame(height: 10)
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Expense Breakdown
            if !expenseCategories.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label(l10n.managementExpenseTitle, systemImage: "briefcase.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))

                    VStack(spacing: 8) {
                        ForEach(expenseCategories, id: \.category) { item in
                            HStack {
                                Text(item.category)
                                    .font(.system(size: 12, weight: .medium))
                                    .lineLimit(1)
                                Spacer()
                                Text(String(format: "%.2f %@", item.amount, settings.currency.symbol))
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                Text(String(format: "(%%%0.1f)", item.percent))
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .frame(width: 50, alignment: .trailing)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.secondary.opacity(0.1))
                                        .frame(height: 5)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color(red: 0.22, green: 0.42, blue: 0.88))
                                        .frame(width: geo.size.width * CGFloat(item.percent / 100.0), height: 5)
                                }
                            }
                            .frame(height: 5)
                        }
                    }
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Tab 1: Dues Tracking Content
    private var duesTrackingTabContent: some View {
        VStack(spacing: 8) {
            ForEach(flatDuesStatusList, id: \.flat) { item in
                HStack(spacing: 12) {
                    Text("\(l10n.flatPrefix) \(item.flat)")
                        .font(.system(size: 13, weight: .bold))
                        .frame(width: 70, alignment: .leading)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.owner.isEmpty ? "—" : item.owner)
                            .font(.system(size: 12, weight: .semibold))
                        if !item.phone.isEmpty {
                            Text(item.phone)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    if item.isPaid {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(l10n.paidStatus)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.green)
                            if let rec = item.record {
                                Text("#\(rec.sequenceNumber)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.green.opacity(0.12))
                        .clipShape(Capsule())
                    } else {
                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.badge.exclamationmark.fill")
                                    .foregroundColor(.orange)
                                Text(l10n.unpaidStatus)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(Capsule())

                            if settings.isLateFeeEnabled {
                                let defaultAmt = Double(settings.defaultPayment.replacingOccurrences(of: ",", with: ".")) ?? 1750.0
                                let fee = LateFeeCalculator.fee(base: defaultAmt, monthlyRate: settings.lateFeeMonthlyRate, months: 1)
                                Text("+\(String(format: "%.2f", fee)) \(settings.currency.symbol) \(l10n.lateFeeShortBadge)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(Color.orange.opacity(0.08))
                                    .clipShape(Capsule())
                            }

                            Button {
                                sendWhatsAppReminder(flat: item.flat, owner: item.owner, phone: item.phone)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "message.fill")
                                    Text(l10n.remindWhatsApp)
                                }
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.green)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    // MARK: - Tab 2: All Transactions Content
    private var transactionsTabContent: some View {
        VStack(spacing: 8) {
            ForEach(filteredRecords) { r in
                HStack(spacing: 12) {
                    Text("#\(r.sequenceNumber)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .frame(width: 50, alignment: .leading)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(r.receiver)
                            .font(.system(size: 12, weight: .bold))
                        Text(r.createdDate + " • " + r.notes)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    let color: Color = r.kind == .income ? .green : (r.kind == .outcome ? .orange : Color(red: 0.22, green: 0.42, blue: 0.88))
                    Text(String(format: "%.2f %@", r.amount, r.currency.symbol))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func kpiCard(title: String, amount: Double, color: Color, icon: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
            }
            Text(String(format: "%.2f %@", amount, settings.currency.symbol))
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundColor(color)
            Text(subtitle)
                .font(.system(size: 9.5))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }

    private func sendWhatsAppReminder(flat: Int, owner: String, phone: String) {
        let periodName = selectedPeriod == "all" ? (availablePeriods.first ?? "") : selectedPeriod
        let duesAmt = settings.defaultPayment.isEmpty ? "1750" : settings.defaultPayment
        let duesAmtValue = Double(duesAmt.replacingOccurrences(of: ",", with: ".")) ?? 1750.0
        let currencySym = settings.currency.symbol
        let apt = settings.apartmentName.isEmpty ? l10n.defaultBuildingName : settings.apartmentName
        let manager = settings.issuer.isEmpty ? l10n.managerSignatureTitle : settings.issuer

        let message: String
        if settings.isLateFeeEnabled {
            let lateFeeVal = LateFeeCalculator.fee(base: duesAmtValue, monthlyRate: settings.lateFeeMonthlyRate, months: 1)
            let totalVal = duesAmtValue + lateFeeVal
            let rateStr = String(format: "%.1f", settings.lateFeeMonthlyRate)
            let feeStr = String(format: "%.2f", lateFeeVal)
            let totalStr = String(format: "%.2f", totalVal)
            switch l10n.resolvedLanguage {
            case .turkish:
                message = "Sayın Komşumuz (Daire \(flat)), \(apt) \(periodName) dönemi \(duesAmt) \(currencySym) aidat ve aylık %\(rateStr) gecikme tazminatı (\(feeStr) \(currencySym)) ile birlikte toplam \(totalStr) \(currencySym) ödemeniz henüz kaydımıza geçmemiştir. Bilginize sunar, iyi günler dileriz. - \(manager)"
            case .romanian:
                message = "Stimate Vecin (Ap. \(flat)), plata întreținerii pentru \(periodName) la \(apt) (\(duesAmt) \(currencySym)) plus penalități de întârziere (%\(rateStr): \(feeStr) \(currencySym)), total \(totalStr) \(currencySym) este în așteptare. Vă mulțumim! - \(manager)"
            default:
                message = "Dear Resident (Flat \(flat)), dues for \(periodName) at \(apt) (\(duesAmt) \(currencySym)) plus late fee compensation (%\(rateStr): \(feeStr) \(currencySym)), total \(totalStr) \(currencySym) is currently pending. Thank you! - \(manager)"
            }
        } else {
            switch l10n.resolvedLanguage {
            case .turkish:
                message = "Sayın Komşumuz (Daire \(flat)), \(apt) \(periodName) dönemi \(duesAmt) \(currencySym) aidat ödemeniz henüz kaydımıza geçmemiştir. Bilginize sunar, iyi günler dileriz. - \(manager)"
            case .romanian:
                message = "Stimate Vecin (Ap. \(flat)), plata întreținerii pentru perioada \(periodName) la \(apt) în valoare de \(duesAmt) \(currencySym) este în așteptare. Vă mulțumim! - \(manager)"
            default:
                message = "Dear Resident (Flat \(flat)), dues payment for \(periodName) at \(apt) in the amount of \(duesAmt) \(currencySym) is currently pending. Thank you! - \(manager)"
            }
        }

        let cleanPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = WhatsAppShareHelper.shareURL(phone: cleanPhone.isEmpty ? nil : cleanPhone, message: message) {
            NSWorkspace.shared.open(url)
        }
    }

    private func exportBulletinBoardPDF() {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.showsTagField = false
        panel.allowedContentTypes = [.pdf]
        let periodStr = selectedPeriod == "all" ? "Genel" : selectedPeriod.replacingOccurrences(of: " ", with: "_")
        let aptStr = sanitizeForFileName(settings.apartmentName.isEmpty ? "Apartman" : settings.apartmentName)
        panel.nameFieldStringValue = "\(aptStr)_Mali_Pano_Raporu_\(periodStr).pdf"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let noticeView = ApartmentBulletinBoardView(
            settings: settings,
            periodTitle: selectedPeriod == "all" ? l10n.allMonths : selectedPeriod,
            totalIncome: totalIncome,
            totalExpenses: totalExpenses,
            netBalance: netCashBalance,
            expenseCategories: expenseCategories,
            paidFlatsCount: flatDuesStatusList.filter { $0.isPaid }.count,
            totalFlatsCount: settings.flatCount,
            records: filteredRecords,
            l10n: l10n
        )
        .frame(width: 595, height: 842)
        .environment(\.colorScheme, .light)

        let renderer = ImageRenderer(content: noticeView)
        renderer.proposedSize = ProposedViewSize(width: 595, height: 842)

        var box = CGRect(origin: .zero, size: CGSize(width: 595, height: 842))
        guard let consumer = CGDataConsumer(url: url as CFURL),
              let pdfContext = CGContext(consumer: consumer, mediaBox: &box, nil) else {
            return
        }

        pdfContext.beginPDFPage(nil)
        renderer.render { size, context in
            context(pdfContext)
        }
        pdfContext.endPDFPage()
        pdfContext.closePDF()

        successNotice = l10n.saveSuccessPDF
    }
}

// MARK: - Batch Dues Generator Sheet

struct BatchDuesGeneratorSheet: View {
    @ObservedObject var settings: ReceiptSettingsStore
    var onComplete: () -> Void
    @Environment(\.presentationMode) private var presentationMode

    @State private var selectedPeriodDate: Date = Date()
    @State private var startSeq: String = ""
    @State private var duesAmount: String = ""
    @State private var selectedFlats: Set<Int> = []
    @State private var isDone: Bool = false
    @State private var generatedCount: Int = 0

    private var l10n: L10n { settings.l10n }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(l10n.batchDuesTitle)
                        .font(.system(size: 16, weight: .bold))
                    Text(l10n.batchDuesSubtitle)
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

            if isDone {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    Text("\(generatedCount) \(l10n.batchSuccessMessage)")
                        .font(.system(size: 15, weight: .bold))
                    Button(l10n.close) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)
            } else {
                // Form Configuration
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        // Period
                        VStack(alignment: .leading, spacing: 4) {
                            Text(l10n.period)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                            DatePicker("", selection: $selectedPeriodDate, displayedComponents: .date)
                                .labelsHidden()
                        }

                        // Starting Sequence #
                        VStack(alignment: .leading, spacing: 4) {
                            Text(l10n.startSequenceNumber)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                            TextField("106", text: $startSeq)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                        }

                        // Dues Amount
                        VStack(alignment: .leading, spacing: 4) {
                            Text(l10n.duesAmountPerFlat)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                            TextField("1750", text: $duesAmount)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 110)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)

                    Divider()

                    // Flat Selection Checklist Header
                    HStack {
                        Text("\(selectedFlats.count) / \(settings.flatCount) \(l10n.duesPaidCount)")
                            .font(.system(size: 12, weight: .bold))
                        Spacer()
                        Button(selectedFlats.count == settings.flatCount ? l10n.deselectAll : l10n.selectAll) {
                            if selectedFlats.count == settings.flatCount {
                                selectedFlats.removeAll()
                            } else {
                                selectedFlats = Set(settings.apartmentNumbers)
                            }
                        }
                        .font(.system(size: 11))
                        .buttonStyle(.link)
                    }
                    .padding(.horizontal, 20)

                    ScrollView {
                        LazyVStack(spacing: 6) {
                            ForEach(settings.apartmentNumbers, id: \.self) { flat in
                                let isSelected = selectedFlats.contains(flat)
                                let owner = settings.owner(for: flat)
                                HStack {
                                    Button {
                                        if isSelected {
                                            selectedFlats.remove(flat)
                                        } else {
                                            selectedFlats.insert(flat)
                                        }
                                    } label: {
                                        Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                                            .foregroundColor(isSelected ? .accentColor : .secondary)
                                            .font(.system(size: 14))
                                    }
                                    .buttonStyle(.plain)

                                    Text("\(l10n.flatPrefix) \(flat)")
                                        .font(.system(size: 12, weight: .bold))
                                        .frame(width: 70, alignment: .leading)

                                    Text(owner.isEmpty ? "—" : owner)
                                        .font(.system(size: 12))
                                        .foregroundColor(owner.isEmpty ? .secondary : .primary)

                                    Spacer()

                                    Text("\(duesAmount) \(settings.currency.symbol)")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                Divider()

                // Footer
                HStack {
                    Button(l10n.cancel) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .keyboardShortcut(.cancelAction)

                    Spacer()

                    Button {
                        executeBatchGeneration()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill")
                            Text("\(selectedFlats.count) \(l10n.generateBatchReceipts)")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedFlats.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
        .frame(minWidth: 640, idealWidth: 700, minHeight: 520, idealHeight: 580)
        .onAppear {
            startSeq = String(settings.seqNumber)
            duesAmount = settings.defaultPayment
            selectedFlats = Set(settings.apartmentNumbers)
        }
    }

    private func executeBatchGeneration() {
        guard let initialSeq = Int(startSeq), let amount = Double(duesAmount.replacingOccurrences(of: ",", with: ".")), amount >= 0 else {
            return
        }

        var currentSeq = initialSeq
        let sortedFlats = Array(selectedFlats).sorted()
        let periodStr = selectedPeriodDate.monthYearString(locale: settings.currentLocale)
        let dateStr = Date().dayMonthYearString(locale: settings.currentLocale)

        for flat in sortedFlats {
            let owner = settings.owner(for: flat)
            let receiverName = owner.isEmpty ? "\(settings.apartmentName) Sakini (Daire \(flat))" : owner

            let draft = ReceiptDraft(
                receiver: receiverName,
                issuer: settings.issuer,
                notes: "\(periodStr) dönemi bina ortak gider ve aidat payı",
                monthYear: periodStr,
                apartmentNumber: flat,
                amount: amount,
                sequenceNumber: currentSeq,
                createdDate: dateStr,
                showApartmentNumber: true,
                kind: .income,
                currency: settings.currency
            )

            ReceiptArchiveStore.shared.add(draft: draft)
            currentSeq += 1
        }

        settings.seqNumber = currentSeq
        generatedCount = sortedFlats.count
        isDone = true
        onComplete()
    }
}

// MARK: - Printable Apartment Bulletin Board Notice View (A4)

struct ApartmentBulletinBoardView: View {
    let settings: ReceiptSettingsStore
    let periodTitle: String
    let totalIncome: Double
    let totalExpenses: Double
    let netBalance: Double
    let expenseCategories: [(category: String, amount: Double, percent: Double)]
    let paidFlatsCount: Int
    let totalFlatsCount: Int
    let records: [ReceiptRecord]
    let l10n: L10n

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            HStack(alignment: .top) {
                if let logo = settings.logoImage {
                    Image(nsImage: logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                } else {
                    Default2DBuildingLogo(size: 48)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(settings.apartmentName.isEmpty ? l10n.defaultBuildingName : settings.apartmentName.uppercased())
                        .font(.system(size: 16, weight: .bold))
                    Text(l10n.bulletinBoardNoticeTitle)
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))
                    Text(periodTitle)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(Date().dayMonthYearString(locale: settings.currentLocale))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 6)

            Divider()

            // Financial Balance Cards (3 Columns)
            HStack(spacing: 12) {
                balanceBox(title: l10n.totalIncome, amount: totalIncome, color: .green, icon: "arrow.down.left.circle.fill")
                balanceBox(title: l10n.totalExpenses, amount: totalExpenses, color: .red, icon: "arrow.up.right.circle.fill")
                balanceBox(title: l10n.netCashBalance, amount: netBalance, color: netBalance >= 0 ? Color(red: 0.22, green: 0.42, blue: 0.88) : .red, icon: "banknote.fill")
            }

            // Dues Collection Status Bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(l10n.duesTrackingTab)
                        .font(.system(size: 11, weight: .bold))
                    Spacer()
                    Text("\(paidFlatsCount) / \(totalFlatsCount) \(l10n.duesPaidCount)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.green)
                }

                GeometryReader { geo in
                    let ratio = totalFlatsCount > 0 ? CGFloat(paidFlatsCount) / CGFloat(totalFlatsCount) : 0
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.15))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green)
                            .frame(width: geo.size.width * ratio, height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(10)
            .background(Color.secondary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Expense Categories Breakdown
            if !expenseCategories.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(l10n.presetUtilities)
                        .font(.system(size: 11, weight: .bold))

                    VStack(spacing: 6) {
                        ForEach(expenseCategories.prefix(6), id: \.category) { item in
                            HStack {
                                Text(item.category)
                                    .font(.system(size: 10.5, weight: .medium))
                                    .lineLimit(1)
                                Spacer()
                                Text(String(format: "%.2f %@", item.amount, settings.currency.symbol))
                                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                Text(String(format: "(%%%0.1f)", item.percent))
                                    .font(.system(size: 9.5))
                                    .foregroundColor(.secondary)
                                    .frame(width: 44, alignment: .trailing)
                            }
                            .padding(.vertical, 2)
                            Divider()
                        }
                    }
                }
                .padding(12)
                .background(Color.secondary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Spacer()

            // Footer & Manager Signature
            Divider()

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(l10n.bulletinBoardNoticeFooter)
                        .font(.system(size: 9.5))
                        .foregroundColor(.secondary)
                    Text("AptReceipt • Doğrulanabilir Dijital Apartman Yönetim Sistemi")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary.opacity(0.7))
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    Text(l10n.managerSignatureTitle)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)

                    if let sig = settings.signatureImage {
                        Image(nsImage: sig)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 35)
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 90, height: 35)
                    }

                    Text(settings.issuer.isEmpty ? l10n.managerSignatureTitle : settings.issuer)
                        .font(.system(size: 10.5, weight: .bold))
                }
            }
        }
        .padding(36)
        .frame(width: 595, height: 842)
        .background(Color.white)
    }

    private func balanceBox(title: String, amount: Double, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
            }
            Text(String(format: "%.2f %@", amount, settings.currency.symbol))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

extension Notification.Name {
    static let appLanguageDidChange = Notification.Name("appLanguageDidChange")
    static let settingsDidSave = Notification.Name("settingsDidSave")
}
