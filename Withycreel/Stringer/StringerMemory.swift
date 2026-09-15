import Foundation

/// Role: Stringer. In-memory seam for previews and tests. Never a UserDefaults path.
actor StringerMemory: StringerStoring {
    private var latest: CreelDocument
    private var warning: CreelWarning?
    private let directory: URL
    private let fileManager: FileManager

    init(
        document: CreelDocument,
        warning: CreelWarning? = nil,
        fileManager: FileManager = .default
    ) {
        self.latest = document
        self.warning = warning
        self.fileManager = fileManager
        self.directory = fileManager.temporaryDirectory.appendingPathComponent(
            "WithycreelMemory-\(UUID().uuidString)",
            isDirectory: true
        )
    }

    func load() async -> (document: CreelDocument, warning: CreelWarning?) {
        (latest, warning)
    }

    func snapshot() async -> CreelDocument {
        latest
    }

    func keep(
        _ clip: OpenClip,
        on day: CensusDay,
        fishID: UUID,
        markID: UUID
    ) async throws -> (CreelDocument, CreelNotice?) {
        let filing = try latest.keep(clip, on: day, fishID: fishID, markID: markID)
        latest = filing.0
        return (latest, filing.1)
    }

    func release(
        _ clip: OpenClip,
        on day: CensusDay,
        fishID: UUID
    ) async throws -> (CreelDocument, Release) {
        let filing = try latest.release(clip, on: day, fishID: fishID)
        latest = filing.0
        return (latest, filing.1)
    }

    func peel(on day: CensusDay) async throws -> CreelDocument {
        latest = try latest.peel(on: day)
        return latest
    }

    func setOpenClip(_ clip: OpenClip) async throws -> CreelDocument {
        latest = try latest.settingOpenClip(clip)
        return latest
    }

    func setYard(_ yard: CreelYard) async -> CreelDocument {
        latest = latest.settingYard(yard)
        return latest
    }

    func reviseLimit(_ limit: SpeciesLimit) async throws -> CreelDocument {
        latest = try latest.revising(limit)
        return latest
    }

    func setOnboardingComplete(_ flag: Bool) async -> CreelDocument {
        if flag {
            latest = latest.completingOnboarding()
        } else {
            latest.onboardingComplete = false
        }
        return latest
    }

    func flush() async throws {}

    func resetAllData() async throws {
        latest = .empty
        warning = nil
    }

    func seedDemoIfNeeded(now: Date, calendar: Calendar) async throws -> CreelDocument? {
        _ = now
        _ = calendar
        return nil
    }

    func exportCSV() async throws -> URL {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("creel-census.csv")
        try CreelCSV.writeAtomically(CreelCSV.sheet(from: latest), to: url, fileManager: fileManager)
        return url
    }
}
