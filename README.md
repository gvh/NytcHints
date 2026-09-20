# nytcHints

A command-line tool that shows hints for the NY Times Connections puzzle, so you can skip a web search that might reveal the answers.

## Usage

```
./run.sh mash              # Mashable hints for today
./run.sh cnet 2026-09-18   # CNET hints for a specific date
```

## Adding a hint source

Each source is a URL plus a parser for the response.

1. Create a public type in `Sources/NytcHintsCore/Sources/` that conforms to `HintSource`:
   - `url(for:)` builds the page or API URL for a `PuzzleDate`.
   - `parse(_:for:)` turns the response `Data` into `[Hint]`. It must return hints only, never the answers.
2. Add a case for it to `SourceName` in `SourceRegistry.swift`.
3. Save a sample response as a test fixture and add a test for `parse`.

## iPad app

`iPad/NytcHintsiPad.xcodeproj` is a UIKit iPad app. It uses the `NytcHintsCore` library from this package, the same code the command-line tool uses, so a new or fixed source works in both.

Open it in Xcode, pick an iPad simulator, and run. To run on a real iPad, set your team under Signing & Capabilities first.

## Layout

- `Sources/NytcHintsCore/`: shared models, sources, parsing and fetching
- `Sources/nytcHints/`: command-line argument handling and terminal output
- `iPad/NytcHintsiPad/`: iPad UI
- `Tests/NytcHintsCoreTests/`: tests for the shared code
