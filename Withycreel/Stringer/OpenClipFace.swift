import SwiftUI

/// Role: Stringer. Open clip. Species, length, weight, Keep, and Release fuse here — not a pushed log row.
struct OpenClipFace: View {
    @Bindable var hold: CreelHold
    var onOverhang: () -> Void
    var onPeel: () -> Void
    @Environment(\.horizontalSizeClass) private var sizeClass
    @FocusState private var focus: Field?
    @State private var speciesID: UUID
    @State private var lengthDraft: String
    @State private var weightDraft: String

    private enum Field: Hashable {
        case length
        case weight
    }

    init(hold: CreelHold, onOverhang: @escaping () -> Void, onPeel: @escaping () -> Void) {
        self.hold = hold
        self.onOverhang = onOverhang
        self.onPeel = onPeel
        _speciesID = State(initialValue: hold.document.openClip.speciesID)
        _lengthDraft = State(initialValue: Self.draftLength(hold.document.openClip, yard: hold.document.yard))
        _weightDraft = State(initialValue: Self.draftWeight(hold.document.openClip, yard: hold.document.yard))
    }

    private var usesSplit: Bool {
        sizeClass == .regular
    }

    var body: some View {
        Group {
            if usesSplit {
                splitCanvas
            } else {
                stackedCanvas
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onChange(of: hold.document.yard) { _, _ in
            guard focus == nil else { return }
            syncDrafts()
        }
        .onChange(of: hold.document.openClip.speciesID) { _, next in
            speciesID = next
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focus = nil
                    CreelKeyboard.dismiss()
                }
                .accessibilityLabel("Done")
            }
        }
    }

