import CryptoKit
import PDFKit
import SwiftUI
import Vision
import XCTest
@testable import aptreceipt

/// The settings window: one shared draft, toolbar tabs, appearance, about, reset and quirk fixes.
final class SettingsTests: XCTestCase {
    // MARK: - 6. Settings Draft Characterization (Arhivar alignment phase 0)
    //
    // These pin today's settings behavior before the settings window is restructured, so the
    // migration cannot silently drop or change an app-specific feature. They use an isolated
    // UserDefaults suite and never touch the real app data.

    @MainActor
    private func makeIsolatedStore() -> ReceiptSettingsStore {
        let store = ReceiptSettingsStore(defaults: InMemoryDefaults())
        store.language = .english
        return store
    }

    @MainActor
    func testSettingsDraftSaveWritesTrimmedClampedValuesToStore() {
        let store = makeIsolatedStore()
        let draft = SettingsViewModel()
        draft.load(from: store)
        draft.language = .english
        draft.apartmentName = "  Test Building  "
        draft.issuer = "jane doe"
        draft.defaultPayment = " 1500,50 "
        draft.flatCount = "4"
        draft.sequenceNumber = "7"
        draft.theme = .dark
        draft.currency = .euro
        draft.isLateFeeEnabled = true
        draft.lateFeeMonthlyRate = "7,5"
        draft.lateFeeDueDay = 40
        draft.lateFeeGracePeriodDays = 99
        draft.lateFeeCustomFootnote = "  Custom note  "
        draft.residents[2] = "  john smith "
        draft.residentPhones[2] = " 0000000000 "
        draft.newVendorName = "Sample Lift Co"
        draft.addVendor()

        XCTAssertTrue(draft.save(to: store))
        XCTAssertNil(draft.validationError)
        XCTAssertEqual(store.apartmentName, "Test Building")
        XCTAssertEqual(store.issuer, "Jane Doe")
        XCTAssertEqual(store.defaultPayment, "1500,50")
        XCTAssertEqual(store.flatCount, 4)
        XCTAssertEqual(store.seqNumber, 7)
        XCTAssertEqual(store.theme, .dark)
        XCTAssertEqual(store.currency, .euro)
        XCTAssertTrue(store.isLateFeeEnabled)
        XCTAssertEqual(store.lateFeeMonthlyRate, 7.5, accuracy: 0.0001)
        XCTAssertEqual(store.lateFeeDueDay, 31)
        XCTAssertEqual(store.lateFeeGracePeriodDays, 60)
        XCTAssertEqual(store.lateFeeCustomFootnote, "Custom note")
        XCTAssertEqual(store.owner(for: 2), "John Smith")
        XCTAssertEqual(store.ownerPhone(for: 2), "0000000000")
        XCTAssertTrue(store.vendors.contains { $0.name == "Sample Lift Co" })

        // A fresh draft loads back exactly what was saved.
        let reloaded = SettingsViewModel()
        reloaded.load(from: store)
        XCTAssertEqual(reloaded.apartmentName, "Test Building")
        XCTAssertEqual(reloaded.flatCount, "4")
        XCTAssertEqual(reloaded.sequenceNumber, "7")
        XCTAssertEqual(reloaded.lateFeeMonthlyRate, "7.5")
        XCTAssertEqual(reloaded.residents[2], "John Smith")
        XCTAssertEqual(reloaded.residents.count, 4)
    }

