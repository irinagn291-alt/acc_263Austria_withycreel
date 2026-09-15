import Foundation

/// Role: Stringer. In-memory creel. Views call keep, release, and peel; remaining is a census, not a field.
struct CreelDocument: Equatable, Sendable {
    var schemaVersion: Int
    var onboardingComplete: Bool
    var yard: CreelYard
    var openClip: OpenClip
    var limits: [SpeciesLimit]
    var creels: [CensusDay: [Fish]]

    static let empty = CreelDocument(
        schemaVersion: CreelCodec.currentSchema,
        onboardingComplete: false,
        yard: .metric,
        openClip: .stock,
        limits: CensusStock.all,
        creels: [:]
    )

    /// Keep stays enabled after seed. A full bag writes Over instead of disabling Keep.
    var keepIsEnabled: Bool { !limits.isEmpty }

    func limit(id: UUID) -> SpeciesLimit? {
        limits.first { $0.id == id }
    }

    func fish(on day: CensusDay) -> [Fish] {
        creels[day] ?? []
    }

    func stringer(on day: CensusDay) -> Stringer {
        StringerFold.reducing(open: openClip, fish: fish(on: day))
    }

    func clips(on day: CensusDay) -> [Stringer] {
        StringerFold.clips(open: openClip, fish: fish(on: day))
    }

    func completingOnboarding() -> CreelDocument {
        var next = self
        next.onboardingComplete = true
        if next.limits.isEmpty {
            next.limits = CensusStock.all
        }
        if next.limit(id: next.openClip.speciesID) == nil {
            next.openClip = .stock
        }
        return next
    }

    func settingYard(_ yard: CreelYard) -> CreelDocument {
        var next = self
        next.yard = yard
        return next
    }

    func settingOpenClip(_ clip: OpenClip) throws -> CreelDocument {
        try Self.validate(clip, limits: limits)
        var next = self
        next.openClip = clip
        return next
    }

    func revising(_ limit: SpeciesLimit) throws -> CreelDocument {
        let name = limit.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw CreelFault.invalidLimit }
        guard limit.dailyBag >= 0, limit.seasonBag >= 0 else { throw CreelFault.invalidLimit }
        var next = self
        if let index = next.limits.firstIndex(where: { $0.id == limit.id }) {
            next.limits[index] = SpeciesLimit(
                id: limit.id,
                name: name,
                dailyBag: limit.dailyBag,
                seasonBag: limit.seasonBag
            )
        } else {
            next.limits.append(
                SpeciesLimit(
                    id: limit.id,
                    name: name,
                    dailyBag: limit.dailyBag,
                    seasonBag: limit.seasonBag
                )
            )
        }
        return next
    }

    /// Keep always files. When remaining is already 0, the Fish is Over and a notice is published.
    func keep(
        _ clip: OpenClip,
        on day: CensusDay,
        fishID: UUID = UUID(),
        markID: UUID = UUID()
    ) throws -> (CreelDocument, CreelNotice?) {
        try Self.validate(clip, limits: limits)
        var next = self
        next.openClip = clip
        let hangs =
            CreelCensus.remainingDaily(species: clip.speciesID, day: day, in: next) == 0
            || CreelCensus.remainingSeason(species: clip.speciesID, year: day.seasonYear, in: next) == 0
        var fish = Fish(
            id: fishID,
            speciesID: clip.speciesID,
            day: day,
            lengthCentimetres: clip.lengthCentimetres,
            weightKilograms: clip.weightKilograms,
            keepMark: KeepMark(
                id: markID,
                fishID: fishID,
                speciesID: clip.speciesID,
                day: day
            ),
            overhang: nil
        )
        if hangs {
            fish.overhang = Over(
                fishID: fishID,
                speciesID: clip.speciesID,
                day: day,
                seasonYear: day.seasonYear
            )
        }
        next.creels[day, default: []].append(fish)
        return (next, hangs ? .overhang : nil)
    }

    /// Release files without a KeepMark and spends nothing.
    func release(
        _ clip: OpenClip,
        on day: CensusDay,
        fishID: UUID = UUID()
    ) throws -> (CreelDocument, Release) {
        try Self.validate(clip, limits: limits)
        var next = self
        next.openClip = clip
        let fish = Fish(
            id: fishID,
            speciesID: clip.speciesID,
            day: day,
            lengthCentimetres: clip.lengthCentimetres,
            weightKilograms: clip.weightKilograms,
            keepMark: nil,
            overhang: nil
        )
        next.creels[day, default: []].append(fish)
        return (next, Release(fishID: fishID))
    }

    /// Peel the last Fish on this day's stringer only. Remaining restores when that Fish carried a KeepMark.
    func peel(on day: CensusDay) throws -> CreelDocument {
        guard var list = creels[day], !list.isEmpty else { throw CreelFault.emptyStringer }
        list.removeLast()
        var next = self
        if list.isEmpty {
            next.creels[day] = nil
        } else {
            next.creels[day] = list
        }
        return next
    }

    private static func validate(_ clip: OpenClip, limits: [SpeciesLimit]) throws {
        guard clip.lengthCentimetres.isFinite, clip.lengthCentimetres > 0 else {
            throw CreelFault.invalidLength
        }
        guard clip.weightKilograms.isFinite, clip.weightKilograms > 0 else {
            throw CreelFault.invalidWeight
        }
        guard limits.contains(where: { $0.id == clip.speciesID }) else {
            throw CreelFault.unknownSpecies
        }
    }
}
