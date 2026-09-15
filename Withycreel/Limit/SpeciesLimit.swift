import Foundation

/// Role: Limit. Daily and season bag for one species. Remaining is never stored here.
struct SpeciesLimit: Identifiable, Equatable, Sendable {
    var id: UUID
    var name: String
    var dailyBag: Int
    var seasonBag: Int
}

/// Role: Limit. Stock creel-census species with room left after a live seed.
enum CensusStock {
    private static func fixed(_ value: String) -> UUID {
        UUID(uuidString: value) ?? UUID()
    }

    static let perchID = fixed("A1111111-0000-4000-8000-000000000001")
    static let breamID = fixed("A1111111-0000-4000-8000-000000000002")
    static let pikeID = fixed("A1111111-0000-4000-8000-000000000003")
    static let tenchID = fixed("A1111111-0000-4000-8000-000000000004")

    static let perch = SpeciesLimit(id: perchID, name: "Perch", dailyBag: 15, seasonBag: 80)
    static let bream = SpeciesLimit(id: breamID, name: "Bream", dailyBag: 10, seasonBag: 50)
    static let pike = SpeciesLimit(id: pikeID, name: "Pike", dailyBag: 5, seasonBag: 20)
    static let tench = SpeciesLimit(id: tenchID, name: "Tench", dailyBag: 8, seasonBag: 40)

    static let all: [SpeciesLimit] = [perch, bream, pike, tench]
}
