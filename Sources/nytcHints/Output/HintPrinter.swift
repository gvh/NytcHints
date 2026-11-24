import Foundation
import NytcHintsCore

/// Prints hints grouped by source. Only hint text is shown, never answers.
struct HintPrinter {
    /// Color the group labels only when writing to a terminal, unless NO_COLOR is set (https://no-color.org).
    var useColor = isatty(STDOUT_FILENO) != 0 && ProcessInfo.processInfo.environment["NO_COLOR"].map(\.isEmpty) ?? true

    private let labelWidth = HintColor.allCases.map(\.label.count).max()!

    func print(_ sets: [HintSet], for date: PuzzleDate) {
        Swift.print("Connections hints for \(date)")

        for set in sets {
            Swift.print("\n== \(set.sourceName) ==")
            switch set.result {
            case .success(let hints):
                for hint in hints {
                    let label = hint.color.label.padding(toLength: labelWidth, withPad: " ", startingAt: 0)
                    Swift.print("  \(styled(label, hint.color))  \(hint.text)")
                }
            case .failure(let error):
                Swift.print("  unavailable: \(error)")
            }
        }
    }

    private func styled(_ text: String, _ color: HintColor) -> String {
        guard useColor else { return text }
        let code = switch color {
        case .yellow: "33"
        case .green: "32"
        case .blue: "34"
        case .purple: "35"
        }
        return "\u{1B}[1;\(code)m\(text)\u{1B}[0m"
    }
}
