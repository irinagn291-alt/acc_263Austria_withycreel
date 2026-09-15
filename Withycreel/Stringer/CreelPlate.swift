import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Role: Stringer. Catalog names from section 13. Empty imagesets until assets.generate.
enum CreelArt {
    static let splash = "wyc_Splash"
    static let onboarding1 = "wyc_Onboarding1"
    static let onboarding2 = "wyc_Onboarding2"
    static let onboarding3 = "wyc_Onboarding3"
    static let emptyHome = "wyc_EmptyHome"
    static let emptyList = "wyc_EmptyList"
    static let cardBackdrop = "wyc_CardBackdrop"
    static let controlFace = "wyc_ControlFace"
    static let twistHero = "wyc_TwistHero"
    static let successMark = "wyc_SuccessMark"
    static let headerDecor = "wyc_HeaderDecor"
}

/// Role: Stringer. Motion, elevation, and shapes. Radii come from CreelFace only.
enum CreelPlate {
    static let motion = Animation.easeInOut(duration: 0.28)
    static let fade = Animation.easeInOut(duration: 0.22)
    static let liftRadius: CGFloat = 10
    static let liftY: CGFloat = 5

    static var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: CreelFace.cardRadius, style: .continuous)
    }

    static var chipShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: CreelFace.chipRadius, style: .continuous)
    }
}

/// Role: Stringer. Dismisses the decimal pad. Scroll and Done also resign.
enum CreelKeyboard {
    @MainActor
    static func dismiss() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
        #endif
    }
}

/// Role: Stringer. Pressed scale. Reduce Motion fades. Disabled is faded, not identical.
struct CreelPressStyle: ButtonStyle {
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        CreelPressBody(configuration: configuration, enabled: enabled)
    }
}

private struct CreelPressBody: View {
    var configuration: ButtonStyle.Configuration
    var enabled: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        configuration.label
            .scaleEffect(!reduceMotion && configuration.isPressed && enabled ? 0.97 : 1)
            .opacity(enabled ? (configuration.isPressed ? 0.88 : 1) : 0.45)
            .animation(reduceMotion ? CreelPlate.fade : CreelPlate.motion, value: configuration.isPressed)
    }
}

private struct CreelElevation: ViewModifier {
    func body(content: Content) -> some View {
        content.shadow(
            color: CreelInk.ink.opacity(0.10),
            radius: CreelPlate.liftRadius,
            x: 0,
            y: CreelPlate.liftY
        )
    }
}

extension View {
    func creelInk(_ step: CreelFace.Step) -> some View {
        font(CreelFace.font(step))
            .foregroundStyle(CreelInk.ink)
    }

    func creelRaised() -> some View {
        modifier(CreelElevation())
    }

    func creelCardFill() -> some View {
        background(CreelInk.surface)
            .clipShape(CreelPlate.cardShape)
            .creelRaised()
    }

    func creelChipFill(lit: Bool) -> some View {
        background(lit ? CreelInk.accent.opacity(0.16) : CreelInk.surface)
            .clipShape(CreelPlate.chipShape)
            .overlay {
                CreelPlate.chipShape.stroke(
                    lit ? CreelInk.accent : CreelInk.muted.opacity(0.35),
                    lineWidth: lit ? 2 : 1
                )
            }
    }
}

/// Role: Stringer. Soft-card Keep. Control face sits in the card; the fill is the target.
struct CreelSoftKeep: View {
    var title: String
    var detail: String? = nil
    var enabled: Bool = true
    var busy: Bool = false
    var hint: String? = nil
    var expands: Bool = false
    var action: () -> Void

    private var active: Bool { enabled && !busy }

