import Foundation
import Testing
@testable import NytcHintsCore

struct MashableSourceTests {
    let source = MashableSource()
    let date = PuzzleDate(year: 2026, month: 9, day: 17)!

    @Test func buildsDatedURL() {
        let date = PuzzleDate(year: 2026, month: 9, day: 7)!
        #expect(source.url(for: date).absoluteString
            == "https://mashable.com/entertainment/nyt-connections-hint-answer-today-september-7-2026")
    }

    /// Markup mirrors the live page (2026-09-17), with made-up answer sections after the hints.
    static let fixture = """
    <h2>What is Connections?</h2><p>A word game.</p>
    <h2>Here's a hint for today's Connections categories</h2><p>Want a hint about the categories without being told the categories? Then give these a try:</p>
    <section aria-label="Newsletter Sign-Up"><div>Sign up</div></section>
    <ul><li><p>Yellow: <strong>Bendable</strong></p></li><li><p>Green: <strong>Down below</strong></p></li><li><p>Blue: <strong>Australian actor</strong></p></li><li><p>Purple: <strong>Heart&#39;s &amp; minds</strong></p></li></ul>
    <p><em>Want more tech news?</em></p>
    <h2>Here are today's Connections categories</h2>
    <ul><li><p>Yellow: <strong>SPOILER CATEGORY</strong></p></li></ul>
    <h2>What is the answer to Connections today</h2>
    <ul><li><p>SPOILER: ONE, TWO, THREE, FOUR</p></li></ul>
    """

    @Test func parsesOnlyHintSection() throws {
        let hints = try source.parse(Data(Self.fixture.utf8), for: date)
        #expect(hints == [
            Hint(color: .yellow, text: "Bendable"),
            Hint(color: .green, text: "Down below"),
            Hint(color: .blue, text: "Australian actor"),
            Hint(color: .purple, text: "Heart's & minds"),
        ])
        #expect(!hints.contains { $0.text.contains("SPOILER") })
    }

    @Test func unrecognizedColorThrows() {
        let html = "<h2>Here's a hint</h2><ul><li><p>Orange: <strong>Nope</strong></p></li></ul>"
        #expect(throws: HintError.self) { try source.parse(Data(html.utf8), for: date) }
    }

    @Test func missingHintSectionThrows() {
        let html = "<h2>What is the answer to Connections today</h2><ul><li>SPOILER</li></ul>"
        #expect(throws: HintError.self) { try source.parse(Data(html.utf8), for: date) }
    }

    @Test func hintSectionWithoutListThrows() {
        let html = "<h2>Here's a hint</h2><p>none</p><h2>Answers</h2><ul><li>SPOILER</li></ul>"
        #expect(throws: HintError.self) { try source.parse(Data(html.utf8), for: date) }
    }
}
