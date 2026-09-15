import SwiftUI

/// Role: Stringer. SF Pro via Font.system. Six Dynamic Type steps. No Font.custom and no fixedSize.
enum CreelFace {
    static let family = "SF Pro"
    static let unit: CGFloat = 8
    static let tap: CGFloat = 44
    static let cardRadius: CGFloat = 22
    static let chipRadius: CGFloat = 14

    enum Step: CaseIterable {
        case display
        case title
        case body
        case callout
        case caption
        case figure
    }

    static func font(_ step: Step) -> Font {
        switch step {
        case .display:
            .system(.largeTitle, design: .default).weight(.semibold).monospacedDigit()
        case .title:
            .system(.title2, design: .default).weight(.semibold)
        case .body:
            .system(.body, design: .default)
        case .callout:
            .system(.callout, design: .default)
        case .caption:
            .system(.caption, design: .default)
        case .figure:
            .system(.title3, design: .default).weight(.semibold).monospacedDigit()
        }
    }

    static func space(_ steps: Int) -> CGFloat {
        unit * CGFloat(steps)
    }
}
