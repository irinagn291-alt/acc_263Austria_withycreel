import XCTest
@testable import Withycreel

final class WithycreelTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: WithycreelApp.self), "WithycreelApp")
        XCTAssertEqual(CreelHarbor.userAgent, "Withycreel/1.0 (iOS; +https://withycreel-bag.pro)")
    }

    func test_paletteAndSFProTokensMatchSpec() {
        XCTAssertEqual(CreelInk.Hex.background, "#F7F5FA")
        XCTAssertEqual(CreelInk.Hex.surface, "#FEFDFE")
        XCTAssertEqual(CreelInk.Hex.ink, "#231839")
        XCTAssertEqual(CreelInk.Hex.accent, "#5B2CBA")
        XCTAssertEqual(CreelInk.Hex.muted, "#6F6487")
        XCTAssertEqual(CreelFace.family, "SF Pro")
        XCTAssertEqual(CreelFace.Step.allCases.count, 6)
    }
}
