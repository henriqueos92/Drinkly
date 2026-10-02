import XCTest
@testable import DrinklyCore

final class CalendarAndHistoryTests: XCTestCase {
    private let history = HistoryCalculator(calendar: TestCalendar.calendar)

    func testWeekStartsOnMonday() {
        // 01/10/2026 é uma quinta-feira.
        let week = history.week(containing: DayKey(year: 2026, month: 10, day: 1))
        XCTAssertEqual(week.first, DayKey(year: 2026, month: 9, day: 28))
        XCTAssertEqual(week.last, DayKey(year: 2026, month: 10, day: 4))
        XCTAssertEqual(week.count, 7)

        let sunday = history.week(containing: DayKey(year: 2026, month: 10, day: 4))
        XCTAssertEqual(sunday.first, DayKey(year: 2026, month: 9, day: 28))
    }

    func testLastSevenDays() {
        let days = history.lastDays(7, endingOn: DayKey(year: 2026, month: 10, day: 2))
        XCTAssertEqual(days.first, DayKey(year: 2026, month: 9, day: 26))
        XCTAssertEqual(days.count, 7)
    }

    func testMonthDaysUpToToday() {
        let today = DayKey(year: 2026, month: 10, day: 15)
        XCTAssertEqual(history.days(of: MonthKey(year: 2026, month: 10), upTo: today).count, 15)
        XCTAssertEqual(history.days(of: MonthKey(year: 2026, month: 9), upTo: today).count, 30)
    }

    func testDayKeyHandlesDSTAndYearBoundaries() {
        let newYear = DayKey(year: 2026, month: 12, day: 31).adding(days: 1, calendar: TestCalendar.calendar)
        XCTAssertEqual(newYear, DayKey(year: 2027, month: 1, day: 1))
        XCTAssertEqual(MonthKey(year: 2026, month: 12).adding(months: 1, calendar: TestCalendar.calendar), MonthKey(year: 2027, month: 1))
        XCTAssertEqual(DayKey(year: 2026, month: 10, day: 1).description, "2026-10-01")
    }

    func testGoalHistoryLookup() {
        var goals = GoalHistory()
        goals.setGoal(2000, from: DayKey(year: 2026, month: 9, day: 1))
        goals.setGoal(2500, from: DayKey(year: 2026, month: 9, day: 15))
        goals.setGoal(2600, from: DayKey(year: 2026, month: 9, day: 15)) // mesmo dia: substitui
        XCTAssertEqual(goals.changes.count, 2)
        XCTAssertEqual(goals.goal(for: DayKey(year: 2026, month: 8, day: 1)), 2000)
        XCTAssertEqual(goals.goal(for: DayKey(year: 2026, month: 9, day: 14)), 2000)
        XCTAssertEqual(goals.goal(for: DayKey(year: 2026, month: 9, day: 15)), 2600)
        XCTAssertEqual(goals.goal(for: DayKey(year: 2026, month: 12, day: 1)), 2600)
        XCTAssertNil(GoalHistory().goal(for: DayKey(year: 2026, month: 1, day: 1)))
    }

    func testDeepLinks() {
        XCTAssertEqual(DeepLink(url: DeepLink.quickAdd.url), .quickAdd)
        XCTAssertEqual(DeepLink(url: URL(string: "drinkly://dashboard")!), .dashboard)
        XCTAssertNil(DeepLink(url: URL(string: "https://example.com")!))
    }

    func testReminderTimeFormatting() {
        XCTAssertEqual(ReminderSettings.format(minuteOfDay: 8 * 60), "08:00")
        XCTAssertEqual(ReminderSettings.format(minuteOfDay: 22 * 60 + 30), "22:30")
    }
}
