import XCTest
@testable import DrinklyCore

final class HydrationServiceTests: XCTestCase {
    private var clock: TestClock!
    private var service: HydrationService!

    override func setUpWithError() throws {
        clock = TestClock(TestCalendar.date(2026, 10, 1, 14, 32))
        service = makeService(clock: clock)
        try service.saveProfile(makeProfile(goalMode: .manual, manualGoal: 2500))
    }

    func testAddDrinkStoresAllFields() throws {
        let record = try service.addDrink(type: .water, volumeMl: 500)
        XCTAssertEqual(record.type, .water)
        XCTAssertEqual(record.volumeMl, 500)
        XCTAssertEqual(record.timestamp, TestCalendar.date(2026, 10, 1, 14, 32))
        XCTAssertEqual(record.day(calendar: TestCalendar.calendar), DayKey(year: 2026, month: 10, day: 1))
        XCTAssertEqual(try service.records(on: service.today), [record])
    }

    func testQuickAddUpdatesTodayProgress() throws {
        try service.addDrink(volumeMl: 1000)
        try service.addDrink(volumeMl: 500)
        let summary = try service.todaySummary()
        XCTAssertEqual(summary.consumedMl, 1500)
        XCTAssertEqual(summary.goalMl, 2500)
        XCTAssertEqual(summary.percentage, 60)
        XCTAssertEqual(summary.remainingMl, 1000)
        XCTAssertEqual(summary.recordCount, 2)
    }

    func testCustomVolumesAreAccepted() throws {
        for volume in [150, 250, 330, 400, 600, 1000] {
            try service.addDrink(type: .juice, volumeMl: volume)
        }
        XCTAssertEqual(try service.todaySummary().consumedMl, 2730)
    }

    func testInvalidVolumeIsRejected() {
        XCTAssertThrowsError(try service.addDrink(volumeMl: 0)) { error in
            XCTAssertEqual(error as? HydrationServiceError, .invalidVolume(0))
        }
        XCTAssertThrowsError(try service.addDrink(volumeMl: 50_000))
    }

    func testGoalReachedAndExceeded() throws {
        try service.addDrink(volumeMl: 2500)
        XCTAssertEqual(try service.todaySummary().status, .reached)
        try service.addDrink(volumeMl: 500)
        let summary = try service.todaySummary()
        XCTAssertEqual(summary.status, .exceeded)
        XCTAssertEqual(summary.percentage, 120)
        XCTAssertEqual(summary.consumedMl, 3000, "O valor real deve continuar armazenado")
    }

    func testEditRecordRecalculatesProgress() throws {
        var record = try service.addDrink(type: .water, volumeMl: 500)
        record.volumeMl = 300
        record.type = .coconutWater
        let updated = try service.updateRecord(record)
        XCTAssertEqual(updated.revision, 2)
        let today = try service.records(on: service.today)
        XCTAssertEqual(today.count, 1)
        XCTAssertEqual(today.first?.type, .coconutWater)
        XCTAssertEqual(try service.todaySummary().consumedMl, 300)
    }

    func testEditRecordMovingToAnotherDay() throws {
        var record = try service.addDrink(volumeMl: 500)
        record.timestamp = TestCalendar.date(2026, 9, 30, 21, 0)
        try service.updateRecord(record)
        XCTAssertEqual(try service.todaySummary().consumedMl, 0)
        XCTAssertEqual(try service.summary(for: DayKey(year: 2026, month: 9, day: 30)).consumedMl, 500)
    }

    func testDeleteRecordRecalculatesProgress() throws {
        let a = try service.addDrink(volumeMl: 500)
        try service.addDrink(volumeMl: 300)
        try service.deleteRecord(a)
        XCTAssertEqual(try service.todaySummary().consumedMl, 300)
        XCTAssertThrowsError(try service.deleteRecord(a))
    }

    func testNewDayStartsAtZeroAndKeepsHistory() throws {
        clock.now = TestCalendar.date(2026, 9, 30, 20, 0)
        try service.addDrink(volumeMl: 2300)
        XCTAssertEqual(try service.todaySummary().consumedMl, 2300)

        // Virada de dia sem nenhum processo à meia-noite: só o relógio muda.
        clock.now = TestCalendar.date(2026, 10, 1, 0, 1)
        XCTAssertEqual(try service.todaySummary().consumedMl, 0)
        XCTAssertEqual(try service.todaySummary().goalMl, 2500)
        XCTAssertEqual(try service.summary(for: DayKey(year: 2026, month: 9, day: 30)).consumedMl, 2300)
    }

