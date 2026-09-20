import Foundation

/// A calendar day identifying a Connections puzzle, formatted as YYYY-MM-DD.
public struct PuzzleDate: Equatable, Sendable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let day: Int

    public init?(year: Int, month: Int, day: Int) {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        guard Self.calendar.date(from: components).map({ Self.calendar.dateComponents([.year, .month, .day], from: $0) })
            .map({ $0.year == year && $0.month == month && $0.day == day }) == true
        else { return nil }
        self.year = year
        self.month = month
        self.day = day
    }

    /// Parses a strict `YYYY-MM-DD` string.
    public init?(string: String) {
        let parts = string.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2])
        else { return nil }
        self.init(year: year, month: month, day: day)
    }

    /// The local-time-zone day containing `date`.
    public init(date: Date) {
        let c = Self.calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: c.year!, month: c.month!, day: c.day!)!
    }

    /// Today's date in the local time zone.
    public static var today: PuzzleDate {
        PuzzleDate(date: Date())
    }

    /// Whole days from `other` to `self` (positive when `self` is later).
    public func days(since other: PuzzleDate) -> Int {
        let calendar = Self.calendar
        func day(_ d: PuzzleDate) -> Date {
            calendar.date(from: DateComponents(year: d.year, month: d.month, day: d.day))!
        }
        return calendar.dateComponents([.day], from: day(other), to: day(self)).day!
    }

    /// `YYYY-MM-DD`
    public var description: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }
}
