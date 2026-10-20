import AppKit

// MARK: - Building-Scoped Defaults

/// A building's view of the app's defaults: its own keys get the building's prefix, app-wide keys (language,
/// theme, launch update check, the building list) are shared by every building.
final class BuildingScopedDefaults: UserDefaults {
    private let base: UserDefaults
    let prefix: String

    /// Keys every building shares.
    static let appWideKeys: Set<String> = [
        ReceiptSettingsStore.Keys.language,
        ReceiptSettingsStore.Keys.theme,
        ReceiptSettingsStore.Keys.checkUpdatesAtLaunch,
        "AppleLanguages",
        BuildingRegistry.listKey,
        BuildingRegistry.activeKey,
    ]

    init(base: UserDefaults, prefix: String) {
        self.base = base
        self.prefix = prefix
        super.init(suiteName: nil)!
    }

    private func scoped(_ key: String) -> String {
        Self.appWideKeys.contains(key) ? key : prefix + key
    }

    override func object(forKey defaultName: String) -> Any? { base.object(forKey: scoped(defaultName)) }
    override func set(_ value: Any?, forKey defaultName: String) { base.set(value, forKey: scoped(defaultName)) }
    override func set(_ value: Bool, forKey defaultName: String) { base.set(value, forKey: scoped(defaultName)) }
    override func set(_ value: Int, forKey defaultName: String) { base.set(value, forKey: scoped(defaultName)) }
    override func set(_ value: Double, forKey defaultName: String) { base.set(value, forKey: scoped(defaultName)) }
    override func set(_ value: Float, forKey defaultName: String) { base.set(value, forKey: scoped(defaultName)) }
    override func set(_ url: URL?, forKey defaultName: String) { base.set(url, forKey: scoped(defaultName)) }
    override func removeObject(forKey defaultName: String) { base.removeObject(forKey: scoped(defaultName)) }
    override func string(forKey defaultName: String) -> String? { base.string(forKey: scoped(defaultName)) }
    override func data(forKey defaultName: String) -> Data? { base.data(forKey: scoped(defaultName)) }
    override func array(forKey defaultName: String) -> [Any]? { base.array(forKey: scoped(defaultName)) }
    override func stringArray(forKey defaultName: String) -> [String]? { base.stringArray(forKey: scoped(defaultName)) }
    override func dictionary(forKey defaultName: String) -> [String: Any]? { base.dictionary(forKey: scoped(defaultName)) }
    override func url(forKey defaultName: String) -> URL? { base.url(forKey: scoped(defaultName)) }
    override func bool(forKey defaultName: String) -> Bool { base.bool(forKey: scoped(defaultName)) }
    override func integer(forKey defaultName: String) -> Int { base.integer(forKey: scoped(defaultName)) }
    override func double(forKey defaultName: String) -> Double { base.double(forKey: scoped(defaultName)) }
    override func float(forKey defaultName: String) -> Float { base.float(forKey: scoped(defaultName)) }
}

// MARK: - Building Registry

/// The buildings this Mac manages and the active one. The first building ("main") keeps the original keys
/// and archive file, so existing data becomes the first building without moving anything; later buildings
/// use prefixed keys (`BuildingScopedDefaults`) and their own archive file.
@MainActor
final class BuildingRegistry: ObservableObject {
    /// The app's buildings. During a screenshot run they live in memory only (`ScreenshotMode`).
    static let shared = BuildingRegistry(base: ScreenshotMode.baseDefaults, mainArchiveFile: ScreenshotMode.archiveFileURL())

    nonisolated static let mainID = "main"
    nonisolated static let listKey = "building_ids"
    nonisolated static let activeKey = "active_building_id"

    struct Building: Identifiable, Equatable {
        let id: String
        var name: String
    }

    @Published private(set) var buildings: [Building] = []
    @Published private(set) var activeID: String

    private let base: UserDefaults
    /// The first building's archive file; `nil` keeps every archive in memory (tests, screenshot runs).
    private let mainArchiveFile: URL?
    /// How a deleted building's archive file is removed; the app moves it to the Trash.
    private let removeArchiveFile: (URL) -> Void

    init(base: UserDefaults, mainArchiveFile: URL?, removeArchiveFile: @escaping (URL) -> Void = { url in
        try? FileManager.default.trashItem(at: url, resultingItemURL: nil)
    }) {
        self.base = base
        self.mainArchiveFile = mainArchiveFile
        self.removeArchiveFile = removeArchiveFile
        activeID = Self.storedActiveID(in: base)
        refresh()
    }

    // MARK: Storage locations

    nonisolated static func storedIDs(in base: UserDefaults) -> [String] {
        let ids = base.stringArray(forKey: listKey) ?? []
        return ids.isEmpty ? [mainID] : ids
    }

    nonisolated static func storedActiveID(in base: UserDefaults) -> String {
        let ids = storedIDs(in: base)
        let active = base.string(forKey: activeKey) ?? mainID
        return ids.contains(active) ? active : ids[0]
    }

    /// The first building reads the base defaults unchanged; any other building gets its own key prefix.
    nonisolated static func defaults(for id: String, base: UserDefaults) -> UserDefaults {
        id == mainID ? base : BuildingScopedDefaults(base: base, prefix: "building.\(id).")
    }

