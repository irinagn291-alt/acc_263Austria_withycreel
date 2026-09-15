import Foundation

/// Role: Stringer. Tab chrome. Catches holds the stringer; Limits and Settings are siblings. No Game tab.
enum StringerTab: String, Hashable, Sendable, CaseIterable {
    case catches
    case limits
    case settings

    var title: String {
        switch self {
        case .catches: "Catches"
        case .limits: "Limits"
        case .settings: "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .catches: "link"
        case .limits: "square.stack"
        case .settings: "gearshape"
        }
    }
}

/// Role: Stringer. Launch keys for live shots. today, log, and goals open three different screens.
enum ReviewPane: String, Equatable, Sendable {
    case today
    case log
    case goals

    var tab: StringerTab {
        switch self {
        case .today: .catches
        case .log: .limits
        case .goals: .settings
        }
    }
}

/// Role: Stringer. Reads `-ReviewScreen today|log|goals` once, only after onboarding. Never hosts a View.
enum StringerLaunch {
    static func consume(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        onboardingComplete: Bool,
        consumed: inout Bool
    ) -> ReviewPane? {
        guard onboardingComplete, !consumed else { return nil }
        consumed = true
        guard let index = arguments.firstIndex(of: "-ReviewScreen") else { return nil }
        let next = arguments.index(after: index)
        guard arguments.indices.contains(next) else { return nil }
        return ReviewPane(rawValue: arguments[next])
    }
}
