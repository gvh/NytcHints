import Foundation

/// CNET's daily "Today's NYT Connections Hints and Answers" article.
///
/// The URL slug has the month, day and puzzle number (derived from the date), and the article's
/// publish date is checked against the requested date.
/// Parsing is confined to the "Hints for today's Connections groups" section.
public struct CNETSource: HintSource {
    public init() {}

    public let name = "CNET"

    private static let months = [
        "january", "february", "march", "april", "may", "june",
        "july", "august", "september", "october", "november", "december",
    ]

    /// Known puzzle number/date pair; puzzles are numbered one per day.
    private static let anchorDate = PuzzleDate(year: 2026, month: 10, day: 31)!
    private static let anchorNumber = 1238

    public func url(for date: PuzzleDate) -> URL {
        let month = Self.months[date.month - 1]
        let number = Self.anchorNumber + date.days(since: Self.anchorDate)
        return URL(string: "https://www.cnet.com/tech/gaming/todays-nyt-connections-hints-answers-\(month)-\(date.day)-\(number)/")!
    }

    public func parse(_ data: Data, for date: PuzzleDate) throws(HintError) -> [Hint] {
        let html = try HTML.string(from: data)
        try HTML.checkPublished(html, for: date)

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
