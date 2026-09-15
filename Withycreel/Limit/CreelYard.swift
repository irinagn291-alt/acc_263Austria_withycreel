import Foundation

/// Role: Limit. Display yard only. The creel store is always centimetres and kilograms.
enum CreelYard: String, Equatable, Sendable {
    case metric
    case imperial
}

/// Role: Limit. Convert at the edge of display. Stored values keep SI precision.
enum CreelMeasure {
    static let centimetresPerInch = 2.54
    static let kilogramsPerPound = 0.453_592_37

    static func displayedLength(centimetres: Double, yard: CreelYard) -> Double {
        switch yard {
        case .metric: centimetres
        case .imperial: centimetres / centimetresPerInch
        }
    }

    static func displayedWeight(kilograms: Double, yard: CreelYard) -> Double {
        switch yard {
        case .metric: kilograms
        case .imperial: kilograms / kilogramsPerPound
        }
    }

    static func storedCentimetres(displayed: Double, yard: CreelYard) -> Double {
        switch yard {
        case .metric: displayed
        case .imperial: displayed * centimetresPerInch
        }
    }

    static func storedKilograms(displayed: Double, yard: CreelYard) -> Double {
        switch yard {
        case .metric: displayed
        case .imperial: displayed * kilogramsPerPound
        }
    }
}