    func testMidnightBoundary() throws {
        clock.now = TestCalendar.date(2026, 9, 30, 23, 59)
        try service.addDrink(volumeMl: 200)
        clock.now = TestCalendar.date(2026, 10, 1, 0, 0)
        try service.addDrink(volumeMl: 300)
        XCTAssertEqual(try service.todaySummary().consumedMl, 300)
        XCTAssertEqual(try service.summary(for: DayKey(year: 2026, month: 9, day: 30)).consumedMl, 200)
    }

    func testPastDaysKeepTheGoalOfTheirTime() throws {
        clock.now = TestCalendar.date(2026, 9, 29, 10, 0)
        try service.saveProfile(makeProfile(goalMode: .manual, manualGoal: 2000))
        try service.addDrink(volumeMl: 1000)

        clock.now = TestCalendar.date(2026, 10, 1, 10, 0)
        var profile = try XCTUnwrap(service.profile())
        profile.manualGoalMl = 3000
        try service.saveProfile(profile)

        XCTAssertEqual(try service.summary(for: DayKey(year: 2026, month: 9, day: 29)).goalMl, 2000)
        XCTAssertEqual(try service.summary(for: DayKey(year: 2026, month: 9, day: 29)).percentage, 50)
        XCTAssertEqual(try service.todaySummary().goalMl, 3000)
    }

    func testHistorySummariesIncludeEmptyDays() throws {
        clock.now = TestCalendar.date(2026, 9, 28, 9, 0); try service.addDrink(volumeMl: 1900)
        clock.now = TestCalendar.date(2026, 9, 29, 9, 0); try service.addDrink(volumeMl: 2750)
        clock.now = TestCalendar.date(2026, 10, 1, 9, 0)

        let days = service.history.lastDays(4, endingOn: service.today)
        let summaries = try service.summaries(for: days)
        XCTAssertEqual(summaries.map(\.consumedMl), [1900, 2750, 0, 0])
        XCTAssertEqual(summaries.map(\.day.description), ["2026-09-28", "2026-09-29", "2026-09-30", "2026-10-01"])
    }

    func testStatisticsIgnoreDaysBeforeProfileCreation() throws {
        let store = InMemoryHydrationStore()
        let service = makeService(store: store, clock: clock)
        try service.saveProfile(makeProfile(goalMode: .manual, manualGoal: 2000,
                                            createdAt: TestCalendar.date(2026, 9, 29, 8, 0)))
        clock.now = TestCalendar.date(2026, 9, 29, 9, 0); try service.addDrink(volumeMl: 2000)
        clock.now = TestCalendar.date(2026, 9, 30, 9, 0); try service.addDrink(volumeMl: 1000)
        clock.now = TestCalendar.date(2026, 10, 1, 9, 0); try service.addDrink(volumeMl: 3000)

        let month = service.history.days(of: MonthKey(year: 2026, month: 9), upTo: service.today)
        let stats = try service.statistics(for: month)
        XCTAssertEqual(stats.dayCount, 2)
        XCTAssertEqual(stats.averageMl, 1500)
        XCTAssertEqual(stats.daysGoalReached, 1)
        XCTAssertEqual(stats.highest?.consumedMl, 2000)
        XCTAssertEqual(stats.lowest?.consumedMl, 1000)
        XCTAssertEqual(stats.averageCompletionPercentage, 75)
        XCTAssertEqual(stats.recordCount, 2)
    }

    func testObserversAreNotified() throws {
        let observer = RecordingObserver()
        service.addObserver(observer)
        let record = try service.addDrink(volumeMl: 200)
        try service.deleteRecord(record)
        XCTAssertEqual(observer.changes.count, 2)
        guard case .recordAdded = observer.changes[0], case .recordDeleted = observer.changes[1] else {
            return XCTFail("Eventos inesperados: \(observer.changes)")
        }
    }

    func testQuickAmountsAreSanitizedAndSaved() throws {
        var profile = try XCTUnwrap(service.profile())
        profile.quickAmounts = [750, 200, 300, 200, 0, 500]
        try service.saveProfile(profile)
        XCTAssertEqual(service.profile()?.quickAmounts, [200, 300, 500, 750])
        XCTAssertEqual(UserProfile.sanitizedQuickAmounts([]), UserProfile.defaultQuickAmounts)
        XCTAssertEqual(UserProfile.sanitizedQuickAmounts([100, 200, 300, 500, 750, 1000, 1500]).count, UserProfile.maxQuickAmounts)
    }

    func testDeleteAllDataReturnsToOnboarding() throws {
        try service.addDrink(volumeMl: 500)
        try service.deleteAllData()
        XCTAssertFalse(service.hasCompletedOnboarding)
        XCTAssertEqual(try service.todaySummary().consumedMl, 0)
    }
}