    @MainActor
    func testSettingsDraftValidationRejectsInvalidInputAndLeavesStoreUntouched() {
        let store = makeIsolatedStore()
        let l10n = L10n(.english)
        let cases: [(String, (SettingsViewModel) -> Void, String)] = [
            ("zero flats", { $0.flatCount = "0" }, l10n.errFlatCountInvalid),
            ("non-numeric flats", { $0.flatCount = "abc" }, l10n.errFlatCountInvalid),
            ("zero sequence", { $0.sequenceNumber = "0" }, l10n.errSequenceInvalid),
            ("non-numeric dues", { $0.defaultPayment = "abc" }, l10n.errAmountInvalid),
            ("blank building", { $0.apartmentName = "   " }, l10n.errBuildingIssuerRequired),
            ("blank issuer", { $0.issuer = "" }, l10n.errBuildingIssuerRequired),
        ]
        let originalName = store.apartmentName
        let originalFlats = store.flatCount

        for (label, breakDraft, expectedMessage) in cases {
            let draft = SettingsViewModel()
            draft.load(from: store)
            draft.language = .english
            breakDraft(draft)
            XCTAssertFalse(draft.save(to: store), label)
            XCTAssertEqual(draft.validationError?.message, expectedMessage, label)
            XCTAssertEqual(store.apartmentName, originalName, label)
            XCTAssertEqual(store.flatCount, originalFlats, label)
        }
    }

    @MainActor
    func testSettingsDraftWithoutSaveLeavesStoreUntouched() {
        let store = makeIsolatedStore()
        let originalName = store.apartmentName
        let originalVendors = store.vendors
        let draft = SettingsViewModel()
        draft.load(from: store)

        draft.apartmentName = "Changed"
        draft.clearAllResidents()
        draft.loadSampleVendorsAndServices(for: .romanian)
        draft.vendors.removeAll()

        // Cancel only closes the window; the store keeps its values.
        XCTAssertEqual(store.apartmentName, originalName)
        XCTAssertEqual(store.vendors, originalVendors)
    }

    @MainActor
    func testSelectCountryProfileResetsEveryLateFeeField() {
        let draft = SettingsViewModel()
        for profile in LateFeeCountryProfile.allCases {
            draft.lateFeeCustomFootnote = "stale"
            draft.lateFeeDueDay = 3
            draft.selectCountryProfile(profile)
            XCTAssertEqual(draft.lateFeeCountryProfile, profile)
            XCTAssertEqual(draft.lateFeeMonthlyRate, String(format: "%.1f", profile.defaultRate))
            XCTAssertEqual(draft.lateFeeDueDay, profile.defaultDueDay)
            XCTAssertEqual(draft.lateFeeGracePeriodDays, profile.defaultGraceDays)
            XCTAssertEqual(draft.lateFeeCustomFootnote, "")
        }
    }

    @MainActor
    func testQuickFlatCountFillsOnlyEmptyResidentSlots() {
        let draft = SettingsViewModel()
        draft.language = .english
        draft.residents = [1: "Kept Resident"]
        draft.setQuickFlatCount(3)

        let samples = SampleData.defaults(for: .english)
        XCTAssertEqual(draft.flatCount, "3")
        XCTAssertEqual(draft.residents[1], "Kept Resident")
        for (flat, name) in samples.residents where flat > 1 && flat <= 3 {
            XCTAssertEqual(draft.residents[flat], name)
        }
        XCTAssertTrue(draft.residents.keys.allSatisfy { $0 <= 3 })
    }

    @MainActor
    func testResidentDirectoryCountsSearchFillAndClear() {
        let draft = SettingsViewModel()
        draft.flatCount = "3"
        draft.residents = [1: "Alice Example", 2: "  ", 3: ""]
        draft.residentPhones = [1: "111"]

        XCTAssertEqual(draft.availableApartments, [1, 2, 3])
        XCTAssertEqual(draft.registeredCount, 1)
        XCTAssertEqual(draft.unassignedCount, 2)
        draft.residentSearchQuery = "alice"
        XCTAssertEqual(draft.filteredApartments, [1])
        draft.residentSearchQuery = "3"
        XCTAssertEqual(draft.filteredApartments, [3])
        draft.residentSearchQuery = ""

        draft.clearResident(for: 1)
        XCTAssertEqual(draft.residents[1], "")
        XCTAssertEqual(draft.residentPhones[1], "")

        draft.fillSampleResidents(for: .english)
        let samples = SampleData.defaults(for: .english)
        for (flat, name) in samples.residents {
            XCTAssertEqual(draft.residents[flat], flat <= 3 ? name : nil)
        }

        draft.clearAllResidents()
        XCTAssertEqual(draft.registeredCount, 0)
        XCTAssertTrue([1, 2, 3].allSatisfy { draft.residentPhones[$0] == "" })
    }

