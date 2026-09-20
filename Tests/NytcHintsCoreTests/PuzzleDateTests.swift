import Testing
@testable import NytcHintsCore

struct PuzzleDateTests {
    @Test func parsesValidDate() {
        let date = PuzzleDate(string: "2026-09-18")
        #expect(date == PuzzleDate(year: 2026, month: 9, day: 18))
        #expect(date?.description == "2026-09-18")
    }

    @Test(arguments: ["", "2026-9-18", "2026/09/18", "2026-13-01", "2026-02-30", "abcd-ef-gh", "2026-09-18x"])
    func rejectsInvalidDate(_ input: String) {
        #expect(PuzzleDate(string: input) == nil)
    }

    @Test func todayRoundTrips() {
        let today = PuzzleDate.today
        #expect(PuzzleDate(string: today.description) == today)
    }
}
