import Foundation

/// Role: Over. A keep that hung past a full bag. Remaining stays at zero; Keep is not refused.
struct Over: Equatable, Sendable {
    var fishID: UUID
    var speciesID: UUID
    var day: CensusDay
    var seasonYear: Int
}

/// Role: Over. Published after a keep that already had no remaining. Colour is never the only signal.
enum CreelNotice: Equatable, Sendable {
    case overhang
}
