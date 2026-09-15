import XCTest
@testable import Withycreel

@MainActor
final class CreelHoldTests: XCTestCase {
    private let calendar = CreelTestDates.calendar
    private var today: CensusDay {
        CensusDay.from(CreelTestDates.day(2026, 6, 10), calendar: calendar)
    }

    func test_keepAlwaysFilesThenWarnsWhenBagIsFull() async throws {
        var document = CreelDocument.empty.completingOnboarding()
        document.limits = [SpeciesLimit(id: CensusStock.perchID, name: "Perch", dailyBag: 1, seasonBag: 8)]
        let hold = makeHold(document)
        XCTAssertTrue(hold.keepIsEnabled)
        XCTAssertEqual(hold.jobTitle, "Keep today's stringer")
        XCTAssertTrue(hold.jobLine.contains("Keep"))
        XCTAssertTrue(hold.overhangLine.contains("Over"))

        await hold.keep(.perch())
        XCTAssertNil(hold.notice)
        XCTAssertEqual(hold.document.fish(on: today).count, 1)
        XCTAssertEqual(hold.remainingDaily, 0)
        XCTAssertTrue(hold.bagIsFull)
        XCTAssertTrue(hold.jobLine.contains("Over"))

        await hold.keep(.perch(length: 32, weight: 0.6))
        XCTAssertEqual(hold.notice, .overhang)
        XCTAssertEqual(hold.document.fish(on: today).count, 2)
        XCTAssertEqual(hold.remainingDaily, 0)
        XCTAssertTrue(hold.document.fish(on: today).last?.hangsOver ?? false)
        XCTAssertTrue(hold.keepIsEnabled)
        XCTAssertEqual(hold.commitTick, 2)
    }

    func test_releaseSpendsNothing_peelRestoresKeep() async throws {
        let hold = makeHold(CreelDocument.empty.completingOnboarding())
        let before = hold.remainingDaily
        await hold.release(.perch())
        XCTAssertEqual(hold.remainingDaily, before)
        XCTAssertEqual(hold.document.fish(on: today).count, 1)

        await hold.keep(.perch(length: 31, weight: 0.55))
        XCTAssertEqual(hold.remainingDaily, before - 1)
        await hold.peel()
        XCTAssertEqual(hold.remainingDaily, before)
        XCTAssertEqual(hold.document.fish(on: today).count, 1)
    }

    func test_monthlyWeightIsDerivedNotStored() async throws {
        let hold = makeHold(CreelDocument.empty.completingOnboarding())
        await hold.keep(.perch(length: 30, weight: 0.5))
        await hold.release(
            OpenClip(speciesID: CensusStock.breamID, lengthCentimetres: 34, weightKilograms: 1.1)
        )
        XCTAssertEqual(hold.monthlyKeptKilograms, 0.5, accuracy: 0.000_000_1)
        let encoded = try CreelCodec.encode(CreelCodec.committed(from: hold.document))
        let text = String(data: encoded, encoding: .utf8) ?? ""
        XCTAssertFalse(text.contains("remaining"))
        XCTAssertFalse(text.contains("monthly"))
    }

    func test_reviewKeysOpenThreeTabs() {
        XCTAssertEqual(tab(for: "today"), .catches)
        XCTAssertEqual(tab(for: "log"), .limits)
        XCTAssertEqual(tab(for: "goals"), .settings)
        XCTAssertNotEqual(tab(for: "today"), tab(for: "log"))
        XCTAssertNotEqual(tab(for: "log"), tab(for: "goals"))
    }

    func test_parseDecimalRejectsNegativeAndNonNumeric() {
        XCTAssertNil(CreelFigure.parseDecimal("-2"))
        XCTAssertNil(CreelFigure.parseDecimal("abc"))
        XCTAssertNil(CreelFigure.parseDecimal("0"))
        XCTAssertEqual(CreelFigure.parseDecimal("30"), 30)
        let separator = Locale.current.decimalSeparator ?? "."
        XCTAssertEqual(CreelFigure.parseDecimal("0\(separator)5"), 0.5)
        XCTAssertEqual(CreelFigure.sanitizeDecimal("12abc3"), "123")
        XCTAssertEqual(CreelHold.copy(.invalidLength), "Length must be greater than zero.")
    }

    private func tab(for key: String) -> StringerTab {
        let document = CreelDocument.empty.completingOnboarding()
        let hold = makeHold(document)
        hold.applyReview(arguments: ["-ReviewScreen", key])
        return hold.tab
    }

    private func makeHold(_ document: CreelDocument) -> CreelHold {
        CreelHold(
            store: StringerMemory(document: document),
            calendar: calendar,
            now: { CreelTestDates.day(2026, 6, 10) },
            document: document,
            shouldLoad: false
        )
    }
}