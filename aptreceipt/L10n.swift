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

    /// Looks up `key` in Localizable.xcstrings for the in-app language (which may differ
    /// from the system language), falling back to English and then to the key itself.
    private func tr(_ key: String) -> String {
        let english = Self.bundle(for: .english).localizedString(forKey: key, value: key, table: nil)
        guard resolvedLanguage != .english else { return english }
        return Self.bundle(for: resolvedLanguage).localizedString(forKey: key, value: english, table: nil)
    }

    private static let languageBundles: [AppLanguage: Bundle] = {
        var bundles: [AppLanguage: Bundle] = [:]
        for language in [AppLanguage.english, .turkish, .romanian] {
            if let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"), let bundle = Bundle(path: path) {
                bundles[language] = bundle
            }
        }
        return bundles
    }()

    private static func bundle(for language: AppLanguage) -> Bundle {
        languageBundles[language] ?? .main
    }

    // App Header & Base
    var appTitle: String { "AptReceipt" }
    var appSubtitle: String { tr("appSubtitle") }
    var preferences: String { tr("preferences") }
    var settingsTitle: String { tr("settingsTitle") }
    var settingsSubtitle: String { tr("settingsSubtitle") }

    // Receipt Type
    var receiptType: String { tr("receiptType") }
    var incomeTitle: String { tr("incomeTitle") }
    var outcomeTitle: String { tr("outcomeTitle") }
    var managementExpenseTitle: String { tr("managementExpenseTitle") }
    var incomeBadge: String { tr("incomeBadge") }
    var outcomeBadge: String { tr("outcomeBadge") }
    var managementExpenseBadge: String { tr("managementExpenseBadge") }

    // Flat & Period
    var flatAndPeriod: String { tr("flatAndPeriod") }
    var flatNumber: String { tr("flatNumber") }
    var flatPrefix: String { tr("flatPrefix") }
    var period: String { tr("period") }
    var printFlatNumber: String { tr("printFlatNumber") }

    // Parties
    var parties: String { tr("parties") }
    var issuerLabel: String { tr("issuerLabel") }
    var issuerPlaceholder: String { tr("issuerPlaceholder") }
    var receiverLabel: String { tr("receiverLabel") }
    var receiverPlaceholder: String { tr("receiverPlaceholder") }
    var fetchSavedResident: String { tr("fetchSavedResident") }

    // Financial & Notes
    var financialDetails: String { tr("financialDetails") }
    var amount: String { tr("amount") }
    var sequenceNo: String { tr("sequenceNo") }
    var notesLabel: String { tr("notesLabel") }
    var notesPlaceholder: String { tr("notesPlaceholder") }

    // Actions
    var clearForm: String { tr("clearForm") }
    var createReceipt: String { tr("createReceipt") }

    // Live Preview & Document
    var livePreview: String { tr("livePreview") }
    var printViewBadge: String { tr("printViewBadge") }
    var totalPaid: String { tr("totalPaid") }
    var totalCollected: String { tr("totalCollected") }
    var descriptionHeader: String { tr("descriptionHeader") }
    var receiptNo: String { tr("receiptNo") }
    var issueDate: String { tr("issueDate") }
    var dateLabel: String { tr("dateLabel") }
    var authorizedSignature: String { tr("authorizedSignature") }
    var electronicDisclaimer: String { tr("electronicDisclaimer") }
    var defaultBuildingName: String { tr("defaultBuildingName") }

    // Sheet Actions
    var previewTitle: String { tr("previewTitle") }
    var previewSubtitle: String { tr("previewSubtitle") }
    var close: String { tr("close") }
    var cancel: String { tr("cancel") }
    var saveAndClose: String { tr("saveAndClose") }
    var saveAsJPEG: String { tr("saveAsJPEG") }
    var saveAsPDF: String { tr("saveAsPDF") }
    var saveSuccess: String { tr("saveSuccess") }
    var saveSuccessPDF: String { tr("saveSuccessPDF") }
    var saveSuccessJPEG: String { tr("saveSuccessJPEG") }

    // Invoice Specific Strings
    var invoiceDocumentTitle: String { tr("invoiceDocumentTitle") }
    var invoiceSubHeader: String { tr("invoiceSubHeader") }
    var invoiceTypeLabel: String { tr("invoiceTypeLabel") }
    var serialLabel: String { tr("serialLabel") }
    var managerSectionTitle: String { tr("managerSectionTitle") }
    var payerSectionTitle: String { tr("payerSectionTitle") }
    var itemNo: String { tr("itemNo") }
    var itemDescription: String { tr("itemDescription") }
    var itemPeriod: String { tr("itemPeriod") }
    var itemUnit: String { tr("itemUnit") }
    var unitMonth: String { tr("unitMonth") }
    var itemAmount: String { tr("itemAmount") }
    var subtotal: String { tr("subtotal") }
    var vatTax: String { tr("vatTax") }
    var vatExempt: String { tr("vatExempt") }
    var grandTotal: String { tr("grandTotal") }
    var inWordsPrefix: String { tr("inWordsPrefix") }
    var signatureStamp: String { tr("signatureStamp") }
    var barcodeSerialText: String { tr("barcodeSerialText") }
    var legalStatutoryNotice: String { tr("legalStatutoryNotice") }
    var statutoryTaxNotice: String { tr("statutoryTaxNotice") }
    var incomeDocumentType: String { tr("incomeDocumentType") }
    var expenseDocumentType: String { tr("expenseDocumentType") }
    var managementExpenseDocumentType: String { tr("managementExpenseDocumentType") }
    var defaultItemNameIncome: String { tr("defaultItemNameIncome") }
    var defaultItemNameExpense: String { tr("defaultItemNameExpense") }
    var defaultItemNameManagementExpense: String { tr("defaultItemNameManagementExpense") }
    var commonAreaLabel: String { tr("commonAreaLabel") }
    var invoiceBuildingLabel: String { tr("invoiceBuildingLabel") }
    var invoiceManagerLabel: String { tr("invoiceManagerLabel") }
    var invoicePayerResidentLabel: String { tr("invoicePayerResidentLabel") }
    var invoiceVendorLabel: String { tr("invoiceVendorLabel") }
    var invoiceUnitLabel: String { tr("invoiceUnitLabel") }
    var vendorLabel: String { tr("vendorLabel") }
    var vendorPlaceholder: String { tr("vendorPlaceholder") }
    var managerPayerLabel: String { tr("managerPayerLabel") }
    var vendorSectionTitle: String { tr("vendorSectionTitle") }

    // Quick Expense Presets
    var quickPresetsLabel: String { tr("quickPresetsLabel") }
    var presetElevator: String { tr("presetElevator") }
    var presetElevatorDesc: String { tr("presetElevatorDesc") }
    var presetCleaning: String { tr("presetCleaning") }
    var presetCleaningDesc: String { tr("presetCleaningDesc") }
    var presetUtilities: String { tr("presetUtilities") }
    var presetUtilitiesDesc: String { tr("presetUtilitiesDesc") }
    var presetRepairs: String { tr("presetRepairs") }
    var presetRepairsDesc: String { tr("presetRepairsDesc") }
    var presetGardening: String { tr("presetGardening") }
    var presetGardeningDesc: String { tr("presetGardeningDesc") }

    // Settings Tabs
    var tabBuilding: String { tr("tabBuilding") }
    var tabResidents: String { tr("tabResidents") }
    var tabAppearance: String { tr("tabAppearance") }
    var tabSignature: String { tr("tabSignature") }
    var tabBackup: String { tr("tabBackup") }
    var tabAbout: String { tr("tabAbout") }

    // Archive & History Strings
    var archiveTitle: String { tr("archiveTitle") }
    var archiveSubtitle: String { tr("archiveSubtitle") }
    var archiveSearchPlaceholder: String { tr("archiveSearchPlaceholder") }
    var filterAll: String { tr("filterAll") }
    var filterIncome: String { tr("filterIncome") }
    var filterOutcome: String { tr("filterOutcome") }
    var filterManagement: String { tr("filterManagement") }
    var totalArchived: String { tr("totalArchived") }
    var openReceipt: String { tr("openReceipt") }
    var deleteReceipt: String { tr("deleteReceipt") }
    var exportCSV: String { tr("exportCSV") }
    var archiveEmpty: String { tr("archiveEmpty") }
    var archiveButton: String { tr("archiveButton") }

    // WhatsApp & Sharing Strings
    var shareWhatsApp: String { tr("shareWhatsApp") }
    var shareEmail: String { tr("shareEmail") }
    var residentPhone: String { tr("residentPhone") }
    var residentPhonePlaceholder: String { tr("residentPhonePlaceholder") }

    // Invoice Import & Attachment Strings
    var importInvoice: String { tr("importInvoice") }
    var dropInvoiceSubtitle: String { tr("dropInvoiceSubtitle") }
    var scanningInvoice: String { tr("scanningInvoice") }
    var invoiceScanSuccess: String { tr("invoiceScanSuccess") }
    var attachedInvoice: String { tr("attachedInvoice") }
    var viewInvoice: String { tr("viewInvoice") }
    var removeInvoice: String { tr("removeInvoice") }
    var invoiceNumberPrefix: String { tr("invoiceNumberPrefix") }
    var viewAttachedInvoice: String { tr("viewAttachedInvoice") }

    // QR Code Verification Strings
    var qrVerificationNotice: String { tr("qrVerificationNotice") }
    var qrCodeActive: String { tr("qrCodeActive") }

    // Backup & Restore Strings
    var backupTitle: String { tr("backupTitle") }
    var backupSubtitle: String { tr("backupSubtitle") }
    var exportBackupButton: String { tr("exportBackupButton") }
    var importBackupButton: String { tr("importBackupButton") }
    var backupExportSuccess: String { tr("backupExportSuccess") }
    var backupImportSuccess: String { tr("backupImportSuccess") }
    var backupImportError: String { tr("backupImportError") }
    var backupNotice: String { tr("backupNotice") }

    // Financial Report & Bulletin Board Strings
    var financialReportTitle: String { tr("financialReportTitle") }
    var financialReportSubtitle: String { tr("financialReportSubtitle") }
    var exportBulletinBoardPDF: String { tr("exportBulletinBoardPDF") }
    var totalIncome: String { tr("totalIncome") }
    var totalExpenses: String { tr("totalExpenses") }
    var netCashBalance: String { tr("netCashBalance") }
    var allMonths: String { tr("allMonths") }
    var duesTrackingTab: String { tr("duesTrackingTab") }
    var financialSummaryTab: String { tr("financialSummaryTab") }
    var allTransactionsTab: String { tr("allTransactionsTab") }
    var paidStatus: String { tr("paidStatus") }
    var unpaidStatus: String { tr("unpaidStatus") }
    var remindWhatsApp: String { tr("remindWhatsApp") }
    var duesPaidCount: String { tr("duesPaidCount") }
    var duesPendingCount: String { tr("duesPendingCount") }
    var bulletinBoardNoticeTitle: String { tr("bulletinBoardNoticeTitle") }
    var bulletinBoardNoticeFooter: String { tr("bulletinBoardNoticeFooter") }
    var managerSignatureTitle: String { tr("managerSignatureTitle") }

    // Batch Dues Generation Strings
    var batchDuesTitle: String { tr("batchDuesTitle") }
    var batchDuesSubtitle: String { tr("batchDuesSubtitle") }
    var startSequenceNumber: String { tr("startSequenceNumber") }
    var duesAmountPerFlat: String { tr("duesAmountPerFlat") }
    var generateBatchReceipts: String { tr("generateBatchReceipts") }
    var batchSuccessMessage: String { tr("batchSuccessMessage") }
    var selectAll: String { tr("selectAll") }
    var deselectAll: String { tr("deselectAll") }

    // MARK: - Late Payment Compensation & Penalty Strings
    var lateFeeEnableToggle: String { tr("lateFeeEnableToggle") }
    var lateFeeTitle: String { tr("lateFeeTitle") }
    var lateFeeSubtitle: String { tr("lateFeeSubtitle") }
    var lateFeeEnabledToggle: String { tr("lateFeeEnabledToggle") }
    var lateFeeCountryProfileTitle: String { tr("lateFeeCountryProfileTitle") }
    var lateFeeMonthlyRateTitle: String { tr("lateFeeMonthlyRateTitle") }
    var lateFeeDueDayTitle: String { tr("lateFeeDueDayTitle") }
    var lateFeeGracePeriodTitle: String { tr("lateFeeGracePeriodTitle") }
    var lateFeeCustomFootnoteTitle: String { tr("lateFeeCustomFootnoteTitle") }
    var lateFeeResetFootnoteButton: String { tr("lateFeeResetFootnoteButton") }
    var lateFeeShortBadge: String { tr("lateFeeShortBadge") }
    var lateFeeDisabledInSettingsNotice: String { tr("lateFeeDisabledInSettingsNotice") }
    var lateFeeLegalNotice: String { tr("lateFeeLegalNotice") }
    var lateFeeApplyCheckbox: String { tr("lateFeeApplyCheckbox") }
    var overdueMonthsCount: String { tr("overdueMonthsCount") }
    var monthUnit: String { tr("monthUnit") }
    var monthsUnit: String { tr("monthsUnit") }
    var autoDetectOverdue: String { tr("autoDetectOverdue") }
    var baseDuesAmount: String { tr("baseDuesAmount") }
    var lateFeeCalculated: String { tr("lateFeeCalculated") }
    var totalWithLateFee: String { tr("totalWithLateFee") }
    var statutoryRateChip: String { tr("statutoryRateChip") }
    var statutoryRateLabel: String { tr("statutoryRateLabel") }
    var dueDayDayPrefix: String { tr("dueDayDayPrefix") }
    var dueDayDaySuffix: String { tr("dueDayDaySuffix") }
    func batchReceiverFallback(buildingName: String, flat: Int) -> String {
        String(format: tr("batchReceiverFallback"), buildingName, flat)
    }

    func batchReceiptNote(period: String) -> String {
        String(format: tr("batchReceiptNote"), period)
    }

    var bulletinFooterTagline: String { tr("bulletinFooterTagline") }

    func bulletinPdfFileName(building: String, period: String) -> String {
        String(format: tr("bulletinPdfFileName"), building, period)
    }

    func lateFeeItemName(rate: Double, months: Int) -> String {
        let format = tr(months > 1 ? "lateFeeItemName.other" : "lateFeeItemName.one")
        return String(format: format, AppFormat.percent(rate, l10n: self, maximumFractionDigits: 2), months)
    }
    var lateFeeStatutoryFootnote: String {
        tr("lateFeeStatutoryFootnote")
    }

    // Settings Form Fields
    var buildingDetails: String { tr("buildingDetails") }
    var buildingName: String { tr("buildingName") }
    var defaultManager: String { tr("defaultManager") }
    var totalFlats: String { tr("totalFlats") }
    var financialSettings: String { tr("financialSettings") }
    var defaultDues: String { tr("defaultDues") }
    var nextReceiptNo: String { tr("nextReceiptNo") }

    // Currency Strings
    var currencySection: String { tr("currencySection") }
    var currencySelection: String { tr("currencySelection") }
    var currencyTRY: String { tr("currencyTRY") }
    var currencyRON: String { tr("currencyRON") }
    var currencyUSD: String { tr("currencyUSD") }
    var currencyEUR: String { tr("currencyEUR") }
    var currencyGBP: String { tr("currencyGBP") }

    // MARK: - Menu Bar Strings
    var menuApp: String { "AptReceipt" }
    var menuFile: String { tr("menuFile") }
    var menuEdit: String { tr("menuEdit") }
    var menuView: String { tr("menuView") }
    var menuWindow: String { tr("menuWindow") }
    var menuHelp: String { tr("menuHelp") }

    // App Submenu
    var menuAboutApp: String { tr("menuAboutApp") }
    var menuSettings: String { tr("menuSettings") }
    var menuServices: String { tr("menuServices") }
    var menuHideApp: String { tr("menuHideApp") }
    var menuHideOthers: String { tr("menuHideOthers") }
    var menuShowAll: String { tr("menuShowAll") }
    var menuQuitApp: String { tr("menuQuitApp") }

    // File Submenu
    var menuNewWindow: String { tr("menuNewWindow") }
    var menuCloseWindow: String { tr("menuCloseWindow") }

    // Edit Submenu
    var menuUndo: String { tr("menuUndo") }
    var menuRedo: String { tr("menuRedo") }
    var menuCut: String { tr("menuCut") }
    var menuCopy: String { tr("menuCopy") }
    var menuPaste: String { tr("menuPaste") }
    var menuPasteAndMatch: String { tr("menuPasteAndMatch") }
    var menuDelete: String { tr("menuDelete") }
    var menuSelectAll: String { tr("menuSelectAll") }

    // View Submenu
    var menuFullScreen: String { tr("menuFullScreen") }

    // Window Submenu
    var menuMinimize: String { tr("menuMinimize") }
    var menuZoom: String { tr("menuZoom") }
    var menuBringAllToFront: String { tr("menuBringAllToFront") }

    // Help Submenu
    var menuHelpItem: String { tr("menuHelpItem") }

    // Language Restart Warning Strings
    var restartWarningTitle: String { tr("restartWarningTitle") }
    var restartMenuBarNotice: String { tr("restartMenuBarNotice") }

    // Sample Defaults Strings
    var sampleDefaultsSection: String { tr("sampleDefaultsSection") }
    var sampleDefaultsDesc: String { tr("sampleDefaultsDesc") }
    var loadSampleDefaultsButton: String { tr("loadSampleDefaultsButton") }
    var sampleDefaultsLoadedFeedback: String { tr("sampleDefaultsLoadedFeedback") }

    // Appearance & Language Tab
    var appearanceSection: String { tr("appearanceSection") }
    var themeSelection: String { tr("themeSelection") }
    var themeSystem: String { tr("themeSystem") }
    var themeLight: String { tr("themeLight") }
    var themeDark: String { tr("themeDark") }

    var languageSection: String { tr("languageSection") }
    var languageSelection: String { tr("languageSelection") }
    var langSystem: String { tr("langSystem") }

    // Residents Directory
    var residentsDirectoryTitle: String { tr("residentsDirectoryTitle") }
    var residentsDirectoryDesc: String { tr("residentsDirectoryDesc") }
    var flatLabel: String { tr("flatLabel") }
    var residentNamePlaceholder: String { tr("residentNamePlaceholder") }
    var saveButton: String { tr("saveButton") }
    var residentSavedFeedback: String { tr("residentSavedFeedback") }
    var totalFlatsBadge: String { tr("totalFlatsBadge") }
    var registeredResidentsBadge: String { tr("registeredResidentsBadge") }
    var vacantFlatsBadge: String { tr("vacantFlatsBadge") }
    var searchNeighborsPlaceholder: String { tr("searchNeighborsPlaceholder") }
    var fillSampleResidentsButton: String { tr("fillSampleResidentsButton") }
    var clearAllResidentsButton: String { tr("clearAllResidentsButton") }
    var clearResidentButton: String { tr("clearResidentButton") }
    var flatUnassigned: String { tr("flatUnassigned") }
    var flatAssigned: String { tr("flatAssigned") }
    var noMatchingResidents: String { tr("noMatchingResidents") }

    // Signature Tab
    var signatureTitle: String { tr("signatureTitle") }
    var signatureDesc: String { tr("signatureDesc") }
    var uploadSignatureButton: String { tr("uploadSignatureButton") }
    var removeSignatureButton: String { tr("removeSignatureButton") }
    var loadedSignature: String { tr("loadedSignature") }
    var noSignatureYet: String { tr("noSignatureYet") }

    // About Tab & License
    var appVersionText: String { tr("appVersionText") }
    var publisher: String { tr("publisher") }
    var license: String { tr("license") }
    var copyright: String { tr("copyright") }
    var viewLicenseButton: String { tr("viewLicenseButton") }
    var licenseViewerTitle: String { tr("licenseViewerTitle") }
    var licenseViewerSubtitle: String { tr("licenseViewerSubtitle") }
    var copyLicenseText: String { tr("copyLicenseText") }
    var licenseCopied: String { tr("licenseCopied") }
    var aboutWindowHeader: String { tr("aboutWindowHeader") }
    var githubRepository: String { tr("githubRepository") }
    var appDescription: String { tr("appDescription") }

    func aboutVersion(_ version: String, _ build: String) -> String {
        String(format: tr("aboutVersionFormat"), version, build)
    }

    func aboutCopyright(_ year: String) -> String {
        String(format: tr("aboutCopyrightFormat"), year)
    }

    // Software Update Strings
    var checkForUpdates: String { tr("checkForUpdates") }
    var checkForUpdatesButton: String { tr("checkForUpdatesButton") }
    var checkingForUpdates: String { tr("checkingForUpdates") }
    var updateAvailableTitle: String { tr("updateAvailableTitle") }
    var upToDateTitle: String { tr("upToDateTitle") }
    var upToDateMessage: String { tr("upToDateMessage") }
    var downloadUpdate: String { tr("downloadUpdate") }
    var laterButton: String { tr("laterButton") }
    var updateCheckFailedTitle: String { tr("updateCheckFailedTitle") }
    var updateCheckFailedMessage: String { tr("updateCheckFailedMessage") }
    var updateErrorOffline: String { tr("updateErrorOffline") }
    var updateErrorTimedOut: String { tr("updateErrorTimedOut") }
    var updateErrorNoPublicRelease: String { tr("updateErrorNoPublicRelease") }
    var installedVersionLabel: String { tr("installedVersionLabel") }
    var updateStatusLabel: String { tr("updateStatusLabel") }
    var updateStatusIdle: String { tr("updateStatusIdle") }
    var checkNowButton: String { tr("checkNowButton") }
    var downloadVersionFormat: String { tr("downloadVersionFormat") }
    var checkUpdatesAtLaunchToggle: String { tr("checkUpdatesAtLaunchToggle") }
    var checkUpdatesAtLaunchFooter: String { tr("checkUpdatesAtLaunchFooter") }
    var resetSectionHeader: String { tr("resetSectionHeader") }
    var resetSettingsButton: String { tr("resetSettingsButton") }
    var resetSettingsConfirmTitle: String { tr("resetSettingsConfirmTitle") }
    var resetSettingsConfirmAction: String { tr("resetSettingsConfirmAction") }
    var resetSettingsFooter: String { tr("resetSettingsFooter") }
    var updateErrorRateLimited: String { tr("updateErrorRateLimited") }
    var updateErrorServer: String { tr("updateErrorServer") }
    var updateErrorBadResponse: String { tr("updateErrorBadResponse") }
    var updateErrorInvalidData: String { tr("updateErrorInvalidData") }
    var updateErrorUnexpected: String { tr("updateErrorUnexpected") }
    var openReleasesPage: String { tr("openReleasesPage") }
    var isNowAvailableText: String { tr("isNowAvailableText") }
    var currentVersionPrefix: String { tr("currentVersionPrefix") }
    var lastChecked: String { tr("lastChecked") }
    var neverChecked: String { tr("neverChecked") }
    var softwareUpdateSection: String { tr("softwareUpdateSection") }
    var softwareUpdateDesc: String { tr("softwareUpdateDesc") }
    var downloadingUpdateTitle: String { tr("downloadingUpdateTitle") }
    var cancelDownloadButton: String { tr("cancelDownloadButton") }
    var updateDownloadedTitle: String { tr("updateDownloadedTitle") }
    var updateDownloadedMessage: String { tr("updateDownloadedMessage") }
    var updateDownloadedNotOpenedMessage: String { tr("updateDownloadedNotOpenedMessage") }
    var quitAndInstallButton: String { tr("quitAndInstallButton") }
    var showInFinderButton: String { tr("showInFinderButton") }
    var updateDownloadFailedTitle: String { tr("updateDownloadFailedTitle") }
    var updateDownloadFailedMessage: String { tr("updateDownloadFailedMessage") }

    // Validation Messages
    var validationErrorTitle: String { tr("validationErrorTitle") }
    var okButton: String { tr("okButton") }
    var errIssuerRequired: String { tr("errIssuerRequired") }
    var errReceiverRequired: String { tr("errReceiverRequired") }
    var errSequenceInvalid: String { tr("errSequenceInvalid") }
    var errAmountInvalid: String { tr("errAmountInvalid") }
    var errBuildingIssuerRequired: String { tr("errBuildingIssuerRequired") }
    var errFlatCountInvalid: String { tr("errFlatCountInvalid") }

    // Placeholders & Labels
    var buildingNamePlaceholder: String { tr("buildingNamePlaceholder") }
    var defaultManagerPlaceholder: String { tr("defaultManagerPlaceholder") }
    var totalFlatsPlaceholder: String { tr("totalFlatsPlaceholder") }
    var publisherLabel: String { tr("publisherLabel") }
    var licenseLabel: String { tr("licenseLabel") }

    // Building Logo
    var buildingLogoSection: String { tr("buildingLogoSection") }
    var buildingLogoDesc: String { tr("buildingLogoDesc") }
    var uploadLogoButton: String { tr("uploadLogoButton") }
    var removeLogoButton: String { tr("removeLogoButton") }
    var activeLogoBadge: String { tr("activeLogoBadge") }
    var default2DLogoBadge: String { tr("default2DLogoBadge") }

    // Settings Hero Strings
    var buildingHeroBadge: String { tr("buildingHeroBadge") }
    var heroQuickFlats: String { tr("heroQuickFlats") }
    var heroStatsFlats: String { tr("heroStatsFlats") }
    var heroStatsManager: String { tr("heroStatsManager") }
    var heroStatsDues: String { tr("heroStatsDues") }
    var heroStatsNextReceipt: String { tr("heroStatsNextReceipt") }
    var heroNotSpecified: String { tr("heroNotSpecified") }
    var quickScenarioTitle: String { tr("quickScenarioTitle") }
    var quickScenarioSubtitle: String { tr("quickScenarioSubtitle") }
    var sampleScenarioTR: String { tr("sampleScenarioTR") }
    var sampleScenarioEN: String { tr("sampleScenarioEN") }
    var sampleScenarioRO: String { tr("sampleScenarioRO") }
    var sampleScenarioDescTR: String { tr("sampleScenarioDescTR") }
    var sampleScenarioDescEN: String { tr("sampleScenarioDescEN") }
    var sampleScenarioDescRO: String { tr("sampleScenarioDescRO") }
    var applyScenarioButton: String { tr("applyScenarioButton") }

    // Vendors & Services Tab Strings
    var tabVendors: String { tr("tabVendors") }
    var vendorsTitle: String { tr("vendorsTitle") }
    var vendorsSubtitle: String { tr("vendorsSubtitle") }
    var registeredVendorsBadge: String { tr("registeredVendorsBadge") }
    var presetServicesBadge: String { tr("presetServicesBadge") }
    var addVendorButton: String { tr("addVendorButton") }
    var vendorNameField: String { tr("vendorNameField") }
    var vendorCategoryField: String { tr("vendorCategoryField") }
    var vendorContactField: String { tr("vendorContactField") }
    var saveVendorButton: String { tr("saveVendorButton") }
    var deleteButton: String { tr("deleteButton") }
    var vendorListHeader: String { tr("vendorListHeader") }
    var serviceListHeader: String { tr("serviceListHeader") }
    var serviceNameField: String { tr("serviceNameField") }
    var serviceDescriptionField: String { tr("serviceDescriptionField") }
    var serviceSuggestedVendorField: String { tr("serviceSuggestedVendorField") }
    var addServiceButton: String { tr("addServiceButton") }
    var saveServiceButton: String { tr("saveServiceButton") }
    var loadSampleVendorsButton: String { tr("loadSampleVendorsButton") }
    var sampleVendorsLoadedFeedback: String { tr("sampleVendorsLoadedFeedback") }
    var selectSavedVendor: String { tr("selectSavedVendor") }
    var selectSavedService: String { tr("selectSavedService") }
    var searchVendorsPlaceholder: String { tr("searchVendorsPlaceholder") }
    var noVendorsFound: String { tr("noVendorsFound") }
    var noServicesFound: String { tr("noServicesFound") }
    var commonAreaOperatingBadge: String { tr("commonAreaOperatingBadge") }
    var payeeVendorCardTitle: String { tr("payeeVendorCardTitle") }
    var serviceExpenseCardTitle: String { tr("serviceExpenseCardTitle") }
    var quickServicesLabel: String { tr("quickServicesLabel") }
    var customExpenseNotePlaceholder: String { tr("customExpenseNotePlaceholder") }
    var langDescTR: String { tr("langDescTR") }
    var langDescEN: String { tr("langDescEN") }
    var langDescRO: String { tr("langDescRO") }
    var langDescSystem: String { tr("langDescSystem") }
}
