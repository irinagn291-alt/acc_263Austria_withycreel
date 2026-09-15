import Foundation

/// Role: Fish. One catch on a day's stringer. Length and weight live as centimetres and kilograms.
struct Fish: Identifiable, Equatable, Sendable {
    var id: UUID
    var speciesID: UUID
    var day: CensusDay
    var lengthCentimetres: Double
    var weightKilograms: Double
    var keepMark: KeepMark?
    var overhang: Over?

    var isKept: Bool { keepMark != nil }
    var isReleased: Bool { keepMark == nil }
    var hangsOver: Bool { overhang != nil }
}
