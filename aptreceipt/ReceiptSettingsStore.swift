import AppKit
import SwiftUI

// MARK: - Store

@MainActor
final class ReceiptSettingsStore: ObservableObject {
    /// The app's settings. During a screenshot run they live in memory only (`ScreenshotMode`).
    static let shared = ReceiptSettingsStore(defaults: ScreenshotMode.settingsDefaults())

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
    /// Opt-in: nothing is sent to GitHub at launch unless the user turns this on (see user_rejected_spec.md).
    @Published var checkUpdatesAtLaunch: Bool {
        didSet { defaults.set(checkUpdatesAtLaunch, forKey: Keys.checkUpdatesAtLaunch) }
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

    var l10n: L10n {
        L10n(language)
    }

    var currentLocale: Locale {
        l10n.locale
    }

    /// Backing store. The app uses `.standard`; tests and screenshot runs pass `InMemoryDefaults` so they never touch real user data.
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let savedLang = defaults.string(forKey: Keys.language) ?? Defaults.language.rawValue
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

        let savedTheme = defaults.string(forKey: Keys.theme) ?? Defaults.theme.rawValue
        let resolvedTheme = AppTheme(rawValue: savedTheme) ?? .system
        theme = resolvedTheme

        isLateFeeEnabled = defaults.bool(forKey: Keys.isLateFeeEnabled)
        let savedFeeRate = defaults.double(forKey: Keys.lateFeeMonthlyRate)
        lateFeeMonthlyRate = savedFeeRate > 0 ? savedFeeRate : Defaults.lateFeeMonthlyRate
        let savedDueDay = defaults.integer(forKey: Keys.lateFeeDueDay)
        lateFeeDueDay = savedDueDay > 0 ? savedDueDay : Defaults.lateFeeDueDay

        let savedProfile = defaults.string(forKey: Keys.lateFeeCountryProfile)
        let resolvedProfile = savedProfile.flatMap(LateFeeCountryProfile.init(rawValue:)) ?? LateFeeCountryProfile.default(for: resolvedLang)
        lateFeeCountryProfile = resolvedProfile
        let savedGrace = defaults.integer(forKey: Keys.lateFeeGracePeriodDays)
        lateFeeGracePeriodDays = defaults.object(forKey: Keys.lateFeeGracePeriodDays) != nil ? savedGrace : resolvedProfile.defaultGraceDays
        lateFeeCustomFootnote = defaults.string(forKey: Keys.lateFeeCustomFootnote) ?? Defaults.lateFeeCustomFootnote
        checkUpdatesAtLaunch = defaults.bool(forKey: Keys.checkUpdatesAtLaunch)

        signatureData = defaults.data(forKey: Keys.signature)
        logoData = defaults.data(forKey: Keys.logo)

        applyTheme(resolvedTheme)
    }

    /// Fresh-install values of the preferences that "Reset Settings…" restores.
    enum Defaults {
        static let language = AppLanguage.english
        static let theme = AppTheme.system
        static let isLateFeeEnabled = false
        static let lateFeeMonthlyRate = 5.0
        static let lateFeeDueDay = 15
        static let lateFeeCustomFootnote = ""
        static let checkUpdatesAtLaunch = false
    }

    /// Restores preferences only: language, theme, currency, late-fee configuration and the launch
    /// update check. Building data, residents, phones, vendors, services, receipts, logo, signature and
    /// the receipt sequence are never touched.
    func resetPreferencesToDefaults() {
        language = Defaults.language
        theme = Defaults.theme
        currency = AppCurrency.default(for: Defaults.language)

        let profile = LateFeeCountryProfile.default(for: Defaults.language)
        for savedProfile in LateFeeCountryProfile.allCases {
            defaults.removeObject(forKey: Keys.lateFeeRate(for: savedProfile))
        }
        isLateFeeEnabled = Defaults.isLateFeeEnabled
        lateFeeCountryProfile = profile
        lateFeeMonthlyRate = Defaults.lateFeeMonthlyRate
        lateFeeDueDay = Defaults.lateFeeDueDay
        lateFeeGracePeriodDays = profile.defaultGraceDays
        lateFeeCustomFootnote = Defaults.lateFeeCustomFootnote
        checkUpdatesAtLaunch = Defaults.checkUpdatesAtLaunch
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
        static let checkUpdatesAtLaunch = "check_updates_at_launch"

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

// MARK: - In-memory defaults

/// `UserDefaults` that keeps every value in memory and never reads or writes a preferences file.
/// Used by tests and screenshot runs so sample data never reaches the user's settings. A named suite
/// would not do: cfprefsd writes its plist back to ~/Library/Preferences even after the domain is removed.
final class InMemoryDefaults: UserDefaults {
    private var values: [String: Any] = [:]

    convenience init() {
        self.init(suiteName: nil)!
    }

    override init?(suiteName suitename: String?) {
        super.init(suiteName: suitename)
    }

    override func object(forKey defaultName: String) -> Any? { values[defaultName] }
    override func set(_ value: Any?, forKey defaultName: String) { values[defaultName] = value }
    override func set(_ value: Bool, forKey defaultName: String) { values[defaultName] = value }
    override func set(_ value: Int, forKey defaultName: String) { values[defaultName] = value }
    override func set(_ value: Double, forKey defaultName: String) { values[defaultName] = value }
    override func set(_ value: Float, forKey defaultName: String) { values[defaultName] = value }
    override func set(_ url: URL?, forKey defaultName: String) { values[defaultName] = url }
    override func removeObject(forKey defaultName: String) { values[defaultName] = nil }
    override func string(forKey defaultName: String) -> String? { values[defaultName] as? String }
    override func data(forKey defaultName: String) -> Data? { values[defaultName] as? Data }
    override func array(forKey defaultName: String) -> [Any]? { values[defaultName] as? [Any] }
    override func stringArray(forKey defaultName: String) -> [String]? { values[defaultName] as? [String] }
    override func dictionary(forKey defaultName: String) -> [String: Any]? { values[defaultName] as? [String: Any] }
    override func url(forKey defaultName: String) -> URL? { values[defaultName] as? URL }
    override func dictionaryRepresentation() -> [String: Any] { values }
    override func bool(forKey defaultName: String) -> Bool { (values[defaultName] as? NSNumber)?.boolValue ?? false }
    override func integer(forKey defaultName: String) -> Int {
        if let string = values[defaultName] as? String { return Int(string) ?? 0 }
        return (values[defaultName] as? NSNumber)?.intValue ?? 0
    }
    override func double(forKey defaultName: String) -> Double {
        if let string = values[defaultName] as? String { return Double(string) ?? 0 }
        return (values[defaultName] as? NSNumber)?.doubleValue ?? 0
    }
    override func float(forKey defaultName: String) -> Float { Float(double(forKey: defaultName)) }
}
