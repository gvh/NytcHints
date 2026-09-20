import ArgumentParser
import Foundation
import NytcHintsCore

extension SourceName: ExpressibleByArgument {}

@main
struct NytcHints: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "nytcHints",
        abstract: "Show hints (not answers) for the NY Times Connections puzzle."
    )

    @Argument(help: "Hint source.")
    var source: SourceName

    @Argument(help: "Puzzle date as YYYY-MM-DD. Defaults to today.")
    var date: String?

    func validate() throws {
        if let date, PuzzleDate(string: date) == nil {
            throw ValidationError("Invalid date '\(date)'. Expected YYYY-MM-DD.")
        }
    }

    func run() async throws {
        let puzzleDate = date.flatMap(PuzzleDate.init(string:)) ?? .today

        let results = await Fetcher().fetchAll([source.source], for: puzzleDate)
        HintPrinter().print(results, for: puzzleDate)

        if results.allSatisfy({ $0.isFailure }) {
            throw ExitCode.failure
        }
    }
}
