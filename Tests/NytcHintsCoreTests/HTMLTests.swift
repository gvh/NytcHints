import Testing
@testable import NytcHintsCore

struct HTMLTests {
    @Test func sectionMatchIsCaseInsensitiveAndStopsAtNextHeading() {
        let html = "<h2>HINTS</h2><p>keep</p><H2>Answers</H2><p>SPOILER</p>"
        let section = HTML.section(afterHeadingContaining: "hint", in: html).map(String.init)
        #expect(section == "<p>keep</p>")
    }

    @Test func sectionIgnoresInnerTagsInHeading() {
        let html = "<h2><span>Group <b>hints</b></span></h2><p>keep</p>"
        #expect(HTML.section(afterHeadingContaining: "group hints", in: html) != nil)
    }

    @Test func sectionMissingReturnsNil() {
        #expect(HTML.section(afterHeadingContaining: "hint", in: "<h2>Answers</h2>") == nil)
    }

    @Test(arguments: [
        #"<meta property="article:published_time" content="2026-09-17">"#,
        #"<meta content="2026-09-17" property="article:published_time">"#,
        "<meta property='article:published_time' content='2026-09-17'>",
        #"<meta data-content="nope" property="article:published_time" content="2026-09-17" />"#,
        #"<meta name="a>b" property="article:published_time" content="2026-09-17">"#,
    ])
    func readsMetaContent(_ html: String) {
        #expect(HTML.metaContent(property: "article:published_time", in: html) == "2026-09-17")
    }

    @Test func metaContentIgnoresOtherProperties() {
        let html = #"<meta property="og:title" content="x"><meta name="article:published_time" content="y">"#
        #expect(HTML.metaContent(property: "article:published_time", in: html) == nil)
    }

    @Test func textStripsTagsAndDecodesEntities() {
        #expect(HTML.text(from: "He played <a href=\"#\">Jean Valjean</a>.") == "He played Jean Valjean.")
        #expect(HTML.text(from: "Heart&#39;s &amp; minds&nbsp;&hellip;") == "Heart's & minds …")
    }
}
