import XCTest
@testable import DrinklyCore

final class ReminderPlannerTests: XCTestCase {
    private let calendar = TestCalendar.calendar
    private let planner = ReminderPlanner()

    private func context(now: Date, lastDrink: Date?, consumed: Int = 500, goal: Int = 2500,
                         settings: ReminderSettings = ReminderSettings(intervalMinutes: 90)) -> ReminderContext {
        ReminderContext(now: now, lastDrinkToday: lastDrink, consumedTodayMl: consumed, goalMl: goal, settings: settings)
    }

    func testNoRemindersBeforeFirstDrinkOfTheDay() {
        let now = TestCalendar.date(2026, 10, 1, 8, 0)
        XCTAssertTrue(planner.plan(for: context(now: now, lastDrink: nil, consumed: 0), calendar: calendar).isEmpty)
    }

    func testDrinkFromYesterdayDoesNotActivateReminders() {
        let now = TestCalendar.date(2026, 10, 1, 8, 0)
        let yesterday = TestCalendar.date(2026, 9, 30, 21, 0)
        XCTAssertTrue(planner.plan(for: context(now: now, lastDrink: yesterday), calendar: calendar).isEmpty)
    }

    func testFirstDrinkActivatesPeriodicReminders() {
        let drink = TestCalendar.date(2026, 10, 1, 8, 30)
        let plan = planner.plan(for: context(now: drink, lastDrink: drink), calendar: calendar)
        let times = plan.prefix(4).map { calendar.dateComponents([.hour, .minute], from: $0.fireDate) }
        XCTAssertEqual(times.map { "\($0.hour!):\($0.minute!)" }, ["10:0", "11:30", "13:0", "14:30"])
    }

    func testRespectsWindowEnd() {
        let drink = TestCalendar.date(2026, 10, 1, 8, 30)
        let plan = planner.plan(for: context(now: drink, lastDrink: drink), calendar: calendar)
        let last = try! XCTUnwrap(plan.last)
        XCTAssertLessThanOrEqual(last.fireDate, TestCalendar.date(2026, 10, 1, 22, 0))
        XCTAssertEqual(plan.count, 9) // 10:00 ... 22:00 a cada 90 min
        XCTAssertTrue(plan.allSatisfy { calendar.isDate($0.fireDate, inSameDayAs: drink) })
    }

    func testDrinkBeforeWindowStartsAtWindowStart() {
        let drink = TestCalendar.date(2026, 10, 1, 6, 0)
        let settings = ReminderSettings(intervalMinutes: 60, startMinuteOfDay: 8 * 60, endMinuteOfDay: 10 * 60)
        let plan = planner.plan(for: context(now: drink, lastDrink: drink, settings: settings), calendar: calendar)
        XCTAssertEqual(plan.map(\.fireDate), [
            TestCalendar.date(2026, 10, 1, 8, 0),
            TestCalendar.date(2026, 10, 1, 9, 0),
            TestCalendar.date(2026, 10, 1, 10, 0)
        ])
    }

    func testDrinkAfterWindowSchedulesNothing() {
        let drink = TestCalendar.date(2026, 10, 1, 22, 30)
        XCTAssertTrue(planner.plan(for: context(now: drink, lastDrink: drink), calendar: calendar).isEmpty)
    }

    func testNewDrinkPushesNextReminder() {
        // Bebeu às 14:00: o próximo lembrete é 14:00 + intervalo, nunca antes.
        let drink = TestCalendar.date(2026, 10, 1, 14, 0)
        let next = planner.nextReminderDate(for: context(now: drink, lastDrink: drink), calendar: calendar)
        XCTAssertEqual(next, TestCalendar.date(2026, 10, 1, 15, 30))
    }

    func testReschedulingLaterKeepsCadenceAndSkipsPast() {
        let drink = TestCalendar.date(2026, 10, 1, 8, 30)
        let now = TestCalendar.date(2026, 10, 1, 12, 0)
        let next = planner.nextReminderDate(for: context(now: now, lastDrink: drink), calendar: calendar)
        XCTAssertEqual(next, TestCalendar.date(2026, 10, 1, 13, 0))
    }

