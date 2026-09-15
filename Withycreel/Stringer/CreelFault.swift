import Foundation

/// Role: Stringer. Typed faults of keep, release, and peel. Keep is never refused for a full bag.
enum CreelFault: Error, Equatable, Sendable {
    case invalidLength
    case invalidWeight
    case unknownSpecies
    case invalidLimit
    case emptyStringer
}

/// Role: Stringer. Recoverable load outcome. Never crash on a corrupt snapshot.
enum CreelWarning: Equatable, Sendable {
    case recoveredFromBackup
    case startedEmpty
}
