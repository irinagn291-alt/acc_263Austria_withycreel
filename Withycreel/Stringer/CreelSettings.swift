import SwiftUI

/// Role: Stringer. Settings. Job groups: Display units, Export, Overhang keep, Contact, Data.
struct CreelSettings: View {
    @Bindable var hold: CreelHold
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var confirmReset = false

    private var usesSplit: Bool {
        sizeClass == .regular
    }

    var body: some View {
        Group {
            if hold.isHauling {
                ProgressView()
                    .tint(CreelInk.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if hold.loadFailed {
                CreelVacancy(
                    image: CreelArt.emptyList,
                    headline: "Settings could not be read.",
                    line: hold.fault ?? "The creel started empty.",
                    actionTitle: "Retry",
                    enabled: !hold.isCommitting
                ) {
                    Task { await hold.retry() }
                }
            } else {
                populated
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CreelInk.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(CreelInk.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .confirmationDialog(
            "Erase every fish, keep, and bag on this device?",
            isPresented: $confirmReset,
            titleVisibility: .visible
        ) {
            Button("Reset all data", role: .destructive) {
                Task { await hold.resetAll() }
            }
            Button("Keep the creel", role: .cancel) {}
        }
    }

    private var populated: some View {
        GeometryReader { geo in
            if usesSplit {
                settingsBoard
                    .padding(CreelFace.space(2))
                    .frame(width: geo.size.width, height: geo.size.height)
            } else {
                ScrollView {
                    settingsColumn
                        .padding(.horizontal, CreelFace.space(2))
                        .padding(.top, CreelFace.space(1))
                        .padding(.bottom, CreelFace.space(2))
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.immediately)
                .contentMargins(.bottom, CreelFace.space(12), for: .scrollContent)
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .tint(CreelInk.accent)
        .background(CreelInk.background)
    }

    private var settingsColumn: some View {
        VStack(alignment: .leading, spacing: CreelFace.space(2)) {
            notices
            unitsCard(fills: false)
            exportCard(fills: false)
            overhangCard(fills: false)
            contactCard(fills: false)
            dataCard(fills: false)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var settingsBoard: some View {
        VStack(alignment: .leading, spacing: CreelFace.space(2)) {
            notices
            HStack(alignment: .top, spacing: CreelFace.space(2)) {
                unitsCard(fills: true)
                exportCard(fills: true)
            }
            HStack(alignment: .top, spacing: CreelFace.space(2)) {
                overhangCard(fills: true)
                contactCard(fills: true)
            }
            dataCard(fills: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var notices: some View {
        if !hold.everFiled {
            emptyBanner
        }
        if let fault = hold.fault, !hold.loadFailed {
            CreelBanner(text: fault) {
                Task { await hold.retry() }
            }
        }
    }

    private var emptyBanner: some View {
        VStack(alignment: .leading, spacing: CreelFace.space(1)) {
            Image(CreelArt.emptyList)
                .resizable()
                .scaledToFit()
                .frame(height: CreelFace.space(8))
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
            Text("The creel is empty.")
                .font(CreelFace.font(.title))
                .foregroundStyle(CreelInk.ink)
            Text("Keep a fish, then export the census from here.")
                .font(CreelFace.font(.body))
                .foregroundStyle(CreelInk.muted)
            Button {
                hold.tab = .catches
            } label: {
                Text("Open Catches")
                    .font(CreelFace.font(.callout).weight(.semibold))
                    .foregroundStyle(CreelInk.ink)
                    .frame(maxWidth: .infinity, minHeight: CreelFace.tap)
                    .background(CreelInk.surface)
                    .clipShape(CreelPlate.cardShape)
                    .overlay {
                        CreelPlate.cardShape.stroke(CreelInk.accent, lineWidth: 2)
                    }
                    .contentShape(CreelPlate.cardShape)
            }
            .buttonStyle(CreelPressStyle(enabled: true))
            .accessibilityLabel("Open Catches")
        }
        .padding(CreelFace.space(2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .creelCardFill()
    }

    private func unitsCard(fills: Bool) -> some View {
        SettingsCard(title: "Display units", footer: "The store keeps centimetres and kilograms. This switch is display only.", fills: fills) {
            Picker("Display units", selection: yardBinding) {
                Text("Metric").tag(CreelYard.metric)
                Text("Imperial").tag(CreelYard.imperial)
            }
            .pickerStyle(.segmented)
            .frame(minHeight: CreelFace.tap)
            .accessibilityLabel("Display units")
            if fills {
                HStack(alignment: .firstTextBaseline, spacing: CreelFace.space(2)) {
                    CreelFigureTile(
                        title: "Open length",
                        value: CreelFigure.length(
                            hold.document.openClip.lengthCentimetres,
                            yard: hold.document.yard
                        )
                    )
                    CreelFigureTile(
                        title: "Open weight",
                        value: CreelFigure.weight(
                            hold.document.openClip.weightKilograms,
                            yard: hold.document.yard
                        )
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                Text("Open clip in the selected yard.")
                    .font(CreelFace.font(.caption))
                    .foregroundStyle(CreelInk.ink)
            }
        }
    }

    private func exportCard(fills: Bool) -> some View {
        SettingsCard(
            title: "Export",
            footer: "CSV writes a local file from the same creel document. Nothing leaves this device until you share it.",
            fills: fills
        ) {
            Button {
                Task { await hold.exportCSV() }
            } label: {
                Text(hold.csvURL == nil ? "Export CSV" : "Export again")
                    .font(CreelFace.font(.body).weight(.semibold))
                    .foregroundStyle(CreelInk.ink)
                    .frame(maxWidth: .infinity, minHeight: CreelFace.tap, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(CreelPressStyle(enabled: !hold.isCommitting))
            .disabled(hold.isCommitting)
            .accessibilityLabel("Export CSV")
            if let url = hold.csvURL {
                ShareLink(item: url) {
                    Text("Share creel-census.csv")
                        .font(CreelFace.font(.body).weight(.semibold))
                        .foregroundStyle(CreelInk.accent)
                        .frame(maxWidth: .infinity, minHeight: CreelFace.tap, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Share creel-census.csv")
            }
            if fills {
                HStack(alignment: .firstTextBaseline, spacing: CreelFace.space(2)) {
                    CreelFigureTile(title: "Filed fish", value: CreelFigure.count(filedCount))
                    CreelFigureTile(
                        title: "This month",
                        value: CreelFigure.weight(hold.monthlyKeptKilograms, yard: hold.document.yard)
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }

    private func overhangCard(fills: Bool) -> some View {
        SettingsCard(
            title: "Overhang keep",
            footer: "Keep always files. A full bag hangs Over.",
            fills: fills
        ) {
            NavigationLink {
                OverhangPane(hold: hold)
            } label: {
                HStack(alignment: .center, spacing: CreelFace.space(1)) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Overhang keep")
                            .font(CreelFace.font(.body))
                            .foregroundStyle(CreelInk.ink)
                        Text("Keep always files. A full bag hangs Over.")
                            .font(CreelFace.font(.caption))
                            .foregroundStyle(CreelInk.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, minHeight: CreelFace.tap, alignment: .leading)
                    Image(systemName: "chevron.right")
                        .font(CreelFace.font(.caption).weight(.semibold))
                        .foregroundStyle(CreelInk.muted)
                        .accessibilityHidden(true)
                }
                .contentShape(Rectangle())
            }
            if fills {
                HStack(alignment: .firstTextBaseline, spacing: CreelFace.space(2)) {
                    CreelFigureTile(
                        title: "Left today",
                        value: CreelFigure.count(hold.remainingDaily)
                    )
                    CreelFigureTile(
                        title: "Left this year",
                        value: CreelFigure.count(hold.remainingSeason)
                    )
                }
                CreelBagCompare(
                    remainingTitle: "Left today",
                    remaining: hold.remainingDaily,
                    keptTitle: "Kept today",
                    kept: hold.dailyKept(for: hold.document.openClip.speciesID),
                    over: hold.remainingDaily == 0
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func contactCard(fills: Bool) -> some View {
        SettingsCard(title: "Contact", fills: fills) {
            Link(destination: CreelHarbor.contact) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Contact Withycreel")
                        .font(CreelFace.font(.body))
                        .foregroundStyle(CreelInk.accent)
                    Text(CreelHarbor.contact.absoluteString)
                        .font(CreelFace.font(.caption))
                        .foregroundStyle(CreelInk.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, minHeight: CreelFace.tap, alignment: .leading)
                .contentShape(Rectangle())
            }
            .accessibilityLabel("Contact Withycreel")
            if fills {
                Text("Support opens this page. There is no account and no in-app shop.")
                    .font(CreelFace.font(.body))
                    .foregroundStyle(CreelInk.ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }

    private func dataCard(fills: Bool) -> some View {
        SettingsCard(
            title: "Data",
            footer: "Fish, keeps, and bags stay on this device. There is no account and no shop.",
            fills: fills
        ) {
            Button {
                Task { await hold.reopenOnboarding() }
            } label: {
                Text("Re-run onboarding")
                    .font(CreelFace.font(.body))
                    .foregroundStyle(CreelInk.ink)
                    .frame(maxWidth: .infinity, minHeight: CreelFace.tap, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(CreelPressStyle(enabled: !hold.isCommitting))
            .disabled(hold.isCommitting)
            Button {
                confirmReset = true
            } label: {
                Text("Reset all data")
                    .font(CreelFace.font(.body))
                    .foregroundStyle(CreelInk.ink)
                    .frame(maxWidth: .infinity, minHeight: CreelFace.tap, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(CreelPressStyle(enabled: true))
            .accessibilityLabel("Reset all data")
            if fills {
                HStack(alignment: .firstTextBaseline, spacing: CreelFace.space(2)) {
                    CreelFigureTile(
                        title: "Filed fish",
                        value: CreelFigure.count(filedCount)
                    )
                    CreelFigureTile(
                        title: "Today's stringer",
                        value: CreelFigure.count(hold.document.fish(on: hold.today).count)
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }

    private var filedCount: Int {
        hold.document.creels.values.reduce(0) { $0 + $1.count }
    }

    private var yardBinding: Binding<CreelYard> {
        Binding(
            get: { hold.document.yard },
            set: { next in
                Task { await hold.setYard(next) }
            }
        )
    }
}

private struct SettingsCard<Content: View>: View {
    var title: String
    var footer: String? = nil
    var fills: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: CreelFace.space(1)) {
            Text(title)
                .font(CreelFace.font(.caption).weight(.semibold))
                .foregroundStyle(CreelInk.muted)
                .lineLimit(1)
            content()
            if let footer {
                Text(footer)
                    .font(CreelFace.font(.caption))
                    .foregroundStyle(CreelInk.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(CreelFace.space(2))
        .frame(maxWidth: .infinity, maxHeight: fills ? .infinity : nil, alignment: .topLeading)
        .creelCardFill()
    }
}

#Preview {
    NavigationStack {
        CreelSettings(hold: .previewPopulated())
    }
}
