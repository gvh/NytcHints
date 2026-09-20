import Foundation

/// A place hints come from: a URL for a given puzzle date, plus a parser for the response body.
///
/// Parsers must return hints only, never the answer words themselves.
public protocol HintSource: Sendable {
    /// Short display name, e.g. "Example Site".
    var name: String { get }

    /// The URL to fetch for the given puzzle date.
    func url(for date: PuzzleDate) -> URL

    /// Extracts hints from the raw response body. `date` lets a source confirm the page is for that puzzle.
    func parse(_ data: Data, for date: PuzzleDate) throws(HintError) -> [Hint]
}
