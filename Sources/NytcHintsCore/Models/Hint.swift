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

    public init(color: HintColor, text: String) {
        self.color = color
        self.text = text
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
    /// Ensures exactly one hint per color, none of which looks like an answer list,
    /// and returns them in yellow → purple order.
    public func validated() throws(HintError) -> [Hint] {
        var byColor: [HintColor: Hint] = [:]
        for hint in self {
            // The text isn't included in the error so a leaked answer is never shown.
            guard !Hint.looksLikeAnswerList(hint.text) else {
                throw .parse("\(hint.color.label) hint looks like a list of answers, so none are shown")
            }
            guard byColor.updateValue(hint, forKey: hint.color) == nil else {
                throw .parse("duplicate \(hint.color.label) hint")
            }
        }
        let missing = HintColor.allCases.filter { byColor[$0] == nil }
        guard missing.isEmpty else {
            throw .parse("missing \(missing.map(\.label).joined(separator: ", ")) hint")
        }
        return HintColor.allCases.map { byColor[$0]! }
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
    case notImplemented

    public var description: String {
        switch self {
        case .invalidDate(let value): "invalid date: \(value)"
        case .network(let message): "network error: \(message)"
        case .badStatus(let code): "unexpected HTTP status \(code)"
        case .parse(let message): "could not parse response: \(message)"
        case .notImplemented: "not implemented yet"
        }
    }
}
