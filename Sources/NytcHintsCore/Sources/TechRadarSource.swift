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

    /// Misspelled labels seen on the site (the 2026-11-21 article spelled green "Geen").
    private static let labelCorrections = ["geen": "green"]

    public func url(for date: PuzzleDate) -> URL {
        URL(string: "https://www.techradar.com/gaming/nyt-connections-today-answers-hints-\(date.day)-\(date.monthName)-\(date.year)")!
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
            hints.append(try Hint.parse(colonLine: HTML.text(from: String(match.item)), labelCorrections: Self.labelCorrections))
        }
        return hints
    }
}
