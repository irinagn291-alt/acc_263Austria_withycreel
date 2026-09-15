import XCTest
@testable import Withycreel

final class StringerLaunchTests: XCTestCase {
    func test_readsOnceAfterOnboarding() {
        var consumed = false
        XCTAssertNil(
            StringerLaunch.consume(
                arguments: ["-ReviewScreen", "log"],
                onboardingComplete: false,
                consumed: &consumed
            )
        )
        XCTAssertFalse(consumed)

        let first = StringerLaunch.consume(
            arguments: ["app", "-ReviewScreen", "log"],
            onboardingComplete: true,
            consumed: &consumed
        )
        XCTAssertEqual(first, .log)
        XCTAssertEqual(first?.tab, .limits)
        XCTAssertTrue(consumed)
        XCTAssertNil(
            StringerLaunch.consume(
                arguments: ["-ReviewScreen", "goals"],
                onboardingComplete: true,
                consumed: &consumed
            )
        )
    }

    func test_threeKeysAreDistinctScreens() {
        XCTAssertEqual(ReviewPane.today.rawValue, "today")
        XCTAssertEqual(ReviewPane.log.rawValue, "log")
        XCTAssertEqual(ReviewPane.goals.rawValue, "goals")
        XCTAssertNotEqual(ReviewPane.today, ReviewPane.log)
        XCTAssertNotEqual(ReviewPane.log, ReviewPane.goals)
        XCTAssertNotEqual(ReviewPane.today, ReviewPane.goals)
        XCTAssertEqual(ReviewPane.today.tab, .catches)
        XCTAssertEqual(ReviewPane.log.tab, .limits)
        XCTAssertEqual(ReviewPane.goals.tab, .settings)
        XCTAssertNotEqual(ReviewPane.today.tab, ReviewPane.log.tab)
        XCTAssertNotEqual(ReviewPane.log.tab, ReviewPane.goals.tab)
        XCTAssertNotEqual(ReviewPane.today.tab, ReviewPane.goals.tab)
        XCTAssertEqual(StringerTab.allCases.count, 3)
        XCTAssertFalse(StringerTab.allCases.map(\.rawValue).contains("game"))

        var consumed = false
        XCTAssertEqual(
            StringerLaunch.consume(
                arguments: ["-ReviewScreen", "today"],
                onboardingComplete: true,
                consumed: &consumed
            ),
            .today
        )
        consumed = false
        XCTAssertEqual(
            StringerLaunch.consume(
                arguments: ["-ReviewScreen", "goals"],
                onboardingComplete: true,
                consumed: &consumed
            ),
            .goals
        )
    }

    func test_unknownKeyIsIgnored() {
        var consumed = false
        XCTAssertNil(
            StringerLaunch.consume(
                arguments: ["-ReviewScreen", "aura"],
                onboardingComplete: true,
                consumed: &consumed
            )
        )
        XCTAssertTrue(consumed)
    }
}
