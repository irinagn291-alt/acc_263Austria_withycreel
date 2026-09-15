import Foundation

/// Role: Stringer. Remaining daily and season counts are derived at display and are never stored.
enum CreelCensus {
    static func keepMarks(in document: CreelDocument) -> [KeepMark] {
        document.creels.values.flatMap { $0.compactMap(\.keepMark) }
    }

    static func dailyKept(species: UUID, day: CensusDay, in document: CreelDocument) -> Int {
        keepMarks(in: document).filter { $0.speciesID == species && $0.day == day }.count
    }

    static func seasonKept(species: UUID, year: Int, in document: CreelDocument) -> Int {
        keepMarks(in: document).filter { $0.speciesID == species && $0.day.seasonYear == year }.count
    }

    static func remainingDaily(species: UUID, day: CensusDay, in document: CreelDocument) -> Int {
        let limit = document.limit(id: species)?.dailyBag ?? 0
        let kept = dailyKept(species: species, day: day, in: document)
        return max(0, limit - kept)
    }

    static func remainingSeason(species: UUID, year: Int, in document: CreelDocument) -> Int {
        let limit = document.limit(id: species)?.seasonBag ?? 0
        let kept = seasonKept(species: species, year: year, in: document)
        return max(0, limit - kept)
    }

    static func exceedsLimit(species: UUID, day: CensusDay, in document: CreelDocument) -> Bool {
        guard let limit = document.limit(id: species) else { return false }
        let daily = dailyKept(species: species, day: day, in: document)
        let season = seasonKept(species: species, year: day.seasonYear, in: document)
        return daily > limit.dailyBag || season > limit.seasonBag
    }
}