    /// The building's archive file next to the first building's one, or `nil` when archives are in memory.
    nonisolated static func archiveFile(for id: String, mainArchiveFile: URL?) -> URL? {
        guard let mainArchiveFile else { return nil }
        guard id != mainID else { return mainArchiveFile }
        return mainArchiveFile.deletingLastPathComponent().appendingPathComponent("receipts_archive-\(id).json")
    }

    func defaults(for id: String) -> UserDefaults { Self.defaults(for: id, base: base) }

    func archiveFile(for id: String) -> URL? { Self.archiveFile(for: id, mainArchiveFile: mainArchiveFile) }

    // MARK: Buildings

    /// Reloads the list and each building's name.
    func refresh() {
        buildings = Self.storedIDs(in: base).map { id in
            Building(id: id, name: defaults(for: id).string(forKey: ReceiptSettingsStore.Keys.apartmentName) ?? "")
        }
    }

    /// Makes `id` the active building and points the shared settings and archive at it.
    func select(_ id: String, settings: ReceiptSettingsStore? = nil, archive: ReceiptArchiveStore? = nil) {
        guard buildings.contains(where: { $0.id == id }) else { return }
        activeID = id
        base.set(id, forKey: Self.activeKey)
        (settings ?? .shared).switchDefaults(to: defaults(for: id))
        (archive ?? .shared).useFile(archiveFile(for: id))
        refresh()
        NotificationCenter.default.post(name: .settingsDidSave, object: nil)
    }

    /// Adds a building named `name` and makes it active. It starts with the current building's manager,
    /// signature, dues amount, flat count, currency, late-fee settings, vendors and services; residents,
    /// phones, logo and receipts start empty and the receipt number starts at 1.
    @discardableResult
    func add(name: String, settings: ReceiptSettingsStore? = nil, archive: ReceiptArchiveStore? = nil) -> String {
        let settings = settings ?? .shared
        let id = UUID().uuidString.lowercased()
        let target = defaults(for: id)
        let source = settings.defaults
        typealias Keys = ReceiptSettingsStore.Keys
        target.set(name.trimmingCharacters(in: .whitespacesAndNewlines), forKey: Keys.apartmentName)
        target.set("1", forKey: Keys.seqNumber)
        for key in [Keys.issuer, Keys.defaultPayment, Keys.flatCount, Keys.currency, Keys.signature, Keys.vendors,
                    Keys.expenseServices, Keys.isLateFeeEnabled, Keys.lateFeeMonthlyRate, Keys.lateFeeDueDay,
                    Keys.lateFeeCountryProfile, Keys.lateFeeGracePeriodDays, Keys.lateFeeCustomFootnote]
            + LateFeeCountryProfile.allCases.map(Keys.lateFeeRate(for:)) {
            if let value = source.object(forKey: key) { target.set(value, forKey: key) }
        }
        base.set(Self.storedIDs(in: base) + [id], forKey: Self.listKey)
        refresh()
        select(id, settings: settings, archive: archive)
        return id
    }

    /// Deletes a building: its settings, residents and vendors are removed and its archive file is moved
    /// to the Trash. The last building cannot be deleted; deleting the active one switches to the first left.
    func delete(_ id: String, settings: ReceiptSettingsStore? = nil, archive: ReceiptArchiveStore? = nil) {
        var ids = Self.storedIDs(in: base)
        guard ids.count > 1, let index = ids.firstIndex(of: id) else { return }
        ids.remove(at: index)
        base.set(ids, forKey: Self.listKey)
        if activeID == id {
            refresh()
            select(ids[0], settings: settings, archive: archive)
        }
        removeKeys(of: id)
        if let file = archiveFile(for: id), FileManager.default.fileExists(atPath: file.path) {
            removeArchiveFile(file)
        }
        refresh()
    }

    private func removeKeys(of id: String) {
        let keys = Array(base.dictionaryRepresentation().keys)
        if id == Self.mainID {
            typealias Keys = ReceiptSettingsStore.Keys
            let buildingKeys: Set<String> = [Keys.apartmentName, Keys.issuer, Keys.defaultPayment, Keys.flatCount, Keys.seqNumber,
                                             Keys.signature, Keys.logo, Keys.currency, Keys.vendors, Keys.expenseServices,
                                             Keys.isLateFeeEnabled, Keys.lateFeeMonthlyRate, Keys.lateFeeDueDay,
                                             Keys.lateFeeCountryProfile, Keys.lateFeeGracePeriodDays, Keys.lateFeeCustomFootnote]
            for key in keys where buildingKeys.contains(key) || key.hasPrefix("homeowner_") || key.hasPrefix("late_fee_rate_") {
                base.removeObject(forKey: key)
            }
        } else {
            let prefix = "building.\(id)."
            for key in keys where key.hasPrefix(prefix) {
                base.removeObject(forKey: key)
            }
        }
    }

    /// Every building's name and archived receipts, for Verify Receipt. The active building's name and
    /// records come from the live settings and archive (its name may not be stored yet on a fresh install);
    /// the others are read from their defaults and files.
    func archives(settings: ReceiptSettingsStore, archive: ReceiptArchiveStore) -> [(name: String, records: [ReceiptRecord])] {
        buildings.map { building in
            building.id == activeID
                ? (name: settings.apartmentName, records: archive.records)
                : (name: building.name, records: ReceiptArchiveStore(fileURL: archiveFile(for: building.id)).records)
        }
    }
}