    func testConfigurableIntervals() {
        let drink = TestCalendar.date(2026, 10, 1, 9, 0)
        for minutes in [30, 60, 90, 120, 45] {
            let settings = ReminderSettings(intervalMinutes: minutes)
            let next = planner.nextReminderDate(for: context(now: drink, lastDrink: drink, settings: settings), calendar: calendar)
            XCTAssertEqual(next, drink.addingTimeInterval(TimeInterval(minutes * 60)))
        }
    }

    func testDisabledOrInvalidWindowProducesNothing() {
        let drink = TestCalendar.date(2026, 10, 1, 9, 0)
        let disabled = ReminderSettings(isEnabled: false)
        XCTAssertTrue(planner.plan(for: context(now: drink, lastDrink: drink, settings: disabled), calendar: calendar).isEmpty)
        let inverted = ReminderSettings(startMinuteOfDay: 22 * 60, endMinuteOfDay: 8 * 60)
        XCTAssertTrue(planner.plan(for: context(now: drink, lastDrink: drink, settings: inverted), calendar: calendar).isEmpty)
    }

    func testStopsWhenGoalReachedIfConfigured() {
        let drink = TestCalendar.date(2026, 10, 1, 9, 0)
        XCTAssertTrue(planner.plan(for: context(now: drink, lastDrink: drink, consumed: 2500), calendar: calendar).isEmpty)
        let keepGoing = ReminderSettings(stopWhenGoalReached: false)
        XCTAssertFalse(planner.plan(for: context(now: drink, lastDrink: drink, consumed: 2500, settings: keepGoing), calendar: calendar).isEmpty)
    }

    func testRespectsSystemLimit() {
        let drink = TestCalendar.date(2026, 10, 1, 0, 5)
        let settings = ReminderSettings(intervalMinutes: 15, startMinuteOfDay: 0, endMinuteOfDay: 24 * 60)
        let plan = ReminderPlanner(maxReminders: 10).plan(for: context(now: drink, lastDrink: drink, settings: settings), calendar: calendar)
        XCTAssertEqual(plan.count, 10)
    }

    func testMessagesAreContextualAndNotRepeatedBackToBack() {
        let drink = TestCalendar.date(2026, 10, 1, 8, 0)
        let plan = planner.plan(for: context(now: drink, lastDrink: drink, consumed: 1500, goal: 2200,
                                             settings: ReminderSettings(intervalMinutes: 60)), calendar: calendar)
        XCTAssertGreaterThan(plan.count, 3)
        for (a, b) in zip(plan, plan.dropFirst()) {
            XCTAssertNotEqual(a.body, b.body)
        }
        let bodies = Set(plan.map(\.body))
        XCTAssertTrue(bodies.contains("Você já bebeu 1.500 ml hoje."))
        XCTAssertTrue(bodies.contains("Faltam 700 ml para sua meta."))
    }

    func testAlmostThereMessage() {
        let composer = ReminderMessageComposer()
        let list = composer.candidates(progress: HydrationProgress(consumedMl: 2100, goalMl: 2500), minutesSinceLastDrink: 60)
        XCTAssertTrue(list.contains("Você está quase chegando à sua meta!"))
    }

    func testIntegrationWithServiceActivatesAfterFirstDrink() throws {
        let clock = TestClock(TestCalendar.date(2026, 10, 1, 8, 0))
        let service = makeService(clock: clock)
        try service.saveProfile(makeProfile(goalMode: .manual, manualGoal: 2500))

        XCTAssertTrue(planner.plan(for: try XCTUnwrap(service.reminderContext()), calendar: calendar).isEmpty)

        clock.now = TestCalendar.date(2026, 10, 1, 8, 30)
        try service.addDrink(volumeMl: 500)
        let next = planner.nextReminderDate(for: try XCTUnwrap(service.reminderContext()), calendar: calendar)
        XCTAssertEqual(next, TestCalendar.date(2026, 10, 1, 10, 0))
    }
}
