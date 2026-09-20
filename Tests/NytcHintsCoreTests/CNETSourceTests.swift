import Foundation
import Testing
@testable import NytcHintsCore

struct CNETSourceTests {
    let source = CNETSource()
    let date = PuzzleDate(year: 2026, month: 9, day: 17)!

    @Test func buildsDatedURL() {
        #expect(source.url(for: date).absoluteString
            == "https://www.cnet.com/tech/gaming/todays-nyt-connections-hints-and-answers-for-sept-17")
        #expect(source.url(for: PuzzleDate(year: 2026, month: 3, day: 1)!).absoluteString.hasSuffix("-for-march-1"))
    }

    /// Markup mirrors the live page (2026-09-17), with made-up answer sections after the hints.
    static func fixture(published: String = "2026-09-16T20:23:40-04:00") -> String {
        """
        <meta property="article:published_time" content="\(published)" />
        <h2 class="wp-block-heading">Hints for today&#8217;s Connections groups</h2>
        <div class="zd-related-stories"><span>Today’s NYT Connections Hints and Answers for Sept. 16, #1193</span></div>
        <p>Here are four hints for the groupings in today’s Connections puzzle.</p>
        <p><strong>Yellow group hint:</strong>&nbsp;Stretches.</p>
        <p><strong>Green group hint:</strong>&nbsp;Not on the surface.</p>
        <p><strong>Blue group hint:</strong>&nbsp;He played <a href="https://en.wikipedia.org/wiki/Jean_Valjean">Jean Valjean</a>.</p>
        <p><strong>Purple group hint:</strong>&nbsp;Not hate.</p>
        <p><strong>Read more</strong>:&nbsp;<a href="#">Some article</a></p>
        <h2 class="wp-block-heading">Answers for today’s Connections groups</h2>
        <p><strong>Yellow group:</strong> SPOILER CATEGORY</p>
        <h2 class="wp-block-heading">What are today’s Connections answers?</h2>
        <p><strong>Yellow group hint:</strong> SPOILER</p>
        """
    }

    @Test func parsesOnlyHintSection() throws {
        let hints = try source.parse(Data(Self.fixture().utf8), for: date)
        #expect(hints == [
            Hint(color: .yellow, text: "Stretches."),
            Hint(color: .green, text: "Not on the surface."),
            Hint(color: .blue, text: "He played Jean Valjean."),
            Hint(color: .purple, text: "Not hate."),
        ])
        #expect(!hints.contains { $0.text.contains("SPOILER") })
    }

    @Test func rejectsArticleFromAnotherYear() {
        let html = Self.fixture(published: "2025-09-16T20:00:00-04:00")
        #expect(throws: HintError.self) { try source.parse(Data(html.utf8), for: date) }
    }

    @Test func missingPublishDateThrows() {
        let html = "<h2>Hints for today</h2><p><strong>Yellow group hint:</strong> x</p>"
        #expect(throws: HintError.self) { try source.parse(Data(html.utf8), for: date) }
    }
}