    var body: some View {
        Button(action: action) {
            HStack(spacing: CreelFace.space(2)) {
                Image(CreelArt.controlFace)
                    .resizable()
                    .scaledToFit()
                    .frame(width: CreelFace.space(5), height: CreelFace.space(5))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .font(CreelFace.font(.title))
                        .foregroundStyle(CreelInk.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    if let detail {
                        Text(detail)
                            .font(CreelFace.font(.caption))
                            .foregroundStyle(CreelInk.ink)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, CreelFace.space(2))
            .padding(.vertical, CreelFace.space(1))
            .frame(maxWidth: .infinity, minHeight: CreelFace.space(7), maxHeight: expands ? .infinity : nil)
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
        .accessibilityLabel(detail.map { "\(title). \($0)" } ?? title)
        .accessibilityHint(hint ?? "")
    }
}

/// Role: Stringer. Secondary card control. Same radii and elevation as Keep.
struct CreelCardButton: View {
    var title: String
    var enabled: Bool = true
    var busy: Bool = false
    var action: () -> Void

    private var active: Bool { enabled && !busy }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(CreelFace.font(.callout).weight(.semibold))
                .foregroundStyle(CreelInk.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, CreelFace.space(2))
                .frame(maxWidth: .infinity, minHeight: CreelFace.tap)
                .background(CreelInk.surface)
                .clipShape(CreelPlate.cardShape)
                .overlay {
                    CreelPlate.cardShape.stroke(CreelInk.muted.opacity(0.35), lineWidth: 1)
                }
                .creelRaised()
                .contentShape(CreelPlate.cardShape)
        }
        .buttonStyle(CreelPressStyle(enabled: active))
        .disabled(!active)
        .accessibilityLabel(title)
    }
}

/// Role: Stringer. Recoverable fault with a retry control.
struct CreelBanner: View {
    var text: String
    var retryTitle: String = "Retry"
    var retry: () -> Void

    var body: some View {
        HStack(spacing: CreelFace.space(1)) {
            Text(text)
                .font(CreelFace.font(.callout))
                .foregroundStyle(CreelInk.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: retry) {
                Text(retryTitle)
                    .font(CreelFace.font(.callout).weight(.semibold))
                    .foregroundStyle(CreelInk.ink)
                    .frame(minWidth: CreelFace.tap, minHeight: CreelFace.tap)
                    .padding(.horizontal, CreelFace.space(1))
                    .background(CreelInk.surface)
                    .clipShape(CreelPlate.chipShape)
                    .contentShape(CreelPlate.chipShape)
            }
            .buttonStyle(CreelPressStyle(enabled: true))
            .accessibilityLabel(retryTitle)
        }
        .padding(.horizontal, CreelFace.space(2))
        .padding(.vertical, CreelFace.space(1))
        .frame(maxWidth: .infinity, minHeight: CreelFace.tap, alignment: .leading)
        .background(CreelInk.surface)
        .clipShape(CreelPlate.cardShape)
        .creelRaised()
    }
}

/// Role: Stringer. Icon control. SF Symbol is the affordance, not the brand.
struct CreelGlyphButton: View {
    var systemName: String
    var label: String
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(CreelFace.font(.body).weight(.semibold))
                .foregroundStyle(CreelInk.ink)
                .frame(width: CreelFace.tap, height: CreelFace.tap)
                .background(CreelInk.surface)
                .clipShape(CreelPlate.chipShape)
                .creelRaised()
                .contentShape(CreelPlate.chipShape)
        }
        .buttonStyle(CreelPressStyle(enabled: enabled))
        .disabled(!enabled)
        .accessibilityLabel(label)
    }
}

/// Role: Stringer. Pill chip. Colour is never the only selected signal.
struct CreelSpeciesChip: View {
    var title: String
    var selected: Bool

    var body: some View {
        HStack(spacing: CreelFace.space(1)) {
            if selected {
                Image(systemName: "checkmark")
                    .font(CreelFace.font(.caption).weight(.semibold))
                    .foregroundStyle(CreelInk.ink)
                    .accessibilityHidden(true)
            }
            Text(title)
                .font(CreelFace.font(.callout).weight(.semibold))
                .foregroundStyle(CreelInk.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, CreelFace.space(1))
        .frame(maxWidth: .infinity, minHeight: CreelFace.tap)
        .creelChipFill(lit: selected)
        .creelRaised()
        .contentShape(CreelPlate.chipShape)
    }
}

/// Role: Stringer. Role badge. Word plus shape — colour is never the only signal.
struct CreelRoleBadge: View {
    var title: String
    var hangs: Bool

    var body: some View {
        HStack(spacing: CreelFace.space(1)) {
            Image(systemName: hangs ? "arrow.down.to.line" : "circle.fill")
                .font(CreelFace.font(.caption).weight(.semibold))
                .foregroundStyle(CreelInk.ink)
                .accessibilityHidden(true)
            Text(title)
                .font(CreelFace.font(.caption).weight(.semibold))
                .foregroundStyle(CreelInk.ink)
                .lineLimit(1)
        }
        .padding(.horizontal, CreelFace.space(2))
        .frame(minHeight: CreelFace.space(4))
        .creelChipFill(lit: hangs)
        .fixedSize(horizontal: true, vertical: false)
    }
}

/// Role: Stringer. Full-page empty or error. Art, headline, line, bottom full-width CTA.
struct CreelVacancy: View {
    var image: String
    var headline: String
    var line: String
    var actionTitle: String
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        VStack(spacing: CreelFace.space(2)) {
            VStack(spacing: CreelFace.space(2)) {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 240, maxHeight: 240)
                    .accessibilityHidden(true)
                Text(headline)
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
            CreelSoftKeep(
                title: actionTitle,
                enabled: enabled,
                action: action
            )
        }
        .padding(.horizontal, CreelFace.space(2))
        .padding(.bottom, CreelFace.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CreelInk.background)
    }
}

