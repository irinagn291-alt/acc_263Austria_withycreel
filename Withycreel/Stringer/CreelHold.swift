import Foundation
import Observation
#if canImport(UIKit)
import UIKit
#endif

/// Role: Stringer. Presentation fold over StringerStoring. Views call keep, release, and peel here.
@MainActor
@Observable
final class CreelHold {
    private(set) var document: CreelDocument
    private(set) var warning: CreelWarning?
    private(set) var fault: String?
    private(set) var notice: CreelNotice?
    private(set) var isHauling = false
    private(set) var isCommitting = false
    private(set) var isSpinning = false
    private(set) var commitTick = 0
    private(set) var csvURL: URL?
    private(set) var dayAnchor: Date

    var tab: StringerTab = .catches

    let store: any StringerStoring
    private let calendar: Calendar
    private let now: @Sendable () -> Date
    private let shouldLoad: Bool
    private var appeared = false
    private var reviewConsumed = false
    private var reviewPane: ReviewPane?
    private var haulToken: UUID?
    private var spinTask: Task<Void, Never>?

    init(
        store: any StringerStoring,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = { Date() },
        document: CreelDocument = .empty,
        warning: CreelWarning? = nil,
        shouldLoad: Bool = true
    ) {
        self.store = store
        self.calendar = calendar
        self.now = now
        self.document = document
        self.warning = warning
        self.shouldLoad = shouldLoad
        self.dayAnchor = calendar.startOfDay(for: now())
    }

    var today: CensusDay {
        CensusDay.from(dayAnchor, calendar: calendar)
    }

    var onboardingComplete: Bool {
        document.onboardingComplete
    }

    var loadFailed: Bool {
        warning == .startedEmpty
    }

    var todayIsEmpty: Bool {
        document.fish(on: today).isEmpty
    }

    var everFiled: Bool {
        document.creels.values.contains { !$0.isEmpty }
    }

    var keepIsEnabled: Bool {
        document.keepIsEnabled
    }

    var canPeel: Bool {
        !document.fish(on: today).isEmpty
    }

    var remainingDaily: Int {
        CreelCensus.remainingDaily(species: document.openClip.speciesID, day: today, in: document)
    }

    var remainingSeason: Int {
        CreelCensus.remainingSeason(
            species: document.openClip.speciesID,
            year: today.seasonYear,
            in: document
        )
    }

    var bagIsFull: Bool {
        remainingDaily == 0 || remainingSeason == 0
    }

    var jobTitle: String {
        "Keep today's stringer"
    }

    var jobLine: String {
        if bagIsFull {
            return "Bag is full. Keep still files; this fish hangs Over."
        }
        return "Tap Keep to file this fish against today's bag."
    }

    /// Twist copy on the open clip. Always named Over — colour is never the only signal.
    var overhangLine: String {
        if bagIsFull || notice == .overhang {
            return "Bag is full. Keep still files as Over."
        }
        return "Keep always files. A full bag hangs Over."
    }

    var monthlyKeptKilograms: Double {
        let month = today.rawValue / 100
        return document.creels.reduce(0) { sum, pair in
            guard pair.key.rawValue / 100 == month else { return sum }
            return sum + pair.value.filter(\.isKept).reduce(0) { $0 + $1.weightKilograms }
        }
    }

    func name(for speciesID: UUID) -> String {
        document.limit(id: speciesID)?.name ?? "—"
    }

    func remainingDaily(for speciesID: UUID) -> Int {
        CreelCensus.remainingDaily(species: speciesID, day: today, in: document)
    }

    func remainingSeason(for speciesID: UUID) -> Int {
        CreelCensus.remainingSeason(species: speciesID, year: today.seasonYear, in: document)
    }

    func dailyKept(for speciesID: UUID) -> Int {
        CreelCensus.dailyKept(species: speciesID, day: today, in: document)
    }

    func seasonKept(for speciesID: UUID) -> Int {
        CreelCensus.seasonKept(species: speciesID, year: today.seasonYear, in: document)
    }

    func appear() async {
        guard shouldLoad else {
            applyReview()
            return
        }
        if appeared {
            applyReview()
            return
        }
        appeared = true
        await haul(seed: true)
        applyReview()
    }

    func retry() async {
        fault = nil
        appeared = false
        await appear()
    }

    func flush() async {
        do {
            try await store.flush()
        } catch {
            fault = Self.saveFailed
        }
    }

    func markDay() {
        dayAnchor = calendar.startOfDay(for: now())
    }

    func keep(_ clip: OpenClip) async {
        await run {
            let filing = try await self.store.keep(
                clip,
                on: self.today,
                fishID: UUID(),
                markID: UUID()
            )
            self.document = filing.0
            self.notice = filing.1
            self.commitTick += 1
        }
    }

    func keepOpen() async {
        await keep(document.openClip)
    }

    func release(_ clip: OpenClip) async {
        await run {
            let filing = try await self.store.release(clip, on: self.today, fishID: UUID())
            self.document = filing.0
            self.notice = nil
            self.commitTick += 1
        }
    }

