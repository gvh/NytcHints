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

    @Test func monthNames() {
        #expect(PuzzleDate(year: 2026, month: 1, day: 5)!.monthName == "january")
        #expect(PuzzleDate(year: 2026, month: 12, day: 5)!.monthName == "december")
    }

    @Test func daysSince() {
        let a = PuzzleDate(year: 2026, month: 10, day: 31)!
        #expect(a.days(since: PuzzleDate(year: 2026, month: 10, day: 29)!) == 2)
        #expect(a.days(since: PuzzleDate(year: 2026, month: 11, day: 2)!) == -2)
        #expect(a.days(since: PuzzleDate.firstPuzzle) == 1237)
    }

    @Test func todayRoundTrips() {
        let today = PuzzleDate.today
        #expect(PuzzleDate(string: today.description) == today)
    }
}
