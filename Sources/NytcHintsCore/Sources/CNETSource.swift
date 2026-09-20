import Foundation

/// CNET's daily "Today's NYT Connections Hints and Answers" article.
///
/// The URL has no year and CNET redirects it to the matching article (whose real slug
/// includes the puzzle number), so the article's publish date is checked against the
/// requested date to make sure it isn't a different year's puzzle.
/// Parsing is confined to the "Hints for today's Connections groups" section.
public struct CNETSource: HintSource {
    public init() {}

    public let name = "CNET"

    /// CNET's slug month spellings (AP style).
    private static let months = [
        "jan", "feb", "march", "april", "may", "june",
        "july", "aug", "sept", "oct", "nov", "dec",
    ]

    public func url(for date: PuzzleDate) -> URL {
        let month = Self.months[date.month - 1]
        return URL(string: "https://www.cnet.com/tech/gaming/todays-nyt-connections-hints-and-answers-for-\(month)-\(date.day)")!
    }

    public func parse(_ data: Data, for date: PuzzleDate) throws(HintError) -> [Hint] {
        let html = try HTML.string(from: data)
        try Self.checkPublished(html, for: date)

        guard let section = HTML.section(afterHeadingContaining: "hint", in: html) else {
            throw .parse("hint section not found")
        }

        var hints: [Hint] = []
        for paragraph in section.matches(of: /<p>(?<body>.*?)<\/p>/.dotMatchesNewlines()) {
            if let hint = try Self.hint(from: HTML.text(from: String(paragraph.body))) {
                hints.append(hint)
            }
        }
        return hints
    }

    /// Articles go up the evening before the puzzle date, so allow a small window.
    private static func checkPublished(_ html: String, for date: PuzzleDate) throws(HintError) {
        guard let published = HTML.metaContent(property: "article:published_time", in: html),
              let day = PuzzleDate(string: String(published.prefix(10)))
        else { throw .parse("publish date not found") }
        guard (-1...3).contains(date.days(since: day)) else {
            throw .parse("article was published \(day), not for \(date)")
        }
    }

    /// "Yellow group hint: Stretches." → Hint(color: .yellow, text: "Stretches.")
    /// Paragraphs that aren't hint lines return nil.
    private static func hint(from line: String) throws(HintError) -> Hint? {
        guard let match = line.firstMatch(of: /^(?<color>\w+) group hint:\s*(?<text>.*)$/.ignoresCase()) else {
            return nil
        }
        guard let color = HintColor(label: String(match.color)) else {
            throw .parse("unrecognized hint color '\(match.color)'")
        }
        let text = match.text.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { throw .parse("empty \(color.label) hint") }
        return Hint(color: color, text: text)
    }
}
