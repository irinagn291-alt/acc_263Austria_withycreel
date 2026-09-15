import XCTest
@testable import Withycreel

/// Family catch_log: always save the catch, then warn if day/season count > SpeciesLimit.
/// Season = calendar year of the Int YYYYMMDD day key. Store SI (kg, cm).
final class FamilyInvariantTests: XCTestCase {
    private let calendar = CreelTestDates.calendar

    func test_alwaysSaveThenWarnWhenCountExceedsSpeciesLimit() throws {
        var document = CreelDocument.empty
        document.limits = [
            SpeciesLimit(id: CensusStock.perchID, name: "Perch", dailyBag: 2, seasonBag: 10),
        ]
        let day = CensusDay.from(CreelTestDates.day(2026, 6, 10), calendar: calendar)

        let first = try document.keep(.perch(), on: day)
        document = first.0
        XCTAssertNil(first.1)
        XCTAssertEqual(document.fish(on: day).count, 1)
        XCTAssertEqual(CreelCensus.dailyKept(species: CensusStock.perchID, day: day, in: document), 1)
        XCTAssertFalse(CreelCensus.exceedsLimit(species: CensusStock.perchID, day: day, in: document))

        let second = try document.keep(.perch(length: 31, weight: 0.6), on: day)
        document = second.0
        XCTAssertNil(second.1)
        XCTAssertEqual(CreelCensus.remainingDaily(species: CensusStock.perchID, day: day, in: document), 0)
        XCTAssertFalse(CreelCensus.exceedsLimit(species: CensusStock.perchID, day: day, in: document))

        let third = try document.keep(.perch(length: 33, weight: 0.7), on: day)
        document = third.0
        XCTAssertEqual(third.1, .overhang)
        XCTAssertEqual(document.fish(on: day).count, 3)
        XCTAssertEqual(CreelCensus.dailyKept(species: CensusStock.perchID, day: day, in: document), 3)
        XCTAssertTrue(CreelCensus.exceedsLimit(species: CensusStock.perchID, day: day, in: document))
        XCTAssertEqual(CreelCensus.remainingDaily(species: CensusStock.perchID, day: day, in: document), 0)
        XCTAssertTrue(document.fish(on: day).last?.hangsOver ?? false)
        XCTAssertTrue(document.keepIsEnabled)
    }

    func test_seasonIsCalendarYearOfYYYYMMDDDayKey() throws {
        var document = CreelDocument.empty
        document.limits = [
            SpeciesLimit(id: CensusStock.perchID, name: "Perch", dailyBag: 8, seasonBag: 1),
        ]
        let late = CensusDay.from(CreelTestDates.day(2025, 12, 31), calendar: calendar)
        let early = CensusDay.from(CreelTestDates.day(2026, 1, 1), calendar: calendar)
        XCTAssertEqual(late.rawValue, 2025_12_31)
        XCTAssertEqual(late.seasonYear, 2025)
        XCTAssertEqual(early.rawValue, 2026_01_01)
        XCTAssertEqual(early.seasonYear, 2026)

        let first = try document.keep(.perch(), on: late)
        document = first.0
        XCTAssertNil(first.1)
        XCTAssertEqual(CreelCensus.seasonKept(species: CensusStock.perchID, year: 2025, in: document), 1)
        XCTAssertEqual(CreelCensus.seasonKept(species: CensusStock.perchID, year: 2026, in: document), 0)

        let second = try document.keep(.perch(length: 31, weight: 0.55), on: early)
        document = second.0
        XCTAssertNil(second.1)
        XCTAssertEqual(CreelCensus.seasonKept(species: CensusStock.perchID, year: 2025, in: document), 1)
        XCTAssertEqual(CreelCensus.seasonKept(species: CensusStock.perchID, year: 2026, in: document), 1)
        XCTAssertEqual(CreelCensus.remainingSeason(species: CensusStock.perchID, year: 2025, in: document), 0)
        XCTAssertEqual(CreelCensus.remainingSeason(species: CensusStock.perchID, year: 2026, in: document), 0)

        let overhangYear = try document.keep(.perch(length: 32, weight: 0.6), on: early)
        document = overhangYear.0
        XCTAssertEqual(overhangYear.1, .overhang)
        XCTAssertTrue(CreelCensus.exceedsLimit(species: CensusStock.perchID, day: early, in: document))
        XCTAssertEqual(CreelCensus.seasonKept(species: CensusStock.perchID, year: 2026, in: document), 2)
        XCTAssertEqual(CreelCensus.remainingSeason(species: CensusStock.perchID, year: 2026, in: document), 0)
    }

    func test_storeIsSIKilogramsAndCentimetres() throws {
        var document = CreelDocument.empty
        let day = CensusDay.from(CreelTestDates.day(2026, 6, 10), calendar: calendar)
        let filing = try document.keep(.perch(length: 30.5, weight: 0.75), on: day)
        document = filing.0
        document = document.settingYard(.imperial)
        let fish = try XCTUnwrap(document.fish(on: day).first)
        XCTAssertEqual(fish.lengthCentimetres, 30.5, accuracy: 0.000_000_1)
        XCTAssertEqual(fish.weightKilograms, 0.75, accuracy: 0.000_000_1)
        XCTAssertEqual(CreelMeasure.displayedLength(centimetres: 30.5, yard: .imperial), 30.5 / 2.54, accuracy: 0.000_000_1)
        XCTAssertEqual(
            CreelMeasure.storedCentimetres(displayed: 12, yard: .imperial),
            12 * 2.54,
            accuracy: 0.000_000_1
        )
        XCTAssertEqual(document.yard, .imperial)
        XCTAssertEqual(fish.lengthCentimetres, 30.5, accuracy: 0.000_000_1)
        XCTAssertEqual(fish.weightKilograms, 0.75, accuracy: 0.000_000_1)
    }

    func test_remainingNeverGoesNegative() throws {
        var document = CreelDocument.empty
        document.limits = [
            SpeciesLimit(id: CensusStock.perchID, name: "Perch", dailyBag: 0, seasonBag: 0),
        ]
        let day = CensusDay.from(CreelTestDates.day(2026, 6, 10), calendar: calendar)
        for _ in 0 ..< 4 {
            let filing = try document.keep(.perch(), on: day)
            document = filing.0
            XCTAssertEqual(filing.1, .overhang)
            XCTAssertGreaterThanOrEqual(
                CreelCensus.remainingDaily(species: CensusStock.perchID, day: day, in: document),
                0
            )
            XCTAssertGreaterThanOrEqual(
                CreelCensus.remainingSeason(species: CensusStock.perchID, year: day.seasonYear, in: document),
                0
            )
        }
        XCTAssertEqual(document.fish(on: day).count, 4)
        XCTAssertEqual(CreelCensus.remainingDaily(species: CensusStock.perchID, day: day, in: document), 0)
    }
}
