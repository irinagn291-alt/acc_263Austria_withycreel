import SwiftUI

/// Role: Stringer. Catches home. Vertical snap of glass clips; species, length, Keep, and Release fuse on Open.
struct CatchesPane: View {
    @Bindable var hold: CreelHold
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var focused: StringerClipID? = .open
    @State private var showOverhang = false
    @State private var confirmPeel = false
    @State private var showSuccess = false
    @State private var successTask: Task<Void, Never>?

    var body: some View {
        Group {
            if hold.isHauling {
                ProgressView()
                    .tint(CreelInk.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if hold.loadFailed {
                CreelVacancy(
                    image: CreelArt.emptyHome,
                    headline: "The stringer could not be read.",
                    line: hold.fault ?? "Today's stringer is empty.",
                    actionTitle: "Retry",
                    enabled: !hold.isCommitting
                ) {
                    Task { await hold.retry() }
                }
            } else if hold.todayIsEmpty {
                CreelVacancy(
                    image: CreelArt.emptyHome,
                    headline: "No catches yet.",
                    line: "Log the first fish.",
                    actionTitle: "Keep",
                    enabled: hold.keepIsEnabled && !hold.isCommitting
                ) {
                    Task { await hold.keepOpen() }
                }
            } else {
                populated
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CreelInk.background.ignoresSafeArea())
        .navigationTitle("Catches")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(CreelInk.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                CreelGlyphButton(
                    systemName: "info.circle",
                    label: "How overhang keep works"
                ) {
                    showOverhang = true
                }
            }
        }
        .sheet(isPresented: $showOverhang) {
            NavigationStack {
                OverhangPane(hold: hold, onClose: { showOverhang = false })
            }
            .presentationDetents([.large])
            .presentationCornerRadius(CreelFace.cardRadius)
            .presentationBackground(CreelInk.background)
        }
        .confirmationDialog(
            "Peel the last fish from today's stringer?",
            isPresented: $confirmPeel,
            titleVisibility: .visible
        ) {
            Button("Peel last fish", role: .destructive) {
                Task { await hold.peel() }
            }
            Button("Keep it on the stringer", role: .cancel) {}
        }
        .onChange(of: hold.commitTick) { _, _ in
            flashSuccess()
        }
        .onDisappear {
            successTask?.cancel()
        }
        .overlay {
            if showSuccess {
                Image(CreelArt.successMark)
                    .resizable()
                    .scaledToFit()
                    .frame(width: CreelFace.space(10), height: CreelFace.space(10))
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .overlay {
            if hold.isSpinning {
                ProgressView()
                    .tint(CreelInk.accent)
                    .accessibilityLabel("Saving the creel")
            }
        }
        .animation(reduceMotion ? CreelPlate.fade : CreelPlate.motion, value: showSuccess)
        .animation(reduceMotion ? CreelPlate.fade : CreelPlate.motion, value: hold.todayIsEmpty)
    }

    private var populated: some View {
        let leaves = clipLeaves
        return GeometryReader { geo in
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    ForEach(leaves) { leaf in
                        clipPage(leaf)
                            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                            .clipped()
                            .id(leaf.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .scrollPosition(id: $focused)
        }
        .onChange(of: hold.document.fish(on: hold.today).map(\.id)) { _, ids in
            if let focused, case .fish(let id) = focused, !ids.contains(id) {
                self.focused = .open
            }
        }
    }

    private var clipLeaves: [ClipLeaf] {
        hold.document.clips(on: hold.today).map { clip in
            switch clip {
            case .open:
                ClipLeaf(id: .open, clip: clip)
            case .kept(let fish, _), .released(let fish), .over(let fish, _, _):
                ClipLeaf(id: .fish(fish.id), clip: clip)
            }
        }
    }

    @ViewBuilder
    private func clipPage(_ leaf: ClipLeaf) -> some View {
        switch leaf.clip {
        case .open:
            GlassClipShell(hangsOver: false, jawOpen: false) {
                OpenClipFace(
                    hold: hold,
                    onOverhang: { showOverhang = true },
                    onPeel: { confirmPeel = true }
                )
            }
        case .kept, .released, .over:
            GlassClipShell(hangsOver: leaf.clip.hangsOver, jawOpen: isReleased(leaf.clip)) {
                FishClipFace(clip: leaf.clip, hold: hold)
            }
        }
    }

    private func isReleased(_ clip: Stringer) -> Bool {
        if case .released = clip { return true }
        return false
    }

    private func flashSuccess() {
        successTask?.cancel()
        successTask = Task {
            showSuccess = true
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard !Task.isCancelled else { return }
            showSuccess = false
        }
    }
}

enum StringerClipID: Hashable {
    case open
    case fish(UUID)
}

private struct ClipLeaf: Identifiable {
    var id: StringerClipID
    var clip: Stringer
}

#Preview {
    NavigationStack {
        CatchesPane(hold: .previewPopulated())
    }
}
