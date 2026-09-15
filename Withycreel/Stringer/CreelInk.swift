import SwiftUI

/// Role: Stringer. The only hex accessor. Named colours live in Assets; views never write a raw hex.
enum CreelInk {
    /// Orchid soft-focus tokens from SPEC.md section 7.1.
    enum Hex {
        static let background = "#F7F5FA"
        static let surface = "#FEFDFE"
        static let ink = "#231839"
        static let accent = "#5B2CBA"
        static let muted = "#6F6487"
    }

    static var background: Color { Color("background") }
    static var surface: Color { Color("surface") }
    static var ink: Color { Color("ink") }
    static var accent: Color { Color("creelAccent") }
    static var muted: Color { Color("muted") }
}
