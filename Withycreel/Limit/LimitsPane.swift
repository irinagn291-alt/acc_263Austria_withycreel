import SwiftUI

/// Role: Limit. Vertical snap of SpeciesLimit cards. Daily and season bags edit here. Stock cards, not glass.
struct LimitsPane: View {
    @Bindable var hold: CreelHold
    @State private var focused: UUID?

    var body: some View {
        Group {
            if hold.isHauling {
                ProgressView()
                    .tint(CreelInk.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if hold.loadFailed {
                CreelVacancy(
                    image: CreelArt.emptyList,
                    headline: "Limits could not be read.",
                    line: hold.fault ?? "The creel started empty.",
                    actionTitle: "Retry",
                    enabled: !hold.isCommitting
                ) {
                    Task { await hold.retry() }
                }
            } else if hold.document.limits.isEmpty {
                CreelVacancy(
                    image: CreelArt.emptyList,
                    headline: "No bag limits yet.",
                    line: "Restore the stock bags, then keep on the stringer.",
                    actionTitle: "Restore stock bags",
                    enabled: !hold.isCommitting
                ) {
                    Task { await hold.restoreStockLimits() }
                }
            } else {
                populated
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CreelInk.background.ignoresSafeArea())
        .navigationTitle("Limits")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(CreelInk.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .overlay {
            if hold.isSpinning {
                ProgressView()
                    .tint(CreelInk.accent)
                    .accessibilityLabel("Saving limits")
            }
        }
    }

    private var populated: some View {
        GeometryReader { geo in
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    ForEach(hold.document.limits) { limit in
                        LimitCard(hold: hold, limit: limit)
                            .padding(.horizontal, CreelFace.space(2))
                            .padding(.vertical, CreelFace.space(2))
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                            .id(limit.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .scrollPosition(id: $focused)
        }
        .onAppear {
            if focused == nil {
                focused = hold.document.limits.first?.id
            }
        }
    }
}

/// Role: Limit. One species bag card. Remaining versus kept fills the page; Over-when-full stays on the card.
private struct LimitCard: View {
    @Bindable var hold: CreelHold
    var limit: SpeciesLimit

    var body: some View {
        VStack(alignment: .leading, spacing: CreelFace.space(2)) {
            header
            HStack(alignment: .top, spacing: CreelFace.space(2)) {
                todayLane
                yearLane
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            if let fault = hold.fault, !hold.loadFailed {
                CreelBanner(text: fault) {
                    Task { await hold.retry() }
                }
            }
        }
        .padding(CreelFace.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .creelCardFill()
    }

    private var todayLane: some View {
        bagLane(
            title: "Today",
            remaining: hold.remainingDaily(for: limit.id),
            kept: hold.dailyKept(for: limit.id),
            bag: limit.dailyBag,
            remainingTitle: "Left today",
            keptTitle: "Kept today",
            stepperTitle: "Daily bag",
            accessibility: "Daily bag for \(limit.name)"
        ) { next in
            Task { await revise(daily: next, season: limit.seasonBag) }
        }
    }

    private var yearLane: some View {
        bagLane(
            title: "This year",
            remaining: hold.remainingSeason(for: limit.id),
            kept: hold.seasonKept(for: limit.id),
            bag: limit.seasonBag,
            remainingTitle: "Left this year",
            keptTitle: "Kept this year",
            stepperTitle: "Season bag",
            accessibility: "Season bag for \(limit.name)"
        ) { next in
            Task { await revise(daily: limit.dailyBag, season: next) }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(limit.name)
                .font(CreelFace.font(.title))
                .foregroundStyle(CreelInk.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text("Edit the bag. Remaining versus kept. Over when this bag is full.")
                .font(CreelFace.font(.caption))
                .foregroundStyle(CreelInk.muted)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func bagLane(
        title: String,
        remaining: Int,
        kept: Int,
        bag: Int,
        remainingTitle: String,
        keptTitle: String,
        stepperTitle: String,
        accessibility: String,
        onChange: @escaping (Int) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: CreelFace.space(2)) {
            Text(title)
                .font(CreelFace.font(.callout).weight(.semibold))
                .foregroundStyle(CreelInk.ink)
                .lineLimit(1)
            VStack(alignment: .leading, spacing: 0) {
                labeledCount(title: remainingTitle, value: remaining)
                labeledCount(title: keptTitle, value: kept)
            }
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .contain)
            CreelBagCompare(
                remainingTitle: remainingTitle,
                remaining: remaining,
                keptTitle: keptTitle,
                kept: kept,
                over: remaining == 0
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            CreelBagTrack(kept: kept, bag: bag, remaining: remaining)
                .fixedSize(horizontal: false, vertical: true)
            bagStepper(title: stepperTitle, value: bag, accessibility: accessibility, onChange: onChange)
                .fixedSize(horizontal: false, vertical: true)
            overWhenFull(remaining: remaining)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(CreelFace.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(CreelInk.background)
        .clipShape(CreelPlate.chipShape)
    }

    private func overWhenFull(remaining: Int) -> some View {
        VStack(alignment: .leading, spacing: CreelFace.space(1)) {
            CreelRoleBadge(title: "Over", hangs: true)
            Text(
                remaining == 0
                    ? "This bag is full. A keep still files and hangs past the last clip."
                    : "Over when this bag is full. Keep still files; remaining stays at zero."
            )
            .font(CreelFace.font(.caption))
            .foregroundStyle(CreelInk.ink)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func labeledCount(title: String, value: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: CreelFace.space(1)) {
            Text(CreelFigure.count(value))
                .font(CreelFace.font(.display))
                .foregroundStyle(CreelInk.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .layoutPriority(1)
            Text(title)
                .font(CreelFace.font(.caption))
                .foregroundStyle(CreelInk.muted)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func bagStepper(
        title: String,
        value: Int,
        accessibility: String,
        onChange: @escaping (Int) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(CreelFace.font(.caption))
                .foregroundStyle(CreelInk.muted)
                .lineLimit(1)
            HStack(spacing: CreelFace.space(1)) {
                Button {
                    onChange(max(0, value - 1))
                } label: {
                    Image(systemName: "minus")
                        .font(CreelFace.font(.body).weight(.semibold))
                        .foregroundStyle(CreelInk.ink)
                        .frame(width: CreelFace.tap, height: CreelFace.tap)
                        .background(CreelInk.surface)
                        .clipShape(CreelPlate.chipShape)
                        .contentShape(CreelPlate.chipShape)
                }
                .buttonStyle(CreelPressStyle(enabled: value > 0 && !hold.isCommitting))
                .disabled(value <= 0 || hold.isCommitting)
                .accessibilityLabel("Decrease \(accessibility)")
                Text(CreelFigure.count(value))
                    .font(CreelFace.font(.figure))
                    .foregroundStyle(CreelInk.ink)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, minHeight: CreelFace.tap)
                    .layoutPriority(1)
                    .accessibilityLabel(accessibility)
                    .accessibilityValue(CreelFigure.count(value))
                Button {
                    onChange(value + 1)
                } label: {
                    Image(systemName: "plus")
                        .font(CreelFace.font(.body).weight(.semibold))
                        .foregroundStyle(CreelInk.ink)
                        .frame(width: CreelFace.tap, height: CreelFace.tap)
                        .background(CreelInk.surface)
                        .clipShape(CreelPlate.chipShape)
                        .contentShape(CreelPlate.chipShape)
                }
                .buttonStyle(CreelPressStyle(enabled: !hold.isCommitting))
                .disabled(hold.isCommitting)
                .accessibilityLabel("Increase \(accessibility)")
            }
            .frame(maxWidth: .infinity, minHeight: CreelFace.tap)
        }
    }

    private func revise(daily: Int, season: Int) async {
        await hold.reviseLimit(
            SpeciesLimit(
                id: limit.id,
                name: limit.name,
                dailyBag: max(0, daily),
                seasonBag: max(0, season)
            )
        )
    }
}

#Preview {
    NavigationStack {
        LimitsPane(hold: .previewPopulated())
    }
}
