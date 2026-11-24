import XCTest

/// Smoke tests for the hints screen. They use the live sites, so they accept either outcome of a
/// load (four cards, or a status message) and check that the screen stays usable in both.
final class NytcHintsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    /// Cards expose "<Color> hint: …" (or "<Color> hint withheld: …") as their accessibility label.
    private func card(_ color: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", "\(color) hint"))
            .firstMatch
    }

    private var status: XCUIElement { app.staticTexts["statusLabel"] }

    /// Waits for a load to finish: either the first card or the status message appears.
    private func waitForLoad(timeout: TimeInterval = 30, file: StaticString = #filePath, line: UInt = #line) {
        let finished = NSPredicate { [self] _, _ in card("Yellow").exists || status.exists }
        let expectation = XCTNSPredicateExpectation(predicate: finished, object: nil)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: timeout), .completed,
                       "Neither hint cards nor a status message appeared", file: file, line: line)
    }

    func testShowsTitleAndControls() {
        XCTAssertTrue(app.navigationBars["Connections Hints"].waitForExistence(timeout: 5))
        let sources = app.segmentedControls.firstMatch
        XCTAssertTrue(sources.exists)
        for name in ["CNET", "Mashable", "TechRadar"] {
            XCTAssertTrue(sources.buttons[name].exists, "Missing \(name) segment")
        }
        XCTAssertTrue(app.datePickers.firstMatch.exists)
    }

    func testCnetIsSelectedByDefault() {
        XCTAssertTrue(app.segmentedControls.buttons["CNET"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.segmentedControls.buttons["CNET"].isSelected)
    }

    func testLoadShowsFourCardsOrAStatusMessage() {
        waitForLoad()
        if status.exists {
            XCTAssertFalse(status.label.isEmpty)
            XCTAssertFalse(card("Yellow").exists, "Cards and an error shouldn't show together")
        } else {
            for color in ["Yellow", "Green", "Blue", "Purple"] {
                XCTAssertTrue(card(color).exists, "Missing \(color) card")
            }
        }
    }

    func testSwitchingSourcesSelectsEachSegmentAndReloads() {
        for name in ["Mashable", "TechRadar", "CNET"] {
            let segment = app.segmentedControls.buttons[name]
            XCTAssertTrue(segment.waitForExistence(timeout: 5))
            segment.tap()
            XCTAssertTrue(segment.isSelected, "\(name) should be selected after tapping")
            waitForLoad()
        }
    }
}
