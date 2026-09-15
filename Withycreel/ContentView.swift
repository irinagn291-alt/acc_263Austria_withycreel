import SwiftUI

/// Role: Stringer. Host. Passage first; then stringer-tab chrome. Views never touch the store.
struct ContentView: View {
    @State private var hold: CreelHold
    var handlesLaunch: Bool
    @Environment(\.scenePhase) private var scenePhase
    @State private var ready = false

    init(hold: CreelHold = .live(), handlesLaunch: Bool = true) {
        self._hold = State(initialValue: hold)
        self.handlesLaunch = handlesLaunch
        self._ready = State(initialValue: !handlesLaunch)
    }

    var body: some View {
        Group {
            if handlesLaunch && !ready {
                CreelInk.background
                    .ignoresSafeArea()
                    .overlay {
                        Image(CreelArt.splash)
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                            .accessibilityHidden(true)
                    }
                    .overlay {
                        if hold.isHauling {
                            ProgressView()
                                .tint(CreelInk.accent)
                        }
                    }
            } else if hold.onboardingComplete {
                StringerChrome(hold: hold)
            } else {
                CreelPassage(hold: hold)
            }
        }
        .tint(CreelInk.accent)
        .preferredColorScheme(.light)
        .background(CreelInk.background.ignoresSafeArea())
        .task {
            guard handlesLaunch else {
                ready = true
                hold.applyReview()
                return
            }
            await hold.appear()
            ready = true
            await Task.yield()
            hold.applyReview()
        }
        .onChange(of: hold.onboardingComplete) { _, complete in
            if complete, ready {
                hold.applyReview()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard handlesLaunch else { return }
            if phase == .inactive || phase == .background {
                Task { await hold.flush() }
            }
            if phase == .active {
                hold.markDay()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            hold.markDay()
        }
    }
}

#Preview {
    ContentView(hold: .previewPopulated(), handlesLaunch: false)
}