/// Role: Stringer. Sheet header with a dismiss that always works.
struct CreelSheetBar: View {
    var title: String
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: CreelFace.space(1)) {
            Text(title)
                .creelInk(.title)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 0)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(CreelFace.font(.body).weight(.semibold))
                    .foregroundStyle(CreelInk.ink)
                    .frame(width: CreelFace.tap, height: CreelFace.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(CreelPressStyle(enabled: true))
            .accessibilityLabel("Close")
        }
        .frame(maxWidth: .infinity, minHeight: CreelFace.tap)
    }
}

/// Role: Stringer. Readout tile. Not a button — figures only.
struct CreelFigureTile: View {
    var title: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(CreelFace.font(.display))
                .foregroundStyle(CreelInk.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .layoutPriority(1)
            Text(title)
                .font(CreelFace.font(.caption))
                .foregroundStyle(CreelInk.muted)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// Role: Stringer. Remaining versus kept as a used surface. Fills the board, not a Spacer.
struct CreelBagCompare: View {
    var remainingTitle: String
    var remaining: Int
    var keptTitle: String
    var kept: Int
    var over: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: CreelFace.space(1)) {
            GeometryReader { geo in
                let ceiling = max(remaining, kept, 1)
                let remainingHeight = barHeight(remaining, ceiling: ceiling, in: geo.size.height)
                let keptHeight = barHeight(kept, ceiling: ceiling, in: geo.size.height)
                HStack(alignment: .bottom, spacing: CreelFace.space(2)) {
                    compareBar(height: remainingHeight, fill: CreelInk.accent)
                    compareBar(
                        height: keptHeight,
                        fill: over ? CreelInk.ink.opacity(0.45) : CreelInk.muted.opacity(0.28)
                    )
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                compareCaption(title: remainingTitle, value: remaining)
                compareCaption(title: keptTitle, value: kept)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(remainingTitle) \(CreelFigure.count(remaining)). \(keptTitle) \(CreelFigure.count(kept)).")
    }

    private func compareBar(height: CGFloat, fill: Color) -> some View {
        CreelPlate.chipShape
            .fill(fill)
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
    }

    private func compareCaption(title: String, value: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: CreelFace.space(1)) {
            Text(CreelFigure.count(value))
                .font(CreelFace.font(.figure))
                .foregroundStyle(CreelInk.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .layoutPriority(1)
            Text(title)
                .font(CreelFace.font(.caption))
                .foregroundStyle(CreelInk.muted)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func barHeight(_ value: Int, ceiling: Int, in height: CGFloat) -> CGFloat {
        let floor = value == 0 ? CreelFace.space(1) : CreelFace.space(2)
        let usable = max(floor, height)
        return max(floor, usable * CGFloat(value) / CGFloat(ceiling))
    }
}

/// Role: Limit. Labeled remaining-versus-kept track. Colour is never the only Over signal.
struct CreelBagTrack: View {
    var kept: Int
    var bag: Int
    var remaining: Int

    var body: some View {
        let ceiling = max(bag, kept, 1)
        let fraction = CGFloat(min(kept, ceiling)) / CGFloat(ceiling)
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: CreelFace.space(1)) {
                Text("Kept \(CreelFigure.count(kept)) of \(CreelFigure.count(max(bag, kept)))")
                    .font(CreelFace.font(.caption))
                    .foregroundStyle(CreelInk.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(remaining == 0 ? "Over when full" : "\(CreelFigure.count(remaining)) left")
                    .font(CreelFace.font(.caption).weight(.semibold))
                    .foregroundStyle(CreelInk.ink)
                    .lineLimit(1)
                    .layoutPriority(1)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    CreelPlate.chipShape.fill(CreelInk.muted.opacity(0.22))
                    CreelPlate.chipShape
                        .fill(CreelInk.accent)
                        .frame(width: kept == 0 ? 0 : max(CreelFace.space(1), geo.size.width * fraction))
                }
            }
            .frame(height: CreelFace.space(2))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Bag fill")
        .accessibilityValue("\(CreelFigure.count(kept)) of \(CreelFigure.count(max(bag, kept))), \(CreelFigure.count(remaining)) remaining")
    }
}
