import Foundation

/// Mashable's daily "NYT Connections hints and answers" article.
///
/// The page has a "Here's a hint for today's Connections categories" section followed by
/// sections that reveal the categories and answers. Parsing is confined to the hint section,
/// which ends at the next `<h2`, so nothing after it can leak into the output.
public struct MashableSource: HintSource {
    public init() {}

    public let name = "Mashable"

    private static let months = [
        "january", "february", "march", "april", "may", "june",
        "july", "august", "september", "october", "november", "december",
    ]

    public func url(for date: PuzzleDate) -> URL {
        let month = Self.months[date.month - 1]
        return URL(string: "https://mashable.com/entertainment/nyt-connections-hint-answer-today-\(month)-\(date.day)-\(date.year)")!
    }

    public func parse(_ data: Data, for date: PuzzleDate) throws(HintError) -> [Hint] {
        let html = try HTML.string(from: data)
        guard let section = HTML.section(afterHeadingContaining: "hint", in: html) else {
            throw .parse("hint section not found")
        }
        guard let list = section.firstMatch(of: /<ul>(?<items>.*?)<\/ul>/.dotMatchesNewlines()) else {
            throw .parse("hint list not found")
        }

        var hints: [Hint] = []
        for match in list.items.matches(of: /<li>(?<item>.*?)<\/li>/.dotMatchesNewlines()) {
            hints.append(try Self.hint(from: HTML.text(from: String(match.item))))
        }
        return hints
    }

    /// "Yellow: Bendable" → Hint(color: .yellow, text: "Bendable")
    private static func hint(from line: String) throws(HintError) -> Hint {
        guard let colon = line.firstIndex(of: ":"),
              let color = HintColor(label: String(line[..<colon]))
        else { throw .parse("unrecognized hint line '\(line)'") }
        let text = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { throw .parse("empty \(color.label) hint") }
        return Hint(color: color, text: text)
    }
}
