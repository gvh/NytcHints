import Foundation

/// The four Connections groups, from easiest to hardest.
public enum HintColor: String, CaseIterable, Sendable {
    case yellow, green, blue, purple

    public init?(label: String) {
        self.init(rawValue: label.trimmingCharacters(in: .whitespaces).lowercased())
    }

    public var label: String { rawValue.capitalized }
}

/// A hint for one color group.
public struct Hint: Equatable, Sendable {
    public var color: HintColor
    public var text: String

    /// True when the real text was replaced because it looked like the answers.
    public var isWithheld: Bool

    public init(color: HintColor, text: String, isWithheld: Bool = false) {
        self.color = color
        self.text = text
        self.isWithheld = isWithheld
    }

    /// Shown in place of a hint that looked like an answer list.
    public static let withheldText = "Hidden: this hint looked like it gave away the answers."

    /// Parses a "Yellow: Bendable" line. `labelCorrections` maps a site's known misspellings
    /// (lowercased) to the intended color label.
    static func parse(colonLine line: String, labelCorrections: [String: String] = [:]) throws(HintError) -> Hint {
        guard let colon = line.firstIndex(of: ":") else { throw .parse("unrecognized hint line '\(line)'") }
        let label = line[..<colon].trimmingCharacters(in: .whitespaces)
        guard let color = HintColor(label: labelCorrections[label.lowercased()] ?? label) else {
            throw .parse("unrecognized hint line '\(line)'")
        }
        let text = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { throw .parse("empty \(color.label) hint") }
        return Hint(color: color, text: text)
    }

    /// True when `text` looks like the group's answer words rather than a hint:
    /// four or more items separated by commas, semicolons, slashes, bullets or line breaks
    /// ("BEND, FLEX, TWIST, TURN"), three items ending in "and"/"&" ("bend, flex, twist and turn"),
    /// or four or more all-caps words ("BEND FLEX TWIST TURN").
    public static func looksLikeAnswerList(_ text: String) -> Bool {
        let items = text
            .split(whereSeparator: { ",;/|•·\n".contains($0) })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        if items.count >= 4 { return true }
        if items.count == 3, items[2].contains(/(?i)^(and|&)\s|\s(and|&)\s/) { return true }

        let capsWords = text.split(whereSeparator: { !$0.isLetter }).filter { word in
            word.count >= 2 && word.allSatisfy(\.isUppercase)
        }
        return capsWords.count >= 4
    }
}

extension [Hint] {
    /// Ensures exactly one hint per color and returns them in yellow → purple order.
    ///
    /// A hint that looks like an answer list is replaced with a placeholder, so only that one is
    /// excluded and the rest still show. If every hint looks like an answer list, the page is
    /// probably the answers section, so the whole set is rejected.
    public func validated() throws(HintError) -> [Hint] {
        var byColor: [HintColor: Hint] = [:]
        for hint in self {
            guard byColor.updateValue(hint, forKey: hint.color) == nil else {
                throw .parse("duplicate \(hint.color.label) hint")
            }
        }
        let missing = HintColor.allCases.filter { byColor[$0] == nil }
        guard missing.isEmpty else {
            throw .parse("missing \(missing.map(\.label).joined(separator: ", ")) hint")
        }

        let ordered = HintColor.allCases.map { byColor[$0]! }
        let flagged = ordered.filter { Hint.looksLikeAnswerList($0.text) }
        guard flagged.count < ordered.count else { throw .answersDetected }
        // The original text is never kept, so a withheld answer can't reach the UI or output.
        return ordered.map { hint in
            flagged.contains(hint) ? Hint(color: hint.color, text: Hint.withheldText, isWithheld: true) : hint
        }
    }
}

/// The outcome of querying one hint source.
public struct HintSet: Sendable {
    public let sourceName: String
    public let result: Result<[Hint], HintError>

    public var isFailure: Bool {
        if case .failure = result { return true }
        return false
    }
}

public enum HintError: Error, Sendable, CustomStringConvertible {
    case invalidDate(String)
    case network(String)
    case badStatus(Int)
    case parse(String)
    /// Every hint looked like the answer words, so the whole set is withheld.
    case answersDetected

    public var description: String {
        switch self {
        case .invalidDate(let value): "invalid date: \(value)"
        case .network(let message): "network error: \(message)"
        case .badStatus(let code): "unexpected HTTP status \(code)"
        case .parse(let message): "could not parse response: \(message)"
        case .answersDetected: "every hint looks like a list of answers, so none are shown"
        }
    }
}
