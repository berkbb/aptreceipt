import XCTest
@testable import aptreceipt

/// Several buildings on one Mac: the existing data stays the first building, others keep their data apart.
final class BuildingTests: XCTestCase {
    // MARK: - 25. Buildings

    private var folder: URL!

    override func setUpWithError() throws {
        folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: folder)
    }

    private typealias Keys = ReceiptSettingsStore.Keys

    /// A registry on in-memory defaults with the first building's archive in a temporary folder.
    @MainActor
    private func makeRegistry(base: UserDefaults, removed: @escaping (URL) -> Void = { try? FileManager.default.removeItem(at: $0) }) -> (BuildingRegistry, ReceiptSettingsStore, ReceiptArchiveStore) {
        let mainFile = folder.appendingPathComponent("receipts_archive.json")
        let registry = BuildingRegistry(base: base, mainArchiveFile: mainFile, removeArchiveFile: removed)
        let settings = ReceiptSettingsStore(defaults: registry.defaults(for: registry.activeID))
        let archive = ReceiptArchiveStore(fileURL: registry.archiveFile(for: registry.activeID))
        return (registry, settings, archive)
    }

    private func receipt(_ number: Int) -> ReceiptDraft {
        ReceiptDraft(receiver: "R\(number)", issuer: "I", notes: "N", monthYear: "Ekim 2026", apartmentNumber: 1, amount: 100, sequenceNumber: number, createdDate: "20.10.2026", showApartmentNumber: true, kind: .income)
    }

    func testScopedDefaultsPrefixBuildingKeysAndShareAppWideKeys() {
        let base = InMemoryDefaults()
        let scoped = BuildingScopedDefaults(base: base, prefix: "building.x.")
        scoped.set("Yeni Site", forKey: Keys.apartmentName)
        scoped.set("tr", forKey: Keys.language)
        scoped.set(true, forKey: Keys.checkUpdatesAtLaunch)
        XCTAssertEqual(base.string(forKey: "building.x.aptname"), "Yeni Site")
        XCTAssertNil(base.object(forKey: Keys.apartmentName))
        XCTAssertEqual(base.string(forKey: Keys.language), "tr")
        XCTAssertTrue(base.bool(forKey: Keys.checkUpdatesAtLaunch))
        XCTAssertEqual(scoped.string(forKey: Keys.apartmentName), "Yeni Site")
        XCTAssertTrue(BuildingRegistry.defaults(for: BuildingRegistry.mainID, base: base) === base, "the first building reads the base unchanged")
    }

    @MainActor
    func testExistingDataIsTheFirstBuildingUnchanged() throws {
        let base = InMemoryDefaults()
        base.set("Eski Apartman", forKey: Keys.apartmentName)
        base.set("42", forKey: Keys.seqNumber)
        base.set("Ali", forKey: Keys.owner(1))
        let oldArchive = ReceiptArchiveStore(fileURL: folder.appendingPathComponent("receipts_archive.json"))
        oldArchive.add(draft: receipt(41))

        let (registry, settings, archive) = makeRegistry(base: base)
        XCTAssertEqual(registry.buildings, [BuildingRegistry.Building(id: BuildingRegistry.mainID, name: "Eski Apartman")])
        XCTAssertEqual(registry.activeID, BuildingRegistry.mainID)
        XCTAssertEqual(settings.apartmentName, "Eski Apartman")
        XCTAssertEqual(settings.seqNumber, 42)
        XCTAssertEqual(settings.owner(for: 1), "Ali")
        XCTAssertEqual(archive.records.map(\.sequenceNumber), [41])
        XCTAssertEqual(archive.fileURL, folder.appendingPathComponent("receipts_archive.json"))
    }

    @MainActor
    func testAddingABuildingCopiesSharedSettingsAndKeepsDataApart() throws {
        let base = InMemoryDefaults()
        base.set("Eski Apartman", forKey: Keys.apartmentName)
        base.set("Ahmet Yılmaz", forKey: Keys.issuer)
        base.set("42", forKey: Keys.seqNumber)
        base.set("Ali", forKey: Keys.owner(1))
        let (registry, settings, archive) = makeRegistry(base: base)
        archive.add(draft: receipt(41))

        let id = registry.add(name: "  Yeni Site ", settings: settings, archive: archive)
        XCTAssertEqual(registry.activeID, id)
        XCTAssertEqual(registry.buildings.map(\.name), ["Eski Apartman", "Yeni Site"])
        XCTAssertEqual(settings.apartmentName, "Yeni Site")
        XCTAssertEqual(settings.issuer, "Ahmet Yılmaz", "the manager is copied")
        XCTAssertEqual(settings.seqNumber, 1)
        XCTAssertEqual(settings.owner(for: 1), "", "residents start empty")
        XCTAssertTrue(archive.records.isEmpty)
        XCTAssertEqual(archive.fileURL, folder.appendingPathComponent("receipts_archive-\(id).json"))
        XCTAssertEqual(base.string(forKey: Keys.apartmentName), "Eski Apartman", "the first building is untouched")

        settings.seqNumber = 5
        settings.saveOwner("Veli", apartmentNumber: 1)
        archive.add(draft: receipt(5))

        registry.select(BuildingRegistry.mainID, settings: settings, archive: archive)
        XCTAssertEqual(settings.apartmentName, "Eski Apartman")
        XCTAssertEqual(settings.seqNumber, 42)
        XCTAssertEqual(settings.owner(for: 1), "Ali")
        XCTAssertEqual(archive.records.map(\.sequenceNumber), [41])

        registry.select(id, settings: settings, archive: archive)
        XCTAssertEqual(settings.seqNumber, 5)
        XCTAssertEqual(settings.owner(for: 1), "Veli")
        XCTAssertEqual(archive.records.map(\.sequenceNumber), [5])

        // The active building survives a restart.
        let (restarted, restartedSettings, _) = makeRegistry(base: base)
        XCTAssertEqual(restarted.activeID, id)
        XCTAssertEqual(restartedSettings.apartmentName, "Yeni Site")
    }

    @MainActor
    func testLanguageThemeAndLaunchCheckAreShared() {
        let base = InMemoryDefaults()
        let (registry, settings, archive) = makeRegistry(base: base)
        registry.add(name: "B", settings: settings, archive: archive)
        settings.language = .romanian
        settings.theme = .dark
        settings.checkUpdatesAtLaunch = true
        registry.select(BuildingRegistry.mainID, settings: settings, archive: archive)
        let first = ReceiptSettingsStore(defaults: registry.defaults(for: BuildingRegistry.mainID))
        XCTAssertEqual(first.language, .romanian)
        XCTAssertEqual(first.theme, .dark)
        XCTAssertTrue(first.checkUpdatesAtLaunch)
    }

    @MainActor
    func testDeletingABuildingRemovesOnlyItsData() throws {
        let base = InMemoryDefaults()
        base.set("Eski Apartman", forKey: Keys.apartmentName)
        var removedFiles: [URL] = []
        let (registry, settings, archive) = makeRegistry(base: base) { url in
            removedFiles.append(url)
            try? FileManager.default.removeItem(at: url)
        }
        registry.delete(BuildingRegistry.mainID, settings: settings, archive: archive)
        XCTAssertEqual(registry.buildings.count, 1, "the last building cannot be deleted")

        let id = registry.add(name: "Silinecek", settings: settings, archive: archive)
        settings.saveOwner("Veli", apartmentNumber: 1)
        archive.add(draft: receipt(1))
        let file = try XCTUnwrap(archive.fileURL)

        registry.delete(id, settings: settings, archive: archive)
        XCTAssertEqual(registry.activeID, BuildingRegistry.mainID)
        XCTAssertEqual(registry.buildings.map(\.id), [BuildingRegistry.mainID])
        XCTAssertEqual(settings.apartmentName, "Eski Apartman")
        XCTAssertTrue(base.dictionaryRepresentation().keys.allSatisfy { !$0.hasPrefix("building.\(id).") })
        XCTAssertEqual(removedFiles, [file])
        XCTAssertEqual(base.string(forKey: Keys.apartmentName), "Eski Apartman")
    }

    @MainActor
    func testVerifyFindsTheReceiptInAnyBuilding() throws {
        let keys = ReceiptVerificationKeyStore(fileURL: nil)
        let draft = receipt(7)
        let code = ReceiptDocumentView(draft: draft, apartmentName: "B Sitesi", signatureImage: nil, l10n: L10n(.turkish), verificationKeys: keys).qrContent
        let scan = try XCTUnwrap(ScannedReceiptVerification(scannedText: code, keys: keys.allKeys))
        let found = ReceiptArchiveComparison.compare(scan, archives: [(name: "A Apartmanı", records: []), (name: "B Sitesi", records: [ReceiptRecord(draft: draft)])])
        XCTAssertEqual(found.comparison, .matches)
        XCTAssertEqual(found.building, "B Sitesi")
        let missing = ReceiptArchiveComparison.compare(scan, archives: [(name: "A Apartmanı", records: [])])
        XCTAssertEqual(missing.comparison, .missing)
        XCTAssertNil(missing.building)
    }

    @MainActor
    func testVerifyUsesTheActiveBuildingsLiveName() {
        // On a fresh install the name is not stored yet; the settings show the sample name.
        let base = InMemoryDefaults()
        let (registry, settings, archive) = makeRegistry(base: base)
        XCTAssertNil(base.object(forKey: Keys.apartmentName))
        let archives = registry.archives(settings: settings, archive: archive)
        XCTAssertEqual(archives.map(\.name), [settings.apartmentName])
        XCTAssertFalse(settings.apartmentName.isEmpty)
    }
}
