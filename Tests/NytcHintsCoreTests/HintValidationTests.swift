import Testing
@testable import NytcHintsCore

struct HintValidationTests {
    @Test func ordersYellowToPurple() throws {
        let hints: [Hint] = [
            Hint(color: .purple, text: "p"),
            Hint(color: .yellow, text: "y"),
            Hint(color: .blue, text: "b"),
            Hint(color: .green, text: "g"),
        ]
        #expect(try hints.validated().map(\.color) == [.yellow, .green, .blue, .purple])
    }

    @Test func missingColorThrows() {
        let hints: [Hint] = [
            Hint(color: .yellow, text: "y"),
            Hint(color: .green, text: "g"),
            Hint(color: .blue, text: "b"),
        ]
        #expect(throws: HintError.self) { try hints.validated() }
    }

    @Test func duplicateColorThrows() {
        let hints: [Hint] = [
            Hint(color: .yellow, text: "y"),
            Hint(color: .yellow, text: "y2"),
            Hint(color: .green, text: "g"),
            Hint(color: .blue, text: "b"),
            Hint(color: .purple, text: "p"),
        ]
        #expect(throws: HintError.self) { try hints.validated() }
    }

    @Test(arguments: [
        "BEND, FLEX, TWIST, TURN",
        "bend, flex, twist, turn",
        "Bend; Flex; Twist; Turn",
        "bend / flex / twist / turn",
        "bend • flex • twist • turn",
        "bend\nflex\ntwist\nturn",
        "bend, flex, twist and turn",
        "bend, flex, twist & turn",
        "bend, flex, twist, and turn",
        "BEND FLEX TWIST TURN",
        "Answers: BEND, FLEX, TWIST, TURN",
    ])
    func rejectsAnswerLists(_ text: String) {
        #expect(Hint.looksLikeAnswerList(text))
    }

    @Test(arguments: [
        "Bendable",
        "Down below",
        "He played Jean Valjean.",
        "Heart's & minds",
        "Rock, paper, scissors",
        "Salt and pepper, maybe",
        "Things an NBA or NFL fan says",
        "You might find these in court.",
    ])
    func allowsRealHints(_ text: String) {
        #expect(!Hint.looksLikeAnswerList(text))
    }

    @Test func answerListFailsValidationWithoutEchoingIt() {
        let hints: [Hint] = [
            Hint(color: .yellow, text: "y"),
            Hint(color: .green, text: "g"),
            Hint(color: .blue, text: "BEND, FLEX, TWIST, TURN"),
            Hint(color: .purple, text: "p"),
        ]
        do {
            _ = try hints.validated()
            Issue.record("expected validation to fail")
        } catch {
            #expect(!error.description.contains("BEND"))
        }
    }

    @Test func colorLabelsAreCaseInsensitive() {
        #expect(HintColor(label: " PURPLE ") == .purple)
        #expect(HintColor(label: "Orange") == nil)
    }
}