    private var stackedCanvas: some View {
        VStack(alignment: .leading, spacing: CreelFace.space(1)) {
            jobBlock
            remainingBoard
                .frame(minHeight: CreelFace.space(10), maxHeight: .infinity)
            cueAndFault
            speciesRow
            measureRow
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .safeAreaInset(edge: .bottom, spacing: CreelFace.space(1)) {
            keepCluster
        }
    }

    private var splitCanvas: some View {
        VStack(alignment: .leading, spacing: CreelFace.space(2)) {
            jobBlock
            HStack(alignment: .top, spacing: CreelFace.space(2)) {
                remainingBoard
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                VStack(alignment: .leading, spacing: CreelFace.space(2)) {
                    cueAndFault
                    speciesRow
                    measureRow
                    keepWell
                    secondaryRow
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var jobBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(hold.jobTitle)
                .font(CreelFace.font(.title))
                .foregroundStyle(CreelInk.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(hold.jobLine)
                .font(CreelFace.font(.callout))
                .foregroundStyle(CreelInk.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var remainingBoard: some View {
        remainingFigures
            .padding(CreelFace.space(2))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background {
                CreelInk.background
                Image(CreelArt.headerDecor)
                    .resizable()
                    .scaledToFit()
                    .opacity(0.16)
                    .padding(CreelFace.space(2))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .clipShape(CreelPlate.chipShape)
    }

    private var remainingFigures: some View {
        VStack(alignment: .leading, spacing: CreelFace.space(1)) {
            Text(hold.name(for: speciesID))
                .font(CreelFace.font(.display))
                .foregroundStyle(CreelInk.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(alignment: .firstTextBaseline, spacing: CreelFace.space(2)) {
                CreelFigureTile(
                    title: "Left today",
                    value: CreelFigure.count(hold.remainingDaily(for: speciesID))
                )
                CreelFigureTile(
                    title: usesSplit ? "Kept today" : "Left this year",
                    value: CreelFigure.count(
                        usesSplit
                            ? hold.dailyKept(for: speciesID)
                            : hold.remainingSeason(for: speciesID)
                    )
                )
            }
            .accessibilityElement(children: .contain)
            if usesSplit {
                HStack(alignment: .firstTextBaseline, spacing: CreelFace.space(2)) {
                    CreelFigureTile(
                        title: "Left this year",
                        value: CreelFigure.count(hold.remainingSeason(for: speciesID))
                    )
                    CreelFigureTile(
                        title: "Kept this year",
                        value: CreelFigure.count(hold.seasonKept(for: speciesID))
                    )
                }
                .accessibilityElement(children: .contain)
            }
            CreelBagCompare(
                remainingTitle: "Left today",
                remaining: hold.remainingDaily(for: speciesID),
                keptTitle: "Kept today",
                kept: hold.dailyKept(for: speciesID),
                over: hold.remainingDaily(for: speciesID) == 0
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack(alignment: .firstTextBaseline, spacing: CreelFace.space(1)) {
                Text("This month")
                    .font(CreelFace.font(.caption))
                    .foregroundStyle(CreelInk.muted)
                    .lineLimit(1)
                Text(CreelFigure.weight(hold.monthlyKeptKilograms, yard: hold.document.yard))
                    .font(CreelFace.font(.figure))
                    .foregroundStyle(CreelInk.ink)
                    .lineLimit(1)
                    .layoutPriority(1)
            }
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private var cueAndFault: some View {
        OverhangCue(line: hold.overhangLine, action: onOverhang)
        if let fault = hold.fault, !hold.loadFailed {
            CreelBanner(text: fault) {
                Task { await hold.retry() }
            }
        }
    }

    private var speciesRow: some View {
        HStack(spacing: CreelFace.space(1)) {
            ForEach(hold.document.limits) { limit in
                Button {
                    speciesID = limit.id
                    persistClip()
                } label: {
                    CreelSpeciesChip(title: limit.name, selected: limit.id == speciesID)
                }
                .buttonStyle(CreelPressStyle(enabled: true))
                .accessibilityLabel(limit.name)
                .accessibilityValue(limit.id == speciesID ? "Selected" : "Not selected")
            }
        }
        .frame(maxWidth: .infinity, minHeight: CreelFace.tap)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityLabel("Species")
    }

    private var measureRow: some View {
        HStack(alignment: .top, spacing: CreelFace.space(1)) {
            measureField(
                title: "Length \(CreelFigure.lengthUnit(hold.document.yard))",
                draft: $lengthDraft,
                field: .length,
                label: "Length in \(CreelFigure.lengthUnit(hold.document.yard))"
            )
            measureField(
                title: "Weight \(CreelFigure.weightUnit(hold.document.yard))",
                draft: $weightDraft,
                field: .weight,
                label: "Weight in \(CreelFigure.weightUnit(hold.document.yard))"
            )
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var keepCluster: some View {
        VStack(spacing: CreelFace.space(1)) {
            CreelSoftKeep(
                title: "Keep",
                detail: keepDetail,
                enabled: canCommit,
                busy: hold.isCommitting,
                hint: "Files this fish on today's stringer."
            ) {
                commitKeep()
            }
            secondaryRow
        }
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var secondaryRow: some View {
        HStack(spacing: CreelFace.space(1)) {
            CreelCardButton(
                title: "Release",
                enabled: canCommit,
                busy: hold.isCommitting
            ) {
                commitRelease()
            }
            CreelCardButton(
                title: "Peel last",
                enabled: hold.canPeel && !hold.isCommitting,
                busy: hold.isCommitting
            ) {
                onPeel()
            }
        }
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var keepWell: some View {
        let active = canCommit
        return Button {
            commitKeep()
        } label: {
            VStack(alignment: .leading, spacing: CreelFace.space(2)) {
                HStack(alignment: .center, spacing: CreelFace.space(2)) {
                    Image(CreelArt.controlFace)
                        .resizable()
                        .scaledToFit()
                        .frame(width: CreelFace.space(6), height: CreelFace.space(6))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Keep")
                            .font(CreelFace.font(.title))
                            .foregroundStyle(CreelInk.ink)
                            .lineLimit(1)
                        Text(keepDetail)
                            .font(CreelFace.font(.callout))
                            .foregroundStyle(CreelInk.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                keepClipSummary
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding(CreelFace.space(2))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(active ? CreelInk.accent.opacity(0.18) : CreelInk.surface)
            .clipShape(CreelPlate.cardShape)
            .overlay {
                CreelPlate.cardShape.stroke(
                    active ? CreelInk.accent : CreelInk.muted.opacity(0.35),
                    lineWidth: active ? 3 : 1
                )
            }
            .creelRaised()
            .contentShape(CreelPlate.cardShape)
        }
        .buttonStyle(CreelPressStyle(enabled: active))
        .disabled(!active)
        .accessibilityLabel("Keep. \(keepDetail)")
        .accessibilityHint("Files this fish on today's stringer.")
    }

    private var keepClipSummary: some View {
        VStack(alignment: .leading, spacing: CreelFace.space(2)) {
            Text(hold.name(for: speciesID))
                .font(CreelFace.font(.display))
                .foregroundStyle(CreelInk.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            HStack(alignment: .firstTextBaseline, spacing: CreelFace.space(2)) {
                CreelFigureTile(
                    title: "Length \(CreelFigure.lengthUnit(hold.document.yard))",
                    value: lengthDraft.isEmpty ? "—" : lengthDraft
                )
                CreelFigureTile(
                    title: "Weight \(CreelFigure.weightUnit(hold.document.yard))",
                    value: weightDraft.isEmpty ? "—" : weightDraft
                )
            }
            HStack(alignment: .firstTextBaseline, spacing: CreelFace.space(2)) {
                CreelFigureTile(
                    title: "Left today",
                    value: CreelFigure.count(hold.remainingDaily(for: speciesID))
                )
                CreelFigureTile(
                    title: "After this keep",
                    value: CreelFigure.count(afterKeepRemaining)
                )
            }
            CreelBagCompare(
                remainingTitle: "Left today",
                remaining: hold.remainingDaily(for: speciesID),
                keptTitle: "Kept today",
                kept: hold.dailyKept(for: speciesID),
                over: hold.remainingDaily(for: speciesID) == 0
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var keepDetail: String {
        hold.bagIsFull
            ? "Files even when the bag is full."
            : "Writes a keep and spends one remaining."
    }

    private var afterKeepRemaining: Int {
        let left = hold.remainingDaily(for: speciesID)
        if left == 0 { return 0 }
        return left - 1
    }

    private func measureField(
        title: String,
        draft: Binding<String>,
        field: Field,
        label: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(CreelFace.font(.caption))
                .foregroundStyle(CreelInk.muted)
                .lineLimit(1)
            TextField("0", text: draft)
                .keyboardType(.decimalPad)
                .textFieldStyle(.plain)
                .font(CreelFace.font(.figure))
                .foregroundStyle(CreelInk.ink)
                .padding(.horizontal, CreelFace.space(1))
                .frame(maxWidth: .infinity, minHeight: CreelFace.tap)
                .background(CreelInk.background)
                .clipShape(CreelPlate.chipShape)
                .focused($focus, equals: field)
                .onChange(of: draft.wrappedValue) { _, next in
                    let cleaned = CreelFigure.sanitizeDecimal(next)
                    if cleaned != next { draft.wrappedValue = cleaned }
                    persistClip()
                }
                .accessibilityLabel(label)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var canCommit: Bool {
        hold.keepIsEnabled && !hold.isCommitting && parsedClip() != nil
    }

    private func parsedClip() -> OpenClip? {
        guard let displayedLength = CreelFigure.parseDecimal(lengthDraft) else { return nil }
        guard let displayedWeight = CreelFigure.parseDecimal(weightDraft) else { return nil }
        let clip = OpenClip(
            speciesID: speciesID,
            lengthCentimetres: CreelMeasure.storedCentimetres(
                displayed: displayedLength,
                yard: hold.document.yard
            ),
            weightKilograms: CreelMeasure.storedKilograms(
                displayed: displayedWeight,
                yard: hold.document.yard
            )
        )
        return clip
    }

    private func persistClip() {
        guard let clip = parsedClip() else { return }
        Task { await hold.setOpenClip(clip) }
    }

    private func commitKeep() {
        focus = nil
        CreelKeyboard.dismiss()
        guard let clip = parsedClip() else { return }
        Task { await hold.keep(clip) }
    }

    private func commitRelease() {
        focus = nil
        CreelKeyboard.dismiss()
        guard let clip = parsedClip() else { return }
        Task { await hold.release(clip) }
    }

    private func syncDrafts() {
        lengthDraft = Self.draftLength(hold.document.openClip, yard: hold.document.yard)
        weightDraft = Self.draftWeight(hold.document.openClip, yard: hold.document.yard)
        speciesID = hold.document.openClip.speciesID
    }

    private static func draftLength(_ clip: OpenClip, yard: CreelYard) -> String {
        let shown = CreelMeasure.displayedLength(centimetres: clip.lengthCentimetres, yard: yard)
        return CreelFigure.decimal(shown, fraction: yard == .metric ? 0 : 1)
    }

    private static func draftWeight(_ clip: OpenClip, yard: CreelYard) -> String {
        let shown = CreelMeasure.displayedWeight(kilograms: clip.weightKilograms, yard: yard)
        return CreelFigure.decimal(shown, fraction: 2)
    }
}