    func peel() async {
        await run {
            self.document = try await self.store.peel(on: self.today)
            self.notice = nil
            self.commitTick += 1
        }
    }

    func setOpenClip(_ clip: OpenClip) async {
        do {
            document = try await store.setOpenClip(clip)
        } catch let creel as CreelFault {
            fault = Self.copy(creel)
        } catch {
            fault = Self.saveFailed
        }
    }

    func setYard(_ yard: CreelYard) async {
        document = await store.setYard(yard)
    }

    func reviseLimit(_ limit: SpeciesLimit) async {
        await run(haptic: false) {
            self.document = try await self.store.reviseLimit(limit)
        }
    }

    func restoreStockLimits() async {
        await run(haptic: false) {
            for limit in CensusStock.all {
                self.document = try await self.store.reviseLimit(limit)
            }
        }
    }

    func finishOnboarding(yard: CreelYard) async {
        document = await store.setYard(yard)
        document = await store.setOnboardingComplete(true)
        do {
            try await store.flush()
        } catch {
            fault = Self.saveFailed
        }
        applyReview()
    }

    func reopenOnboarding() async {
        document = await store.setOnboardingComplete(false)
    }

    func resetAll() async {
        await run(haptic: false) {
            try await self.store.resetAllData()
            self.document = .empty
            self.warning = nil
            self.notice = nil
            self.csvURL = nil
            self.tab = .catches
        }
    }

    func exportCSV() async {
        await run(haptic: false) {
            self.csvURL = try await self.store.exportCSV()
        }
    }

    func applyReview(arguments: [String] = ProcessInfo.processInfo.arguments) {
        if let pane = StringerLaunch.consume(
            arguments: arguments,
            onboardingComplete: document.onboardingComplete,
            consumed: &reviewConsumed
        ) {
            reviewPane = pane
        }
        if let pane = reviewPane {
            tab = pane.tab
        }
    }

    static func live() -> CreelHold {
        let directory: URL
        do {
            directory = try StringerStore.applicationSupportDirectory()
        } catch {
            directory = FileManager.default.temporaryDirectory.appendingPathComponent(
                "Withycreel",
                isDirectory: true
            )
        }
        return CreelHold(store: StringerStore(directory: directory))
    }

    static func previewPopulated() -> CreelHold {
        let document = (try? CreelSeed.document()) ?? CreelDocument.empty.completingOnboarding()
        return CreelHold(
            store: StringerMemory(document: document),
            document: document,
            shouldLoad: false
        )
    }

    static func previewEmpty() -> CreelHold {
        let document = CreelDocument.empty.completingOnboarding()
        return CreelHold(
            store: StringerMemory(document: document),
            document: document,
            shouldLoad: false
        )
    }

    static func previewError() -> CreelHold {
        let document = CreelDocument.empty.completingOnboarding()
        return CreelHold(
            store: StringerMemory(document: document, warning: .startedEmpty),
            document: document,
            warning: .startedEmpty,
            shouldLoad: false
        )
    }

    private func haul(seed: Bool) async {
        let token = UUID()
        haulToken = token
        let wait = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard let self, self.haulToken == token else { return }
            self.isHauling = true
        }
        let loaded = await store.load()
        document = loaded.document
        warning = loaded.warning
        if seed {
            do {
                if let seeded = try await store.seedDemoIfNeeded(now: now(), calendar: calendar) {
                    document = seeded
                    warning = nil
                }
            } catch {
                fault = Self.saveFailed
            }
        }
        wait.cancel()
        haulToken = nil
        isHauling = false
        applyWarning()
        markDay()
    }

    private func applyWarning() {
        if warning == .startedEmpty {
            fault = "The creel could not be read. Today's stringer is empty."
        } else if warning == .recoveredFromBackup {
            fault = "Recovered the last good creel."
        }
    }

    private func run(haptic: Bool = true, _ work: () async throws -> Void) async {
        guard !isCommitting else { return }
        isCommitting = true
        spinTask?.cancel()
        spinTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard let self, !Task.isCancelled, self.isCommitting else { return }
            self.isSpinning = true
        }
        defer {
            spinTask?.cancel()
            spinTask = nil
            isSpinning = false
            isCommitting = false
        }
        do {
            if warning != .recoveredFromBackup {
                fault = nil
            }
            try await work()
            if haptic {
                #if canImport(UIKit)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                #endif
            }
        } catch let creel as CreelFault {
            fault = Self.copy(creel)
        } catch {
            fault = Self.saveFailed
        }
    }

    private static let saveFailed = "The creel could not be written. Try again."

    static func copy(_ fault: CreelFault) -> String {
        switch fault {
        case .invalidLength:
            "Length must be greater than zero."
        case .invalidWeight:
            "Weight must be greater than zero."
        case .unknownSpecies:
            "Pick a species on the stringer."
        case .invalidLimit:
            "Bag limits cannot be negative, and the name cannot be empty."
        case .emptyStringer:
            "There is no fish to peel."
        }
    }
}
