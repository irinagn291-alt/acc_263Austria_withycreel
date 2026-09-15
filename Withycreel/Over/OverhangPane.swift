import SwiftUI

/// Role: Over. Twist screen. Overhang keep: Keep always files; a full stringer hangs Over and warns.
struct OverhangPane: View {
    var hold: CreelHold
    var onClose: (() -> Void)?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CreelFace.space(2)) {
                Image(CreelArt.twistHero)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 280)
                    .accessibilityHidden(true)
                Text("Overhang keep")
                    .font(CreelFace.font(.title))
                    .foregroundStyle(CreelInk.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Keep always files. When today's bag or this year's bag is already full, the fish still clips on and hangs past the last clip as Over. Remaining stays at zero. Keep is never refused.")
                    .font(CreelFace.font(.body))
                    .foregroundStyle(CreelInk.ink)
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
                .padding(CreelFace.space(2))
                .frame(maxWidth: .infinity, alignment: .leading)
                .creelCardFill()
                HStack(alignment: .top, spacing: CreelFace.space(1)) {
                    CreelRoleBadge(title: "Over", hangs: true)
                    Text("Colour is never the only signal. The hanging clip, the Over word, and this warning travel together.")
                        .font(CreelFace.font(.caption))
                        .foregroundStyle(CreelInk.ink)
                        .lineLimit(4)
                }
                Text("Release files without a keep mark and spends nothing. Peel last undoes only today's last fish and restores remaining when that fish had a keep.")
                    .font(CreelFace.font(.caption))
                    .foregroundStyle(CreelInk.muted)
                if let onClose {
                    CreelSoftKeep(title: "Back to the stringer", action: onClose)
                }
            }
            .padding(CreelFace.space(2))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .contentMargins(.bottom, CreelFace.space(2), for: .scrollContent)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CreelInk.background.ignoresSafeArea())
        .navigationTitle("Overhang keep")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(CreelInk.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            if let onClose {
                ToolbarItem(placement: .topBarTrailing) {
                    CreelGlyphButton(systemName: "xmark", label: "Close", action: onClose)
                }
            }
        }
    }
}

/// Role: Over. Home cue for overhang keep. Always on the open clip — not buried in Settings.
struct OverhangCue: View {
    var line: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: CreelFace.space(1)) {
                CreelRoleBadge(title: "Over", hangs: true)
                Text(line)
                    .font(CreelFace.font(.caption))
                    .foregroundStyle(CreelInk.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, CreelFace.space(1))
            .frame(maxWidth: .infinity, minHeight: CreelFace.tap, alignment: .leading)
            .background(CreelInk.surface.opacity(0.72))
            .clipShape(CreelPlate.chipShape)
            .contentShape(CreelPlate.chipShape)
        }
        .buttonStyle(CreelPressStyle(enabled: true))
        .accessibilityLabel(line)
        .accessibilityHint("Opens how overhang keep works")
    }
}

#Preview {
    NavigationStack {
        OverhangPane(hold: .previewPopulated())
    }
}
