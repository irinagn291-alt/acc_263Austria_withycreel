import Foundation

/// Role: Stringer. The composing clip. Species, length, and weight fuse here before Keep or Release.
struct OpenClip: Equatable, Sendable {
    var speciesID: UUID
    var lengthCentimetres: Double
    var weightKilograms: Double

    static let stock = OpenClip(
        speciesID: CensusStock.perchID,
        lengthCentimetres: 28,
        weightKilograms: 0.42
    )
}

/// Role: Stringer. ADT fold Open | Kept | Released | Over. The day is a fold over Fish, not an editable list.
enum Stringer: Equatable, Sendable {
    case open(OpenClip)
    case kept(Fish, KeepMark)
    case released(Fish)
    case over(Fish, KeepMark, Over)

    var hangsOver: Bool {
        if case .over = self { return true }
        return false
    }
}

/// Role: Stringer. Fold Fish into clips. Keep writes KeepMark; Release files without spending; Over hangs past a full bag.
enum StringerFold {
    static func clip(for fish: Fish) -> Stringer {
        if let mark = fish.keepMark {
            if let overhang = fish.overhang {
                return .over(fish, mark, overhang)
            }
            return .kept(fish, mark)
        }
        return .released(fish)
    }

    static func clips(open: OpenClip, fish: [Fish]) -> [Stringer] {
        [.open(open)] + fish.map(clip(for:))
    }

    /// The day's ADT is the last Fish, or Open when the stringer has none.
    static func reducing(open: OpenClip, fish: [Fish]) -> Stringer {
        fish.reduce(Stringer.open(open)) { _, item in
            clip(for: item)
        }
    }
}
