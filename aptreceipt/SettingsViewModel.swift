import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Settings View Model

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var selectedTab: SettingsTab = .general
    @Published var apartmentName: String = ""
    @Published var issuer: String = ""
    @Published var defaultPayment: String = ""
    @Published var flatCount: String = "1"
    @Published var sequenceNumber: String = "1"
    @Published var language: AppLanguage = .system
    @Published var theme: AppTheme = .system
    @Published var currency: AppCurrency = .turkishLira
    @Published var isLateFeeEnabled: Bool = false
    @Published var lateFeeMonthlyRate: String = "5.0"
    @Published var lateFeeDueDay: Int = 15
    @Published var lateFeeCountryProfile: LateFeeCountryProfile = .international
    @Published var lateFeeGracePeriodDays: Int = 0
    @Published var lateFeeCustomFootnote: String = ""
    @Published var showRestartAlert: Bool = false
    @Published var showSampleDefaultsFeedback: Bool = false

    @Published var residents: [Int: String] = [:]
    @Published var residentPhones: [Int: String] = [:]
    @Published var residentSearchQuery: String = ""
    @Published var backupSuccessMessage: String? = nil
    @Published var backupErrorMessage: String? = nil

    @Published var vendors: [VendorRecord] = []
    @Published var vendorSearchQuery: String = ""
    @Published var newVendorName: String = ""
    @Published var newVendorCategory: String = ""
    @Published var newVendorContact: String = ""

    @Published var expenseServices: [ExpenseServicePreset] = []
    @Published var newServiceName: String = ""
    @Published var newServiceDescription: String = ""
    @Published var newServiceSuggestedVendor: String = ""
    @Published var showSampleVendorsFeedback: Bool = false

    @Published var selectedApartment: Int = 1
    @Published var selectedOwner: String = ""
    @Published var showOwnerSavedFeedback: Bool = false

    @Published var validationError: ValidationError?

    /// Set by `load(from:)`; pages load the shared draft only once.
    private(set) var isLoaded = false

    var totalFlatCount: Int {
        Int(flatCount) ?? 1
    }

    var availableApartments: [Int] {
        if let count = Int(flatCount), count > 0 {
            return Array(1...count)
        }
        return [1]
    }

    var registeredCount: Int {
        availableApartments.filter { flat in
            let name = residents[flat]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return !name.isEmpty
        }.count
    }

    var unassignedCount: Int {
        max(0, availableApartments.count - registeredCount)
    }

    var filteredApartments: [Int] {
        let query = residentSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            return availableApartments
        }
        return availableApartments.filter { flat in
            let flatStr = String(flat)
            let name = (residents[flat] ?? "").lowercased()
            return flatStr.contains(query) || name.contains(query)
        }
    }

    var filteredVendors: [VendorRecord] {
        let query = vendorSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            return vendors
        }
        return vendors.filter { v in
            v.name.lowercased().contains(query) || v.category.lowercased().contains(query) || v.contactInfo.lowercased().contains(query)
        }
    }

    func addVendor() {
        let trimmedName = newVendorName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let trimmedCategory = newVendorCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContact = newVendorContact.trimmingCharacters(in: .whitespacesAndNewlines)
        let vendor = VendorRecord(name: trimmedName, category: trimmedCategory, contactInfo: trimmedContact)
        vendors.append(vendor)
        newVendorName = ""
        newVendorCategory = ""
        newVendorContact = ""
    }

    func deleteVendor(id: UUID) {
        vendors.removeAll { $0.id == id }
    }

    func addExpenseService() {
        let trimmedName = newServiceName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let trimmedDesc = newServiceDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedVendor = newServiceSuggestedVendor.trimmingCharacters(in: .whitespacesAndNewlines)
        let service = ExpenseServicePreset(
            name: trimmedName,
            defaultDescription: trimmedDesc.isEmpty ? trimmedName : trimmedDesc,
            iconName: "briefcase.fill",
            suggestedVendor: trimmedVendor.isEmpty ? nil : trimmedVendor
        )
        expenseServices.append(service)
        newServiceName = ""
        newServiceDescription = ""
        newServiceSuggestedVendor = ""
    }

    func deleteExpenseService(id: UUID) {
        expenseServices.removeAll { $0.id == id }
    }

    func loadSampleVendorsAndServices(for targetLang: AppLanguage) {
        let samples = SampleData.defaults(for: targetLang)
        vendors = samples.defaultVendors
        expenseServices = samples.defaultServices
        showSampleVendorsFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showSampleVendorsFeedback = false
        }
    }

    func bindingForResident(at flat: Int) -> Binding<String> {
        Binding<String>(
            get: { self.residents[flat] ?? "" },
            set: { self.residents[flat] = $0 }
        )
    }

    func bindingForResidentPhone(at flat: Int) -> Binding<String> {
        Binding<String>(
            get: { self.residentPhones[flat] ?? "" },
            set: { self.residentPhones[flat] = $0 }
        )
    }

    func clearResident(for flat: Int) {
        residents[flat] = ""
        residentPhones[flat] = ""
    }

    func fillSampleResidents(for targetLang: AppLanguage) {
        let samples = SampleData.defaults(for: targetLang)
        let maxFlats = max(1, totalFlatCount)
        for (apt, name) in samples.residents {
            if apt <= maxFlats {
                residents[apt] = name
            }
        }
    }

    func clearAllResidents() {
        for apt in availableApartments {
            residents[apt] = ""
            residentPhones[apt] = ""
        }
    }

    func load(from settings: ReceiptSettingsStore) {
        isLoaded = true
        apartmentName = settings.apartmentName
        issuer = settings.issuer
        defaultPayment = settings.defaultPayment
        flatCount = String(settings.flatCount)
        sequenceNumber = String(settings.seqNumber)
        language = settings.language
        theme = settings.theme
        currency = settings.currency
        isLateFeeEnabled = settings.isLateFeeEnabled
        lateFeeMonthlyRate = String(format: "%.1f", settings.lateFeeMonthlyRate)
        lateFeeDueDay = settings.lateFeeDueDay
        lateFeeCountryProfile = settings.lateFeeCountryProfile
        lateFeeGracePeriodDays = settings.lateFeeGracePeriodDays
        lateFeeCustomFootnote = settings.lateFeeCustomFootnote
        vendors = settings.vendors
        expenseServices = settings.expenseServices
        selectedApartment = settings.apartmentNumbers.first ?? 1
        selectedOwner = settings.owner(for: selectedApartment)
        showOwnerSavedFeedback = false
        backupSuccessMessage = nil
        backupErrorMessage = nil

        var loaded: [Int: String] = [:]
        var loadedPhones: [Int: String] = [:]
        for apt in 1...settings.flatCount {
            loaded[apt] = settings.owner(for: apt)
            loadedPhones[apt] = settings.ownerPhone(for: apt)
        }
        residents = loaded
        residentPhones = loadedPhones
    }

    /// The language and its default currency apply at once; a sample (or empty) building switches to that
    /// language's sample data, which is stored right away; the restart notice is shown. Unrelated pending
    /// edits on other tabs stay in the draft for Save & Close or Cancel.
    func selectLanguage(_ lang: AppLanguage, settings: ReceiptSettingsStore) {
        language = lang
        settings.language = lang
        let resolved = L10n(lang).resolvedLanguage
        let newCurrency = AppCurrency.default(for: resolved)
        currency = newCurrency
        settings.currency = newCurrency

        let sampleApts = [
            SampleData.defaults(for: .english).apartmentName,
            SampleData.defaults(for: .turkish).apartmentName,
            SampleData.defaults(for: .romanian).apartmentName
        ]
        if sampleApts.contains(apartmentName) || apartmentName.isEmpty {
            loadSampleDefaults(for: lang)
            commitSampleData(to: settings)
        }
        showRestartAlert = true
    }

    /// Stores the fields `loadSampleDefaults(for:)` filled, with the same normalization as `save(to:)`.
    private func commitSampleData(to settings: ReceiptSettingsStore) {
        let flats = max(1, Int(flatCount) ?? settings.flatCount)
        settings.apartmentName = apartmentName.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.issuer = issuer.trimmingCharacters(in: .whitespacesAndNewlines).localizedCapitalized
        settings.defaultPayment = defaultPayment.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.flatCount = flats
        settings.currency = currency
        settings.vendors = vendors
        settings.expenseServices = expenseServices
        for apt in 1...flats {
            let name = (residents[apt] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            settings.saveOwner(name.localizedCapitalized, apartmentNumber: apt)
        }
        settings.objectWillChange.send()
        NotificationCenter.default.post(name: .settingsDidSave, object: settings)
    }

    /// Resets the stored preferences and mirrors them into the draft. Other draft edits (building,
    /// residents, vendors) are kept, so Save & Close still commits them.
    func resetPreferences(settings: ReceiptSettingsStore) {
        settings.resetPreferencesToDefaults()
        language = settings.language
        theme = settings.theme
        currency = settings.currency
        isLateFeeEnabled = settings.isLateFeeEnabled
        lateFeeMonthlyRate = String(format: "%.1f", settings.lateFeeMonthlyRate)
        lateFeeDueDay = settings.lateFeeDueDay
        lateFeeCountryProfile = settings.lateFeeCountryProfile
        lateFeeGracePeriodDays = settings.lateFeeGracePeriodDays
        lateFeeCustomFootnote = settings.lateFeeCustomFootnote
    }

    func selectCountryProfile(_ profile: LateFeeCountryProfile) {
        lateFeeCountryProfile = profile
        lateFeeMonthlyRate = String(format: "%.1f", profile.defaultRate)
        lateFeeDueDay = profile.defaultDueDay
        lateFeeGracePeriodDays = profile.defaultGraceDays
        lateFeeCustomFootnote = ""
    }

    func loadSampleDefaults(for targetLang: AppLanguage) {
        let samples = SampleData.defaults(for: targetLang)
        apartmentName = samples.apartmentName
        issuer = samples.issuer
        defaultPayment = samples.defaultPayment
        flatCount = String(samples.flatCount)
        currency = samples.currency
        vendors = samples.defaultVendors
        expenseServices = samples.defaultServices

        var loaded: [Int: String] = [:]
        for (apt, name) in samples.residents {
            loaded[apt] = name
        }
        residents = loaded

        selectedOwner = samples.residents[selectedApartment] ?? (samples.residents[1] ?? "")
        showSampleDefaultsFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showSampleDefaultsFeedback = false
        }
    }

    func setQuickFlatCount(_ count: Int) {
        flatCount = String(count)
        let samples = SampleData.defaults(for: language)
        for (apt, name) in samples.residents {
            if apt <= count && (residents[apt] == nil || residents[apt]?.isEmpty == true) {
                residents[apt] = name
            }
        }
    }

    func save(to settings: ReceiptSettingsStore) -> Bool {
        let l10n = L10n(language)
        let trimmedApartmentName = apartmentName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedIssuer = issuer.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDefaultPayment = defaultPayment.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let flats = Int(flatCount), flats > 0 else {
            validationError = ValidationError(message: l10n.errFlatCountInvalid)
            return false
        }
        guard let sequence = Int(sequenceNumber), sequence > 0 else {
            validationError = ValidationError(message: l10n.errSequenceInvalid)
            return false
        }
        guard Double(trimmedDefaultPayment.replacingOccurrences(of: ",", with: ".")) != nil else {
            validationError = ValidationError(message: l10n.errAmountInvalid)
            return false
        }
        guard !trimmedApartmentName.isEmpty, !trimmedIssuer.isEmpty else {
            validationError = ValidationError(message: l10n.errBuildingIssuerRequired)
            return false
        }

        settings.apartmentName = trimmedApartmentName
        settings.issuer = trimmedIssuer.localizedCapitalized
        settings.defaultPayment = trimmedDefaultPayment
        settings.flatCount = flats
        settings.seqNumber = sequence
        settings.language = language
        settings.theme = theme
        settings.currency = currency
        settings.isLateFeeEnabled = isLateFeeEnabled
        let normalizedFeeRate = lateFeeMonthlyRate.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        if let feeRate = Double(normalizedFeeRate), feeRate >= 0 {
            settings.lateFeeMonthlyRate = feeRate
        }
        settings.lateFeeDueDay = max(1, min(31, lateFeeDueDay))
        settings.lateFeeCountryProfile = lateFeeCountryProfile
        settings.lateFeeGracePeriodDays = max(0, min(60, lateFeeGracePeriodDays))
        settings.lateFeeCustomFootnote = lateFeeCustomFootnote.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.vendors = vendors
        settings.expenseServices = expenseServices

        for apt in 1...flats {
            let name = (residents[apt] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            settings.saveOwner(name.localizedCapitalized, apartmentNumber: apt)
            let phone = (residentPhones[apt] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            settings.saveOwnerPhone(phone, apartmentNumber: apt)
        }

        settings.objectWillChange.send()
        NotificationCenter.default.post(name: .settingsDidSave, object: settings)

        return true
    }
}
