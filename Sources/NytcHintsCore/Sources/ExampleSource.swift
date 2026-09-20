import Foundation

/// Placeholder source showing the shape of a real one. Replace the URL and parser.
public struct ExampleSource: HintSource {
    public init() {}

    public let name = "Example"

    public func url(for date: PuzzleDate) -> URL {
        URL(string: "https://example.com/connections-hints/\(date)")!
    }

    public func parse(_ data: Data, for date: PuzzleDate) throws(HintError) -> [Hint] {
        throw .notImplemented
    }
}
