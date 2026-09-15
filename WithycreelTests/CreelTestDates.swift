import XCTest
@testable import Withycreel

enum CreelTestDates {
    static var calendar: Calendar {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        utc.locale = Locale(identifier: "en_US_POSIX")
        return utc
    }

    static func day(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        parts.hour = hour
        return calendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
    }
}

extension OpenClip {
    static func perch(length: Double = 30, weight: Double = 0.5) -> OpenClip {
        OpenClip(speciesID: CensusStock.perchID, lengthCentimetres: length, weightKilograms: weight)
    }
}
