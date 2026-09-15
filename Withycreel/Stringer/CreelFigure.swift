import Foundation

/// Role: Stringer. Locale figures for remaining, length, and weight. Round only at display.
enum CreelFigure {
    static func count(_ value: Int) -> String {
        countFormatter.string(from: NSNumber(value: value)) ?? "—"
    }

    static func decimal(_ value: Double, fraction: Int = 1) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = fraction
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? "—"
    }

    static func length(_ centimetres: Double, yard: CreelYard) -> String {
        let shown = CreelMeasure.displayedLength(centimetres: centimetres, yard: yard)
        let unit = yard == .metric ? "cm" : "in"
        let digits = yard == .metric ? 0 : 1
        return "\(decimal(shown, fraction: digits)) \(unit)"
    }

    static func weight(_ kilograms: Double, yard: CreelYard) -> String {
        let shown = CreelMeasure.displayedWeight(kilograms: kilograms, yard: yard)
        let unit = yard == .metric ? "kg" : "lb"
        return "\(decimal(shown, fraction: 2)) \(unit)"
    }

    static func lengthUnit(_ yard: CreelYard) -> String {
        yard == .metric ? "cm" : "in"
    }

    static func weightUnit(_ yard: CreelYard) -> String {
        yard == .metric ? "kg" : "lb"
    }

    static func parseDecimal(_ raw: String) -> Double? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let value = decimalFormatter.number(from: trimmed)?.doubleValue else { return nil }
        guard value.isFinite, value > 0 else { return nil }
        return value
    }

    static func parseCount(_ raw: String) -> Int? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let number = countFormatter.number(from: trimmed) else { return nil }
        let value = number.intValue
        guard value >= 0 else { return nil }
        return value
    }

    static func sanitizeDecimal(_ raw: String) -> String {
        let separator = Locale.current.decimalSeparator ?? "."
        var seenSeparator = false
        var out = ""
        for character in raw {
            if character.isNumber {
                out.append(character)
            } else if String(character) == separator || character == "." || character == "," {
                guard !seenSeparator else { continue }
                seenSeparator = true
                out.append(contentsOf: separator)
            }
        }
        return out
    }

    static func sanitizeCount(_ raw: String) -> String {
        raw.filter(\.isNumber)
    }

    static func day(_ stamp: CensusDay, calendar: Calendar) -> String {
        var parts = DateComponents()
        parts.year = stamp.rawValue / 10_000
        parts.month = (stamp.rawValue / 100) % 100
        parts.day = stamp.rawValue % 100
        let date = calendar.date(from: parts) ?? Date()
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale ?? .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: calendar.startOfDay(for: date))
    }

    private static var countFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        return formatter
    }

    private static var decimalFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }
}