    @MainActor
    func testVendorAndServiceDraftEditing() {
        let draft = SettingsViewModel()

        draft.newVendorName = "   "
        draft.addVendor()
        XCTAssertTrue(draft.vendors.isEmpty)

        draft.newVendorName = "  Lift Service  "
        draft.newVendorCategory = " Elevator "
        draft.newVendorContact = " 000 "
        draft.addVendor()
        XCTAssertEqual(draft.vendors, [VendorRecord(id: draft.vendors[0].id, name: "Lift Service", category: "Elevator", contactInfo: "000")])
        XCTAssertEqual([draft.newVendorName, draft.newVendorCategory, draft.newVendorContact], ["", "", ""])
        draft.vendorSearchQuery = "elev"
        XCTAssertEqual(draft.filteredVendors.count, 1)
        draft.deleteVendor(id: draft.vendors[0].id)
        XCTAssertTrue(draft.vendors.isEmpty)

        draft.newServiceName = " Cleaning "
        draft.addExpenseService()
        let service = draft.expenseServices[0]
        XCTAssertEqual(service.name, "Cleaning")
        XCTAssertEqual(service.defaultDescription, "Cleaning")
        XCTAssertEqual(service.iconName, "briefcase.fill")
        XCTAssertNil(service.suggestedVendor)
        XCTAssertEqual([draft.newServiceName, draft.newServiceDescription, draft.newServiceSuggestedVendor], ["", "", ""])

        draft.newServiceName = "Repairs"
        draft.newServiceDescription = "Monthly repairs"
        draft.newServiceSuggestedVendor = "Lift Service"
        draft.addExpenseService()
        XCTAssertEqual(draft.expenseServices[1].defaultDescription, "Monthly repairs")
        XCTAssertEqual(draft.expenseServices[1].suggestedVendor, "Lift Service")
        draft.deleteExpenseService(id: service.id)
        XCTAssertEqual(draft.expenseServices.map(\.name), ["Repairs"])
    }

    @MainActor
    func testScenarioSamplesFillTheDraftOnly() {
        let store = makeIsolatedStore()
        let originalName = store.apartmentName
        let draft = SettingsViewModel()
        draft.load(from: store)

        draft.loadSampleDefaults(for: .romanian)

        let samples = SampleData.defaults(for: .romanian)
        XCTAssertEqual(draft.apartmentName, samples.apartmentName)
        XCTAssertEqual(draft.issuer, samples.issuer)
        XCTAssertEqual(draft.defaultPayment, samples.defaultPayment)
        XCTAssertEqual(draft.flatCount, String(samples.flatCount))
        XCTAssertEqual(draft.currency, samples.currency)
        // Sample records get fresh UUIDs on every call, so compare their content.
        XCTAssertEqual(draft.vendors.map { [$0.name, $0.category, $0.contactInfo] },
                       samples.defaultVendors.map { [$0.name, $0.category, $0.contactInfo] })
        XCTAssertEqual(draft.expenseServices.map { [$0.name, $0.defaultDescription, $0.iconName, $0.suggestedVendor ?? ""] },
                       samples.defaultServices.map { [$0.name, $0.defaultDescription, $0.iconName, $0.suggestedVendor ?? ""] })
        XCTAssertEqual(draft.residents, samples.residents)
        XCTAssertTrue(draft.showSampleDefaultsFeedback)
        XCTAssertEqual(store.apartmentName, originalName)
    }

