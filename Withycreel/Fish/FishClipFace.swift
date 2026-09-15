import SwiftUI

/// Role: Fish. Filed clip on today's stringer. Length and weight stay centimetres and kilograms in the store.
struct FishClipFace: View {
    var clip: Stringer
    var hold: CreelHold

    var body: some View {
        VStack(alignment: .leading, spacing: CreelFace.space(2)) {
            HStack(alignment: .firstTextBaseline, spacing: CreelFace.space(1)) {
                Text(speciesName)
                    .font(CreelFace.font(.title))
                    .foregroundStyle(CreelInk.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .truncationMode(.tail)
                Spacer(minLength: CreelFace.space(1))
                CreelRoleBadge(title: roleTitle, hangs: clip.hangsOver)
            }
            Text(roleLine)
                .font(CreelFace.font(.caption))
                .foregroundStyle(CreelInk.ink)
                .lineLimit(3)
            HStack(alignment: .firstTextBaseline, spacing: CreelFace.space(2)) {
                CreelFigureTile(title: "Length", value: lengthText)
                CreelFigureTile(title: "Weight", value: weightText)
            }
            if clip.hangsOver {
                Text("Hung past the last clip. Remaining stayed at zero.")
                    .font(CreelFace.font(.caption))
                    .foregroundStyle(CreelInk.ink)
                    .lineLimit(3)
            }
            if let fish {
                HStack(alignment: .firstTextBaseline, spacing: CreelFace.space(2)) {
                    CreelFigureTile(
                        title: "Left today",
                        value: CreelFigure.count(hold.remainingDaily(for: fish.speciesID))
                    )
                    CreelFigureTile(
                        title: "Left this year",
                        value: CreelFigure.count(hold.remainingSeason(for: fish.speciesID))
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                Text("Swipe to the open clip to Keep again.")
                    .font(CreelFace.font(.caption))
                    .foregroundStyle(CreelInk.ink)
                    .lineLimit(2)
            }
            HStack(alignment: .firstTextBaseline, spacing: CreelFace.space(1)) {
                Text(CreelFigure.day(fishDay, calendar: .current))
                    .font(CreelFace.font(.caption))
                    .foregroundStyle(CreelInk.muted)
                    .lineLimit(1)
                Spacer(minLength: CreelFace.space(1))
                Text(keepLabel)
                    .font(CreelFace.font(.caption))
                    .foregroundStyle(CreelInk.ink)
                    .lineLimit(1)
                    .layoutPriority(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .accessibilityElement(children: .combine)
    }

    private var fish: Fish? {
        switch clip {
        case .open:
            nil
        case .kept(let fish, _), .released(let fish), .over(let fish, _, _):
            fish
        }
    }

    private var fishDay: CensusDay {
        fish?.day ?? hold.today
    }

    private var speciesName: String {
        guard let fish else { return "—" }
        return hold.name(for: fish.speciesID)
    }

    private var roleTitle: String {
        switch clip {
        case .open:
            "Open"
        case .kept:
            "Kept"
        case .released:
            "Released"
        case .over:
            "Over"
        }
    }

    private var roleLine: String {
        switch clip {
        case .open:
            "Species, length, and Keep fuse on the open clip."
        case .kept:
            "Kept. Spent one from daily remaining and from this year's remaining."
        case .released:
            "Released. Filed without a keep and without spending remaining."
        case .over:
            "Over. This keep hung past a full bag. Keep was not refused."
        }
    }

    private var lengthText: String {
        guard let fish else { return "—" }
        return CreelFigure.length(fish.lengthCentimetres, yard: hold.document.yard)
    }

    private var weightText: String {
        guard let fish else { return "—" }
        return CreelFigure.weight(fish.weightKilograms, yard: hold.document.yard)
    }

    private var keepLabel: String {
        switch clip {
        case .kept, .over:
            "Keep mark"
        case .released:
            "No keep mark"
        case .open:
            "Open clip"
        }
    }
}
