import SwiftUI

/// Role: Stringer. The only custom-drawn surface: a withy line and glass fish clips. Limits and Settings stay stock.
struct GlassClipShell<Content: View>: View {
    var hangsOver: Bool
    var jawOpen: Bool
    @ViewBuilder var content: () -> Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let shift: CGFloat = hangsOver && !reduceMotion ? CreelFace.space(2) : 0
        ZStack(alignment: .topLeading) {
            WithyLine()
                .stroke(CreelInk.ink.opacity(0.28), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 12)
                .padding(.leading, CreelFace.space(2))
                .padding(.top, CreelFace.space(1))
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            VStack(spacing: 0) {
                ClipHook(jawOpen: jawOpen)
                    .stroke(CreelInk.ink.opacity(0.55), lineWidth: 2.5)
                    .frame(height: CreelFace.space(4))
                    .frame(maxWidth: .infinity)
                    .offset(x: shift)
                    .accessibilityHidden(true)
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: CreelFace.cardRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: CreelFace.cardRadius, style: .continuous)
                        .fill(CreelInk.surface.opacity(0.72))
                        .overlay {
                            Image(CreelArt.cardBackdrop)
                                .resizable()
                                .scaledToFit()
                                .opacity(0.18)
                                .padding(CreelFace.space(2))
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                                .clipped()
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                        }
                    content()
                        .padding(CreelFace.space(2))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                .clipShape(CreelPlate.cardShape)
                .overlay {
                    CreelPlate.cardShape.stroke(CreelInk.ink.opacity(0.12), lineWidth: 1)
                }
                .creelRaised()
                .offset(x: shift)
                .padding(.top, hangsOver ? CreelFace.space(2) : 0)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, CreelFace.space(2))
            .padding(.bottom, CreelFace.space(2))
            .padding(.top, CreelFace.space(1))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}

/// Role: Stringer. Willow withy that the clips hang from. Path only — not a second canvas.
struct WithyLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let x = rect.midX
        path.move(to: CGPoint(x: x, y: rect.minY))
        let steps = 6
        let height = rect.height
        for index in 1 ... steps {
            let y = rect.minY + height * CGFloat(index) / CGFloat(steps)
            let sway = (index.isMultiple(of: 2) ? 1.0 : -1.0) * 3.5
            path.addQuadCurve(
                to: CGPoint(x: x, y: y),
                control: CGPoint(x: x + sway, y: y - height / CGFloat(steps) / 2)
            )
        }
        return path
    }
}

/// Role: Stringer. Clip eye and jaw. Released opens the jaw; Keep and Over close it.
struct ClipHook: Shape {
    var jawOpen: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let eyeR = min(rect.height * 0.28, 11)
        let center = CGPoint(x: rect.midX, y: rect.minY + eyeR + 2)
        path.addEllipse(in: CGRect(x: center.x - eyeR, y: center.y - eyeR, width: eyeR * 2, height: eyeR * 2))
        let inner = eyeR * 0.45
        path.addEllipse(in: CGRect(x: center.x - inner, y: center.y - inner, width: inner * 2, height: inner * 2))
        let jawY = center.y + eyeR + 2
        let left = CGPoint(x: center.x - (jawOpen ? 16 : 8), y: rect.maxY - 2)
        let right = CGPoint(x: center.x + (jawOpen ? 16 : 8), y: rect.maxY - 2)
        path.move(to: CGPoint(x: center.x - 4, y: jawY))
        path.addLine(to: left)
        path.move(to: CGPoint(x: center.x + 4, y: jawY))
        path.addLine(to: right)
        return path
    }
}
