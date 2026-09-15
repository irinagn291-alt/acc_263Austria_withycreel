import XCTest
@testable import Withycreel

final class StringerFoldTests: XCTestCase {
    private let calendar = CreelTestDates.calendar
    private var today = CensusDay(rawValue: 2026_06_10)

    override func setUp() {
        today = CensusDay.from(CreelTestDates.day(2026, 6, 10), calendar: calendar)
    }

    func test_dayIsAFoldOverFish_openKeptReleasedOver() throws {
        var document = CreelDocument.empty
        XCTAssertEqual(document.stringer(on: today), .open(document.openClip))
        if case .open = StringerFold.reducing(open: document.openClip, fish: []) {
            // empty fold is Open
        } else {
            XCTFail("empty fold must be Open")
        }

        let kept = try document.keep(.perch(), on: today)
        document = kept.0
        if case .kept(let fish, let mark) = document.stringer(on: today) {
            XCTAssertEqual(fish.id, mark.fishID)
            XCTAssertEqual(fish.keepMark, mark)
            XCTAssertFalse(fish.hangsOver)
        } else {
            XCTFail("Keep must fold the day to Kept")
        }

        let released = try document.release(
            OpenClip(speciesID: CensusStock.breamID, lengthCentimetres: 34, weightKilograms: 1.2),
            on: today
        )
        document = released.0
        if case .released(let fish) = document.stringer(on: today) {
            XCTAssertNil(fish.keepMark)
            XCTAssertEqual(released.1.fishID, fish.id)
        } else {
            XCTFail("Release must fold the day to Released")
        }

        document.limits = [
            SpeciesLimit(id: CensusStock.perchID, name: "Perch", dailyBag: 1, seasonBag: 1),
            CensusStock.bream,
            CensusStock.pike,
            CensusStock.tench,
        ]
        let hangs = try document.keep(.perch(length: 31, weight: 0.6), on: today)
        document = hangs.0
        XCTAssertEqual(hangs.1, .overhang)
        if case .over(let fish, let mark, let over) = document.stringer(on: today) {
            XCTAssertEqual(fish.id, mark.fishID)
            XCTAssertEqual(over.fishID, fish.id)
            XCTAssertEqual(over.seasonYear, today.seasonYear)
        } else {
            XCTFail("Keep at remaining 0 must fold the day to Over")
        }

        let clips = document.clips(on: today)
        XCTAssertGreaterThanOrEqual(clips.count, 2)
        if case .open = clips.first {
            // open clip stays first
        } else {
            XCTFail("clips must start with Open")
        }
        XCTAssertTrue(clips.last?.hangsOver ?? false)
    }

    func test_primaryVerb_emptyPopulatedInvalid() throws {
        var document = CreelDocument.empty
        let day = today
        XCTAssertTrue(document.fish(on: day).isEmpty)
        XCTAssertTrue(document.keepIsEnabled)

        let populated = try document.keep(.perch(), on: day)
        document = populated.0
        XCTAssertEqual(document.fish(on: day).count, 1)
        XCTAssertNil(populated.1)

        XCTAssertThrowsError(try document.keep(.perch(length: -1, weight: 0.5), on: day)) { error in
            XCTAssertEqual(error as? CreelFault, .invalidLength)
        }
        XCTAssertThrowsError(try document.keep(.perch(length: 30, weight: 0), on: day)) { error in
            XCTAssertEqual(error as? CreelFault, .invalidWeight)
        }
        let unknown = OpenClip(
            speciesID: UUID(uuidString: "FFFFFFFF-0000-4000-8000-000000000099") ?? UUID(),
            lengthCentimetres: 30,
            weightKilograms: 0.5
        )
        XCTAssertThrowsError(try document.keep(unknown, on: day)) { error in
            XCTAssertEqual(error as? CreelFault, .unknownSpecies)
        }
        XCTAssertEqual(document.fish(on: day).count, 1)
    }

    func test_releaseSpendsNothing_peelRestoresKeepMarkRemaining() throws {
        var document = CreelDocument.empty
        let day = today
        let before = CreelCensus.remainingDaily(species: CensusStock.perchID, day: day, in: document)
        let released = try document.release(.perch(), on: day)
        document = released.0
        XCTAssertEqual(
            CreelCensus.remainingDaily(species: CensusStock.perchID, day: day, in: document),
            before
        )
        XCTAssertEqual(CreelCensus.dailyKept(species: CensusStock.perchID, day: day, in: document), 0)

        let kept = try document.keep(.perch(length: 31, weight: 0.55), on: day)
        document = kept.0
        XCTAssertEqual(
            CreelCensus.remainingDaily(species: CensusStock.perchID, day: day, in: document),
            before - 1
        )
        document = try document.peel(on: day)
        XCTAssertEqual(
            CreelCensus.remainingDaily(species: CensusStock.perchID, day: day, in: document),
            before
        )
        XCTAssertEqual(document.fish(on: day).count, 1)
        document = try document.peel(on: day)
        XCTAssertTrue(document.fish(on: day).isEmpty)
        XCTAssertThrowsError(try document.peel(on: day)) { error in
            XCTAssertEqual(error as? CreelFault, .emptyStringer)
        }
    }

    func test_overhangKeep_isTheTwist_keepIsNotRefused() throws {
        var document = CreelDocument.empty
        document.limits = [SpeciesLimit(id: CensusStock.perchID, name: "Perch", dailyBag: 1, seasonBag: 8)]
        let day = today
        document = try document.keep(.perch(), on: day).0
        let over = try document.keep(.perch(length: 40, weight: 0.9), on: day)
        document = over.0
        XCTAssertEqual(over.1, .overhang)
        XCTAssertEqual(document.fish(on: day).count, 2)
        XCTAssertTrue(document.keepIsEnabled)
        XCTAssertEqual(CreelCensus.remainingDaily(species: CensusStock.perchID, day: day, in: document), 0)
        XCTAssertTrue(CreelCensus.exceedsLimit(species: CensusStock.perchID, day: day, in: document))
    }
}
