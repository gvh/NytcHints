import Foundation

/// TechRadar's daily "NYT Connections hints and answers" article.
///
/// The URL is fully predictable from the date. The page has a "group hints" section (a
/// `YELLOW: …` bullet list) followed by sections that reveal the answers. Parsing is confined
/// to the first `<ul>` of the "group hints" section, which ends at the next `<h2`, so nothing
/// after it can leak into the output.
public struct TechRadarSource: HintSource {
    public init() {}

    public let name = "TechRadar"

    private static let months = [
        "january", "february", "march", "april", "may", "june",
        "july", "august", "september", "october", "november", "december",
    ]

    public func url(for date: PuzzleDate) -> URL {
        let month = Self.months[date.month - 1]
        return URL(string: "https://www.techradar.com/gaming/nyt-connections-today-answers-hints-\(date.day)-\(month)-\(date.year)")!
    }

    public func parse(_ data: Data, for date: PuzzleDate) throws(HintError) -> [Hint] {
        let html = try HTML.string(from: data)
        try HTML.checkPublished(html, for: date)

        guard let section = HTML.section(afterHeadingContaining: "group hints", in: html) else {
            throw .parse("hint section not found")
        }
        guard let list = section.firstMatch(of: /<ul[^>]*>(?<items>.*?)<\/ul>/.dotMatchesNewlines()) else {
            throw .parse("hint list not found")
        }

        var hints: [Hint] = []
        for match in list.items.matches(of: /<li[^>]*>(?<item>.*?)<\/li>/.dotMatchesNewlines()) {
            hints.append(try Self.hint(from: HTML.text(from: String(match.item))))
        }
        return hints
    }

    /// "YELLOW: A pile of things" → Hint(color: .yellow, text: "A pile of things")
    private static func hint(from line: String) throws(HintError) -> Hint {
        guard let colon = line.firstIndex(of: ":"),
              let color = HintColor(label: String(line[..<colon]))
        else { throw .parse("unrecognized hint line '\(line)'") }
        let text = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { throw .parse("empty \(color.label) hint") }
        return Hint(color: color, text: text)
    }
}
