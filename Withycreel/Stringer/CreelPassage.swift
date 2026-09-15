import SwiftUI

/// Role: Stringer. One-shot cover of four pages. Skip still writes metric defaults. Re-runnable from Settings.
struct CreelPassage: View {
    var hold: CreelHold
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @State private var yard: CreelYard

    private let last = 3

    init(hold: CreelHold) {
        self.hold = hold
        _yard = State(initialValue: hold.document.yard)
    }

    var body: some View {
        VStack(spacing: CreelFace.space(2)) {
            Group {
                switch page {
                case 0:
                    pageView(
                        image: CreelArt.onboarding1,
                        title: "Keep today's stringer",
                        line: "An angler clips a kept fish on today's stringer and the remaining bag for that species updates."
                    )
                case 1:
                    pageView(
                        image: CreelArt.onboarding2,
                        title: "Keep is the first tap",
                        line: "Species, length, and weight stay on the open clip. Tap Keep to file. Release files without spending remaining."
                    )
                case 2:
                    pageView(
                        image: CreelArt.onboarding3,
                        title: "A full bag still keeps",
                        line: "When remaining is already zero, Keep still files. That fish hangs Over past the last clip, and remaining stays at zero."
                    )
                default:
                    settingsPage
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(reduceMotion ? nil : CreelPlate.motion, value: page)
            CreelSoftKeep(
                title: page < last ? "Next" : "Open the stringer",
                busy: hold.isCommitting
            ) {
                if page < last {
                    page += 1
                } else {
                    Task { await hold.finishOnboarding(yard: yard) }
                }
            }
            Button {
                Task { await hold.finishOnboarding(yard: .metric) }
            } label: {
                Text("Skip")
                    .font(CreelFace.font(.body))
                    .foregroundStyle(CreelInk.muted)
                    .frame(maxWidth: .infinity, minHeight: CreelFace.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(CreelPressStyle(enabled: !hold.isCommitting))
            .disabled(hold.isCommitting)
            .accessibilityLabel("Skip")
        }
        .padding(CreelFace.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CreelInk.background.ignoresSafeArea())
    }

    private var settingsPage: some View {
        VStack(spacing: CreelFace.space(2)) {
            Image(CreelArt.twistHero)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityHidden(true)
            Text("Pick a display yard")
                .font(CreelFace.font(.title))
                .foregroundStyle(CreelInk.ink)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Text("The creel stores centimetres and kilograms. Skip still writes metric.")
                .font(CreelFace.font(.body))
                .foregroundStyle(CreelInk.ink)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            VStack(spacing: CreelFace.space(1)) {
                yardChoice(.metric, title: "Metric", detail: "Centimetres and kilograms")
                yardChoice(.imperial, title: "Imperial", detail: "Inches and pounds on screen")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func yardChoice(_ value: CreelYard, title: String, detail: String) -> some View {
        Button {
            yard = value
        } label: {
            HStack(spacing: CreelFace.space(1)) {
                if yard == value {
                    Image(systemName: "checkmark")
                        .font(CreelFace.font(.caption).weight(.semibold))
                        .foregroundStyle(CreelInk.ink)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .font(CreelFace.font(.body).weight(.semibold))
                        .foregroundStyle(CreelInk.ink)
                    Text(detail)
                        .font(CreelFace.font(.caption))
                        .foregroundStyle(CreelInk.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, CreelFace.space(2))
            .frame(maxWidth: .infinity, minHeight: CreelFace.tap, alignment: .leading)
            .creelChipFill(lit: yard == value)
            .creelRaised()
            .contentShape(CreelPlate.chipShape)
        }
        .buttonStyle(CreelPressStyle(enabled: true))
        .accessibilityLabel(title)
        .accessibilityValue(yard == value ? "Selected" : "Not selected")
    }

    private func pageView(image: String, title: String, line: String) -> some View {
        VStack(spacing: CreelFace.space(2)) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityHidden(true)
            Text(title)
                .font(CreelFace.font(.title))
                .foregroundStyle(CreelInk.ink)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Text(line)
                .font(CreelFace.font(.body))
                .foregroundStyle(CreelInk.ink)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    CreelPassage(hold: .previewEmpty())
}
