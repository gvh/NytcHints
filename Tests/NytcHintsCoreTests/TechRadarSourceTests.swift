import Foundation
import Testing
@testable import NytcHintsCore

struct TechRadarSourceTests {
    let source = TechRadarSource()
    let date = PuzzleDate(year: 2026, month: 10, day: 4)!

    @Test func buildsDatedURL() {
        #expect(source.url(for: date).absoluteString
            == "https://www.techradar.com/gaming/nyt-connections-today-answers-hints-4-october-2026")
        #expect(source.url(for: PuzzleDate(year: 2026, month: 3, day: 21)!).absoluteString
            .hasSuffix("-hints-21-march-2026"))
    }

    /// Markup mirrors the live page (2026-10-04), with made-up answer sections after the hints.
    static func fixture(published: String = "2026-10-03T23:00:00Z") -> String {
        """
        <meta property="article:published_time" content="\(published)">
        <h2 class="article-body__section" id="a"><span>NYT Connections today (game #1211) - today's words</span></h2>
        <p>SPOILER WORDS</p>
        <h2 class="article-body__section" id="b"><span>NYT Connections today (game #1211) - hint #1 - group hints</span></h2>
        <p>What are some clues for today's NYT Connections groups?</p>
        <ul id="x"><li><strong>YELLOW: </strong>A pile of things</li><li><strong>GREEN: </strong>Ping pong equipment</li><li><strong>BLUE: </strong>All rise</li><li><strong>PURPLE: </strong>Begin with a noiseless word</li></ul>
        <p>Need more clues?</p>
        <script>var data = {"header":"<ul><li>SPOILER</li></ul>"};</script>
        <h2 class="article-body__section" id="c"><span>NYT Connections today (game #1211) - hint #2 - group answers</span></h2>
        <ul><li><strong>YELLOW: </strong>SPOILER CATEGORY</li></ul>
        """
    }

    @Test func parsesOnlyHintSection() throws {
        let hints = try source.parse(Data(Self.fixture().utf8), for: date)
        #expect(hints == [
            Hint(color: .yellow, text: "A pile of things"),
            Hint(color: .green, text: "Ping pong equipment"),
            Hint(color: .blue, text: "All rise"),
            Hint(color: .purple, text: "Begin with a noiseless word"),
        ])
        #expect(!hints.contains { $0.text.contains("SPOILER") })
    }

    @Test func rejectsArticleFromAnotherYear() {
        let html = Self.fixture(published: "2025-10-03T23:00:00Z")
        #expect(throws: HintError.self) { try source.parse(Data(html.utf8), for: date) }
    }

    @Test func missingHintSectionThrows() {
        let html = "<meta property=\"article:published_time\" content=\"2026-10-03T23:00:00Z\"><h2><span>Other</span></h2>"
        #expect(throws: HintError.self) { try source.parse(Data(html.utf8), for: date) }
    }
}
