import SwiftUI

/// Role: Stringer. Tab chrome. Catches holds the stringer; Limits and Settings are siblings. No Game tab.
struct StringerChrome: View {
    @Bindable var hold: CreelHold
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var tab: StringerTab

    init(hold: CreelHold) {
        self.hold = hold
        hold.applyReview()
        _tab = State(initialValue: hold.tab)
    }

    private var docksRail: Bool {
        sizeClass != .regular
    }

    var body: some View {
        Group {
            if #available(iOS 18.0, *) {
                TabView(selection: $tab) {
                    Tab(StringerTab.catches.title, systemImage: StringerTab.catches.symbol, value: StringerTab.catches) {
                        NavigationStack {
                            CatchesPane(hold: hold)
                        }
                        .toolbar(docksRail ? .hidden : .automatic, for: .tabBar)
                    }
                    Tab(StringerTab.limits.title, systemImage: StringerTab.limits.symbol, value: StringerTab.limits) {
                        NavigationStack {
                            LimitsPane(hold: hold)
                        }
                        .toolbar(docksRail ? .hidden : .automatic, for: .tabBar)
                    }
                    Tab(StringerTab.settings.title, systemImage: StringerTab.settings.symbol, value: StringerTab.settings) {
                        NavigationStack {
                            CreelSettings(hold: hold)
                        }
                        .toolbar(docksRail ? .hidden : .automatic, for: .tabBar)
                    }
                }
                .tabViewStyle(.tabBarOnly)
            } else {
                TabView(selection: $tab) {
                    NavigationStack {
                        CatchesPane(hold: hold)
                    }
                    .tabItem {
                        Label(StringerTab.catches.title, systemImage: StringerTab.catches.symbol)
                    }
                    .tag(StringerTab.catches)
                    .toolbar(docksRail ? .hidden : .automatic, for: .tabBar)

                    NavigationStack {
                        LimitsPane(hold: hold)
                    }
                    .tabItem {
                        Label(StringerTab.limits.title, systemImage: StringerTab.limits.symbol)
                    }
                    .tag(StringerTab.limits)
                    .toolbar(docksRail ? .hidden : .automatic, for: .tabBar)

                    NavigationStack {
                        CreelSettings(hold: hold)
                    }
                    .tabItem {
                        Label(StringerTab.settings.title, systemImage: StringerTab.settings.symbol)
                    }
                    .tag(StringerTab.settings)
                    .toolbar(docksRail ? .hidden : .automatic, for: .tabBar)
                }
            }
        }
        .id(tab)
        .toolbar(docksRail ? .hidden : .automatic, for: .tabBar)
        .toolbarBackground(CreelInk.surface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .tint(CreelInk.accent)
        .creelTabBarPinned(hidingSystemBar: docksRail)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if docksRail {
                CreelTabRail(tab: $tab)
            }
        }
        .onAppear {
            hold.applyReview()
            tab = hold.tab
        }
        .onChange(of: tab) { _, new in
            hold.tab = new
        }
        .onChange(of: hold.tab) { _, new in
            tab = new
        }
    }
}

/// Role: Stringer. Full-width tab rail that sits on the home indicator. Not a floating pill.
private struct CreelTabRail: View {
    @Binding var tab: StringerTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(StringerTab.allCases, id: \.self) { item in
                Button {
                    tab = item
                } label: {
                    VStack(spacing: 0) {
                        Image(systemName: item.symbol)
                            .font(CreelFace.font(.body).weight(.semibold))
                            .symbolVariant(tab == item ? .fill : .none)
                            .accessibilityHidden(true)
                        Text(item.title)
                            .font(CreelFace.font(.caption).weight(tab == item ? .semibold : .regular))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(tab == item ? CreelInk.ink : CreelInk.muted)
                    .frame(maxWidth: .infinity, minHeight: CreelFace.tap)
                    .padding(.top, CreelFace.space(1))
                    .contentShape(Rectangle())
                }
                .buttonStyle(CreelPressStyle(enabled: true))
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(tab == item ? .isSelected : [])
            }
        }
        .frame(maxWidth: .infinity)
        .background {
            CreelInk.surface.ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(CreelInk.muted.opacity(0.28))
                .frame(height: 1)
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .contain)
    }
}

private extension View {
    @ViewBuilder
    func creelTabBarPinned(hidingSystemBar: Bool) -> some View {
        if #available(iOS 26.0, *) {
            toolbarVisibility(hidingSystemBar ? .hidden : .automatic, for: .tabBar)
                .tabBarMinimizeBehavior(.never)
        } else if #available(iOS 18.0, *) {
            toolbarVisibility(hidingSystemBar ? .hidden : .automatic, for: .tabBar)
        } else {
            self
        }
    }
}
