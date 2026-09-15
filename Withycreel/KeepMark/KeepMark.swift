import Foundation

/// Role: KeepMark. Proof that a Fish spent one from daily remaining and from season remaining.
struct KeepMark: Identifiable, Equatable, Sendable {
    var id: UUID
    var fishID: UUID
    var speciesID: UUID
    var day: CensusDay
}
