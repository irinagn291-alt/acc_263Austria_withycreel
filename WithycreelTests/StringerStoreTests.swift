import XCTest
@testable import Withycreel

final class StringerStoreTests: XCTestCase {
    private var directory = FileManager.default.temporaryDirectory
    private var suiteName = ""
    private var defaults = UserDefaults.standard
    private var calendar = CreelTestDates.calendar
    private var today = CensusDay(rawValue: 2026_06_10)

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        suiteName = "wyc.test.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        calendar = CreelTestDates.calendar
        today = CensusDay.from(CreelTestDates.day(2026, 6, 10), calendar: calendar)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
        if !suiteName.isEmpty {
            defaults.removePersistentDomain(forName: suiteName)
        }
    }

    func test_roundTrip_reloadPreservesKeepAndSIValues() async throws {
        let store = makeStore()
        _ = await store.load()
        _ = await store.setOnboardingComplete(true)
        try await store.flush()
        let filing = try await store.keep(.perch(length: 31.25, weight: 0.64), on: today)
        XCTAssertNil(filing.1)
        XCTAssertEqual(filing.0.fish(on: today).count, 1)

        let relaunched = makeStore()
        let loaded = await relaunched.load()
        XCTAssertNil(loaded.warning)
        XCTAssertTrue(loaded.document.onboardingComplete)
        let fish = try XCTUnwrap(loaded.document.fish(on: today).first)
        XCTAssertEqual(fish.lengthCentimetres, 31.25, accuracy: 0.000_000_1)
        XCTAssertEqual(fish.weightKilograms, 0.64, accuracy: 0.000_000_1)
        XCTAssertNotNil(fish.keepMark)
        XCTAssertEqual(
            CreelCensus.remainingDaily(species: CensusStock.perchID, day: today, in: loaded.document),
            CensusStock.perch.dailyBag - 1
        )
        let encoded = try CreelCodec.encode(CreelCodec.committed(from: loaded.document))
        let text = String(data: encoded, encoding: .utf8) ?? ""
        XCTAssertFalse(text.contains("remaining"))
    }

    func test_corruptSnapshotFallsBackToBackup() async throws {
        let store = makeStore()
        _ = await store.load()
        _ = try await store.keep(.perch(), on: today)
        if let good = defaults.data(forKey: CreelKey.snapshot) {
            defaults.set(good, forKey: CreelKey.backup)
        }
        let file = directory.appendingPathComponent("creel.json")
        let backup = directory.appendingPathComponent("creel.json.backup")
        if FileManager.default.fileExists(atPath: file.path) {
            try? FileManager.default.removeItem(at: backup)
            try FileManager.default.copyItem(at: file, to: backup)
        }
        defaults.set(Data("{not-json".utf8), forKey: CreelKey.snapshot)
        try Data("nope".utf8).write(to: file, options: .atomic)

        let relaunched = makeStore()
        let loaded = await relaunched.load()
        XCTAssertEqual(loaded.warning, .recoveredFromBackup)
        XCTAssertEqual(loaded.document.fish(on: today).count, 1)
    }

    func test_corruptSnapshotWithoutBackupStartsEmpty() async throws {
        defaults.set(Data("nope".utf8), forKey: CreelKey.snapshot)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("nope".utf8).write(to: directory.appendingPathComponent("creel.json"), options: .atomic)
        let loaded = await makeStore().load()
        XCTAssertEqual(loaded.warning, .startedEmpty)
        XCTAssertTrue(loaded.document.fish(on: today).isEmpty)
    }

    func test_resetAllData_clearsSnapshot() async throws {
        let store = makeStore()
        _ = await store.load()
        _ = try await store.keep(.perch(), on: today)
        try await store.resetAllData()
        let loaded = await store.load()
        XCTAssertTrue(loaded.document.fish(on: today).isEmpty)
        XCTAssertNil(defaults.data(forKey: CreelKey.snapshot))
        XCTAssertNil(defaults.data(forKey: CreelKey.backup))
    }

    func test_codecSwitchesOnSchemaVersion() throws {
        let data = try CreelCodec.encode(CreelCodec.committed(from: .empty))
        let decoded = try CreelCodec.decode(data)
        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.document.schemaVersion, 1)
        XCTAssertEqual(decoded.document.limits.count, 4)

        let future = Data("{\"schemaVersion\":99}".utf8)
        XCTAssertThrowsError(try CreelCodec.decode(future)) { error in
            XCTAssertEqual(error as? CreelCodec.Failure, .unsupportedSchema(99))
        }
        XCTAssertThrowsError(try CreelCodec.decode(Data("[]".utf8))) { error in
            XCTAssertEqual(error as? CreelCodec.Failure, .corrupt)
        }
    }

    func test_csvExportReadsTheSameDocument() async throws {
        let store = makeStore()
        _ = await store.load()
        _ = try await store.keep(.perch(length: 30, weight: 0.5), on: today)
        _ = try await store.release(
            OpenClip(speciesID: CensusStock.breamID, lengthCentimetres: 34, weightKilograms: 1.1),
            on: today
        )
        let url = try await store.exportCSV()
        let sheet = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(sheet.contains("day,species,role,length_cm,weight_kg"))
        XCTAssertTrue(sheet.contains("kept"))
        XCTAssertTrue(sheet.contains("released"))
        XCTAssertTrue(sheet.contains("Perch"))
        XCTAssertTrue(sheet.contains("30"))
    }

    #if targetEnvironment(simulator)
    func test_simulatorSeedWritesSeveralFish_keepEnabled_notOverFirst() async throws {
        let store = makeStore()
        _ = await store.load()
        let now = CreelTestDates.day(2026, 6, 10)
        let first = try await store.seedDemoIfNeeded(now: now, calendar: calendar)
        let second = try await store.seedDemoIfNeeded(now: now, calendar: calendar)
        XCTAssertNil(second)
        let seeded = try XCTUnwrap(first)
        XCTAssertTrue(seeded.onboardingComplete)
        XCTAssertTrue(seeded.keepIsEnabled)
        XCTAssertGreaterThanOrEqual(seeded.fish(on: today).count, 4)
        if case .open = seeded.clips(on: today).first {
            // open clip first — never seed Over as the first frame
        } else {
            XCTFail("seeded clips must start Open")
        }
        XCTAssertFalse(seeded.stringer(on: today).hangsOver)
        XCTAssertGreaterThan(
            CreelCensus.remainingDaily(species: CensusStock.perchID, day: today, in: seeded),
            0
        )
        XCTAssertTrue(defaults.bool(forKey: CreelKey.demo))
    }
    #endif

    private func makeStore() -> StringerStore {
        StringerStore(directory: directory, defaultsSuiteName: suiteName, writeDelayNanoseconds: 0)
    }
}