    @MainActor
    func testSettingsTabsStayCompleteAndLocalized() {
        // Order, identifiers and icons are part of the feature set (deep links, screenshots).
        XCTAssertEqual(SettingsTab.allCases.map(\.rawValue), ["building", "residents", "vendors", "appearance", "signature", "backup", "about"])
        for tab in SettingsTab.allCases {
            XCTAssertFalse(tab.iconName.isEmpty, tab.rawValue)
            for language in [AppLanguage.english, .turkish, .romanian] {
                let title = tab.title(l10n: L10n(language))
                XCTAssertFalse(title.isEmpty, "\(tab.rawValue) \(language)")
            }
        }
    }

    // MARK: - 7. Settings Toolbar Tabs (Arhivar alignment phase 1)

    func testEverySettingsTabUsesTheWidestWidth() {
        for tab in SettingsTab.allCases {
            XCTAssertEqual(tab.preferredWidth, 760, tab.rawValue)
        }
        XCTAssertGreaterThan(SettingsTab.preferredHeight, 0)
    }

    @MainActor
    func testSettingsToolbarTabsShareOneDraftAndOpenOnTheRequestedTab() {
        let store = makeIsolatedStore()
        for initialTab in SettingsTab.allCases {
            let controller = SettingsTabViewController(settings: store, initialTab: initialTab) {}
            XCTAssertEqual(controller.tabStyle, .toolbar)
            XCTAssertEqual(controller.tabViewItems.compactMap { $0.identifier as? String }, SettingsTab.allCases.map(\.rawValue))
            XCTAssertEqual(controller.selectedSettingsTab, initialTab)
            XCTAssertEqual(controller.draft.selectedTab, initialTab)
            XCTAssertEqual(controller.tabViewItems.map(\.label), SettingsTab.allCases.map { $0.title(l10n: store.l10n) })
        }

        let controller = SettingsTabViewController(settings: store, initialTab: .general) {}
        controller.draft.load(from: store)
        controller.draft.apartmentName = "Edited On Building Tab"
        controller.selectedTabViewItemIndex = SettingsTab.allCases.firstIndex(of: .vendors)!
        XCTAssertEqual(controller.draft.selectedTab, .vendors)
        // Switching tabs keeps the shared draft; nothing reloads it from the store.
        XCTAssertEqual(controller.draft.apartmentName, "Edited On Building Tab")
        XCTAssertTrue(controller.draft.isLoaded)
    }

    // MARK: - 8. Appearance Tab (Arhivar alignment phase 2)

    @MainActor
    func testLanguageSelectionOnSampleBuildingStoresSamplesButNotOtherDraftEdits() {
        let store = makeIsolatedStore()
        let draft = SettingsViewModel()
        draft.load(from: store)
        draft.loadSampleDefaults(for: .english)
        draft.sequenceNumber = "9"
        let originalSequence = store.seqNumber

        draft.selectLanguage(.romanian, settings: store)

        let samples = SampleData.defaults(for: .romanian)
        XCTAssertEqual(store.language, .romanian)
        XCTAssertEqual(store.currency, AppCurrency.default(for: .romanian))
        XCTAssertEqual(draft.currency, AppCurrency.default(for: .romanian))
        XCTAssertEqual(store.apartmentName, samples.apartmentName)
        XCTAssertEqual(store.issuer, samples.issuer)
        XCTAssertEqual(store.flatCount, samples.flatCount)
        XCTAssertEqual(store.vendors.map(\.name), samples.defaultVendors.map(\.name))
        for (flat, name) in samples.residents {
            XCTAssertEqual(store.owner(for: flat), name.localizedCapitalized)
        }
        // A receipt number typed on another tab stays a pending draft edit.
        XCTAssertEqual(store.seqNumber, originalSequence)
        XCTAssertEqual(draft.sequenceNumber, "9")
        XCTAssertTrue(draft.showRestartAlert)
    }

