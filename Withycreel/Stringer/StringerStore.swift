import Foundation

/// Role: Stringer. The only persistence seam. Views never touch UserDefaults or files.
protocol StringerStoring: Sendable {
    func load() async -> (document: CreelDocument, warning: CreelWarning?)
    func snapshot() async -> CreelDocument
    func keep(_ clip: OpenClip, on day: CensusDay, fishID: UUID, markID: UUID) async throws -> (CreelDocument, CreelNotice?)
    func release(_ clip: OpenClip, on day: CensusDay, fishID: UUID) async throws -> (CreelDocument, Release)
    func peel(on day: CensusDay) async throws -> CreelDocument
    func setOpenClip(_ clip: OpenClip) async throws -> CreelDocument
    func setYard(_ yard: CreelYard) async -> CreelDocument
    func reviseLimit(_ limit: SpeciesLimit) async throws -> CreelDocument
    func setOnboardingComplete(_ flag: Bool) async -> CreelDocument
    func flush() async throws
    func resetAllData() async throws
    func seedDemoIfNeeded(now: Date, calendar: Calendar) async throws -> CreelDocument?
    func exportCSV() async throws -> URL
}

/// Role: Stringer. Memory is the source of truth. UserDefaults wyc.stringer.v1 plus an Application Support file are projections.
actor StringerStore: StringerStoring {
    private let directory: URL
    private let defaultsSuiteName: String?
    private let fileManager: FileManager
    private let writeDelayNanoseconds: UInt64

    private var latest: CreelDocument = .empty
    private var dirty = false
    private var writeTask: Task<Void, Never>?
    private(set) var warning: CreelWarning?
    private(set) var lastWriteError: String?
    private(set) var lastNotice: CreelNotice?

    init(
        directory: URL,
        defaultsSuiteName: String? = nil,
        fileManager: FileManager = .default,
        writeDelayNanoseconds: UInt64 = 300_000_000
    ) {
        self.directory = directory
        self.defaultsSuiteName = defaultsSuiteName
        self.fileManager = fileManager
        self.writeDelayNanoseconds = writeDelayNanoseconds
    }

    static func applicationSupportDirectory(fileManager: FileManager = .default) throws -> URL {
        let root = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return root.appendingPathComponent("Withycreel", isDirectory: true)
    }

    func load() async -> (document: CreelDocument, warning: CreelWarning?) {
        warning = nil
        lastNotice = nil
        latest = .empty
        dirty = false
        let defaults = preferenceDefaults()
        if let data = defaults.data(forKey: CreelKey.snapshot), let document = decode(data) {
            latest = document
            return (latest, nil)
        }
        if let document = decodeFile(fileURL) {
            latest = document
            return (latest, nil)
        }
        if let data = defaults.data(forKey: CreelKey.backup), let document = decode(data) {
            latest = document
            warning = .recoveredFromBackup
            return (latest, warning)
        }
        if let document = decodeFile(backupURL) {
            latest = document
            warning = .recoveredFromBackup
            return (latest, warning)
        }
        let hadPayload = defaults.data(forKey: CreelKey.snapshot) != nil
            || fileManager.fileExists(atPath: fileURL.path)
        if hadPayload {
            warning = .startedEmpty
        }
        return (latest, warning)
    }

    func snapshot() async -> CreelDocument {
        latest
    }

    func keep(
        _ clip: OpenClip,
        on day: CensusDay,
        fishID: UUID = UUID(),
        markID: UUID = UUID()
    ) async throws -> (CreelDocument, CreelNotice?) {
        try Task.checkCancellation()
        let filing = try latest.keep(clip, on: day, fishID: fishID, markID: markID)
        latest = filing.0
        lastNotice = filing.1
        try persistCommitted()
        return (latest, filing.1)
    }

    func release(
        _ clip: OpenClip,
        on day: CensusDay,
        fishID: UUID = UUID()
    ) async throws -> (CreelDocument, Release) {
        try Task.checkCancellation()
        let filing = try latest.release(clip, on: day, fishID: fishID)
        latest = filing.0
        lastNotice = nil
        try persistCommitted()
        return (latest, filing.1)
    }

    func peel(on day: CensusDay) async throws -> CreelDocument {
        try Task.checkCancellation()
        latest = try latest.peel(on: day)
        lastNotice = nil
        try persistCommitted()
        return latest
    }

    func setOpenClip(_ clip: OpenClip) async throws -> CreelDocument {
        latest = try latest.settingOpenClip(clip)
        dirty = true
        scheduleFlush()
        return latest
    }

    func setYard(_ yard: CreelYard) async -> CreelDocument {
        latest = latest.settingYard(yard)
        dirty = true
        scheduleFlush()
        return latest
    }

    func reviseLimit(_ limit: SpeciesLimit) async throws -> CreelDocument {
        latest = try latest.revising(limit)
        dirty = true
        scheduleFlush()
        return latest
    }

    func setOnboardingComplete(_ flag: Bool) async -> CreelDocument {
        if flag {
            latest = latest.completingOnboarding()
        } else {
            latest.onboardingComplete = false
        }
        dirty = true
        scheduleFlush()
        return latest
    }

    func flush() async throws {
        writeTask?.cancel()
        writeTask = nil
        if dirty {
            try persistCommitted()
        }
    }

    func resetAllData() async throws {
        writeTask?.cancel()
        writeTask = nil
        latest = .empty
        dirty = false
        warning = nil
        lastNotice = nil
        lastWriteError = nil
        let defaults = preferenceDefaults()
        defaults.removeObject(forKey: CreelKey.snapshot)
        defaults.removeObject(forKey: CreelKey.backup)
        if fileManager.fileExists(atPath: directory.path) {
            try fileManager.removeItem(at: directory)
        }
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func seedDemoIfNeeded(now: Date = Date(), calendar: Calendar = .current) async throws -> CreelDocument? {
        #if targetEnvironment(simulator)
        let defaults = preferenceDefaults()
        guard defaults.object(forKey: CreelKey.demo) == nil else { return nil }
        latest = try CreelSeed.document(now: now, calendar: calendar)
        lastNotice = nil
        try persistCommitted()
        defaults.set(true, forKey: CreelKey.demo)
        return latest
        #else
        _ = now
        _ = calendar
        return nil
        #endif
    }

    func exportCSV() async throws -> URL {
        try Task.checkCancellation()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("creel-census.csv")
        try CreelCSV.writeAtomically(CreelCSV.sheet(from: latest), to: url, fileManager: fileManager)
        return url
    }

    /// File IO stays on this actor, which is not MainActor — the main thread never waits on disk.
    private func persistCommitted() throws {
        let ledger = CreelCodec.committed(from: latest)
        let data = try CreelCodec.encode(ledger)
        let defaults = preferenceDefaults()
        if let previous = defaults.data(forKey: CreelKey.snapshot) {
            defaults.set(previous, forKey: CreelKey.backup)
        }
        defaults.set(data, forKey: CreelKey.snapshot)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        if fileManager.fileExists(atPath: fileURL.path) {
            if fileManager.fileExists(atPath: backupURL.path) {
                try? fileManager.removeItem(at: backupURL)
            }
            try? fileManager.copyItem(at: fileURL, to: backupURL)
        }
        try data.write(to: fileURL, options: .atomic)
        dirty = false
        lastWriteError = nil
    }

    private func scheduleFlush() {
        writeTask?.cancel()
        let delay = writeDelayNanoseconds
        writeTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }
            await self?.flushIfNeeded()
        }
    }

    private func flushIfNeeded() async {
        writeTask = nil
        do {
            if dirty {
                try persistCommitted()
            }
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    private func decode(_ data: Data) -> CreelDocument? {
        guard let ledger = try? CreelCodec.decode(data) else { return nil }
        return ledger.document
    }

    private func decodeFile(_ url: URL) -> CreelDocument? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return decode(data)
    }

    private var fileURL: URL {
        directory.appendingPathComponent("creel.json")
    }

    private var backupURL: URL {
        directory.appendingPathComponent("creel.json.backup")
    }

    private func preferenceDefaults() -> UserDefaults {
        if let defaultsSuiteName {
            return UserDefaults(suiteName: defaultsSuiteName) ?? .standard
        }
        return .standard
    }
}
