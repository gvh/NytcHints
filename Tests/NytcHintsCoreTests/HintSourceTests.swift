import Foundation
import Testing
@testable import NytcHintsCore

struct HintSourceTests {
    let date = PuzzleDate(year: 2026, month: 9, day: 18)!

    @Test func exampleSourceBuildsDatedURL() {
        #expect(ExampleSource().url(for: date).absoluteString.hasSuffix("/2026-09-18"))
    }

    @Test func exampleSourceParseIsNotImplemented() {
        #expect(throws: HintError.self) {
            try ExampleSource().parse(Data(), for: date)
        }
    }

    // Pattern for real sources: save a response under Tests/NytcHintsCoreTests/Fixtures/,
    // load it as Data, and assert on the hints returned by `parse`.
}