    @MainActor
    func testLanguageSelectionOnCustomBuildingKeepsDraftUnsaved() {
        let store = makeIsolatedStore()
        let draft = SettingsViewModel()
        draft.load(from: store)
        draft.apartmentName = "Custom Building"
        draft.sequenceNumber = "9"
        let originalSequence = store.seqNumber
        let originalName = store.apartmentName

        draft.selectLanguage(.turkish, settings: store)

        XCTAssertEqual(store.language, .turkish)
        XCTAssertEqual(store.currency, AppCurrency.default(for: .turkish))
        XCTAssertEqual(draft.apartmentName, "Custom Building")
        XCTAssertEqual(store.apartmentName, originalName)
        XCTAssertEqual(store.seqNumber, originalSequence)
        XCTAssertTrue(draft.showRestartAlert)
    }

    // MARK: - 9. About Tab: Updates and Reset (Arhivar alignment phase 3)

    @MainActor
    func testLaunchUpdateCheckIsOptInAndPersists() {
        let defaults = InMemoryDefaults()
        let store = ReceiptSettingsStore(defaults: defaults)
        XCTAssertFalse(store.checkUpdatesAtLaunch)

        store.checkUpdatesAtLaunch = true
        XCTAssertTrue(ReceiptSettingsStore(defaults: defaults).checkUpdatesAtLaunch)
    }

    @MainActor
    func testPreferenceResetRestoresPreferencesAndKeepsAllData() {
        let defaults = InMemoryDefaults()
        let store = ReceiptSettingsStore(defaults: defaults)
        store.apartmentName = "Kept Building"
        store.issuer = "Kept Manager"
        store.defaultPayment = "1234"
        store.flatCount = 5
        store.seqNumber = 42
        store.saveOwner("Kept Resident", apartmentNumber: 2)
        store.saveOwnerPhone("0000", apartmentNumber: 2)
        store.vendors = [VendorRecord(name: "Kept Vendor")]
        store.expenseServices = [ExpenseServicePreset(name: "Kept Service", defaultDescription: "Kept")]
        store.logoData = Data([1, 2, 3])
        store.signatureData = Data([4, 5, 6])

        store.language = .turkish
        store.theme = .dark
        store.currency = .euro
        store.isLateFeeEnabled = true
        store.lateFeeCountryProfile = .romania
        store.lateFeeMonthlyRate = 9
        store.lateFeeDueDay = 3
        store.lateFeeGracePeriodDays = 10
        store.lateFeeCustomFootnote = "Custom"
        store.checkUpdatesAtLaunch = true
        store.setLateFeeCountryProfile(.turkey)

        store.resetPreferencesToDefaults()

        let defaultProfile = LateFeeCountryProfile.default(for: ReceiptSettingsStore.Defaults.language)
        XCTAssertEqual(store.language, ReceiptSettingsStore.Defaults.language)
        XCTAssertEqual(store.theme, ReceiptSettingsStore.Defaults.theme)
        XCTAssertEqual(store.currency, AppCurrency.default(for: ReceiptSettingsStore.Defaults.language))
        XCTAssertFalse(store.isLateFeeEnabled)
        XCTAssertEqual(store.lateFeeCountryProfile, defaultProfile)
        XCTAssertEqual(store.lateFeeMonthlyRate, ReceiptSettingsStore.Defaults.lateFeeMonthlyRate)
        XCTAssertEqual(store.lateFeeDueDay, ReceiptSettingsStore.Defaults.lateFeeDueDay)
        XCTAssertEqual(store.lateFeeGracePeriodDays, defaultProfile.defaultGraceDays)
        XCTAssertEqual(store.lateFeeCustomFootnote, "")
        XCTAssertFalse(store.checkUpdatesAtLaunch)
        XCTAssertTrue(LateFeeCountryProfile.allCases.allSatisfy { defaults.object(forKey: "late_fee_rate_\($0.rawValue)") == nil })

        // Data survives, also after reloading from the backing store.
        for reloaded in [store, ReceiptSettingsStore(defaults: defaults)] {
            XCTAssertEqual(reloaded.apartmentName, "Kept Building")
            XCTAssertEqual(reloaded.issuer, "Kept Manager")
            XCTAssertEqual(reloaded.defaultPayment, "1234")
            XCTAssertEqual(reloaded.flatCount, 5)
            XCTAssertEqual(reloaded.seqNumber, 42)
            XCTAssertEqual(reloaded.owner(for: 2), "Kept Resident")
            XCTAssertEqual(reloaded.ownerPhone(for: 2), "0000")
            XCTAssertEqual(reloaded.vendors.map(\.name), ["Kept Vendor"])
            XCTAssertEqual(reloaded.expenseServices.map(\.name), ["Kept Service"])
            XCTAssertEqual(reloaded.logoData, Data([1, 2, 3]))
            XCTAssertEqual(reloaded.signatureData, Data([4, 5, 6]))
        }
    }

