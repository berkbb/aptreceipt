import Foundation

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