    @MainActor
    func testPreferenceResetMirrorsIntoDraftAndKeepsOtherDraftEdits() {
        let store = makeIsolatedStore()
        store.theme = .dark
        store.isLateFeeEnabled = true
        let draft = SettingsViewModel()
        draft.load(from: store)
        draft.apartmentName = "Unsaved Draft Name"
        draft.lateFeeCustomFootnote = "Unsaved footnote"

        draft.resetPreferences(settings: store)

        XCTAssertEqual(draft.theme, store.theme)
        XCTAssertEqual(draft.language, store.language)
        XCTAssertEqual(draft.currency, store.currency)
        XCTAssertFalse(draft.isLateFeeEnabled)
        XCTAssertEqual(draft.lateFeeMonthlyRate, String(format: "%.1f", store.lateFeeMonthlyRate))
        XCTAssertEqual(draft.lateFeeCustomFootnote, "")
        XCTAssertEqual(draft.apartmentName, "Unsaved Draft Name")
        XCTAssertNotEqual(store.apartmentName, "Unsaved Draft Name")
    }

    // MARK: - 10. Settings Quirk Fixes

    func testStatutoryRateLabelHasNoRateInsideItInEveryLanguage() {
        for language in [AppLanguage.english, .turkish, .romanian] {
            let label = L10n(language).statutoryRateLabel
            XCTAssertFalse(label.isEmpty)
            XCTAssertFalse(label.contains("%"), "\(language): \(label)")
            XCTAssertFalse(label.contains(where: \.isNumber), "\(language): \(label)")
        }
        XCTAssertNotEqual(L10n(.turkish).clearResidentButton, L10n(.turkish).clearAllResidentsButton)
    }

    @MainActor
    func testSwitchingSettingsTabsKeepsWindowSizeAndPosition() async throws {
        let store = makeIsolatedStore()
        SettingsWindowManager.shared.show(settings: store, tab: .general)
        defer { SettingsWindowManager.shared.close() }
        let window = try XCTUnwrap(NSApp.windows.first { $0.contentViewController is SettingsTabViewController })
        let controller = try XCTUnwrap(window.contentViewController as? SettingsTabViewController)
        try await Task.sleep(for: .milliseconds(400))
        let topLeft = NSPoint(x: window.frame.minX, y: window.frame.maxY)

        for tab in [SettingsTab.residents, .vendors, .appearance, .residents, .general, .about] {
            controller.selectedTabViewItemIndex = SettingsTab.allCases.firstIndex(of: tab)!
            try await Task.sleep(for: .milliseconds(600))
            // The top-left corner never moves (it used to drift 100 pt per switch).
            XCTAssertEqual(window.frame.minX, topLeft.x, accuracy: 0.5, tab.rawValue)
            XCTAssertEqual(window.frame.maxY, topLeft.y, accuracy: 0.5, tab.rawValue)
            // One width for every tab, so nothing is clipped and the window never resizes.
            XCTAssertEqual(window.contentLayoutRect.width, SettingsTab.preferredWidth, accuracy: 0.5, tab.rawValue)
        }
    }
}
