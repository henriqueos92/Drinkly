import XCTest
@testable import DrinklyCore

final class PersistenceTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("DrinklyTests-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeStore() -> FileHydrationStore {
        FileHydrationStore(directory: directory, calendar: TestCalendar.calendar)
    }

    func testProfileRoundTrip() throws {
        let profile = makeProfile(weight: 82.5)
        try makeStore().saveProfile(profile)
        XCTAssertEqual(try makeStore().loadProfile(), profile)
    }

    func testRecordsPersistAcrossInstancesAndMonths() throws {
        let store = makeStore()
        let sept = DrinkRecord(timestamp: TestCalendar.date(2026, 9, 30, 23, 0), type: .tea, volumeMl: 250)
        let oct = DrinkRecord(timestamp: TestCalendar.date(2026, 10, 1, 8, 30), type: .water, volumeMl: 500)
        try store.insert(oct)
        try store.insert(sept)

        let reopened = makeStore()
        let all = try reopened.records(in: DateInterval(start: TestCalendar.date(2026, 9, 1), end: TestCalendar.date(2026, 11, 1)))
        XCTAssertEqual(all, [sept, oct])
        let october = try reopened.records(in: DayKey(year: 2026, month: 10, day: 1).interval(calendar: TestCalendar.calendar))
        XCTAssertEqual(october, [oct])

        let files = try FileManager.default.contentsOfDirectory(atPath: directory.appendingPathComponent("records").path).sorted()
        XCTAssertEqual(files, ["2026-09.json", "2026-10.json"])
    }

    func testUpdateMovesRecordBetweenMonthFiles() throws {
        let store = makeStore()
        var record = DrinkRecord(timestamp: TestCalendar.date(2026, 10, 1, 8, 0), type: .water, volumeMl: 500)
        try store.insert(record)
        record.timestamp = TestCalendar.date(2026, 9, 30, 8, 0)
        try store.update(record)
        XCTAssertEqual(try makeStore().record(id: record.id), record)
        let files = try FileManager.default.contentsOfDirectory(atPath: directory.appendingPathComponent("records").path)
        XCTAssertEqual(files, ["2026-09.json"])
    }

    func testDeleteAndErrors() throws {
        let store = makeStore()
        let record = DrinkRecord(timestamp: TestCalendar.date(2026, 10, 1, 8, 0), type: .water, volumeMl: 500)
        try store.insert(record)
        try store.deleteRecord(id: record.id)
        XCTAssertNil(try store.record(id: record.id))
        XCTAssertThrowsError(try store.deleteRecord(id: record.id))
        XCTAssertThrowsError(try store.update(record))
    }

    func testSeesWritesFromAnotherInstance() throws {
        // Simula app e widget (processos diferentes) usando o mesmo diretório.
        let app = makeStore()
        let widget = makeStore()
        let interval = DayKey(year: 2026, month: 10, day: 1).interval(calendar: TestCalendar.calendar)
        XCTAssertEqual(try widget.records(in: interval).count, 0)
        try app.insert(DrinkRecord(timestamp: TestCalendar.date(2026, 10, 1, 9, 0), type: .water, volumeMl: 300))
        XCTAssertEqual(try widget.records(in: interval).count, 1)
    }

    func testGoalHistoryAndDeleteAll() throws {
        let store = makeStore()
        var goals = GoalHistory()
        goals.setGoal(2000, from: DayKey(year: 2026, month: 9, day: 1))
        goals.setGoal(2500, from: DayKey(year: 2026, month: 10, day: 1))
        try store.saveGoalHistory(goals)
        try store.saveProfile(makeProfile())
        try store.insert(DrinkRecord(timestamp: Date(), type: .water, volumeMl: 200))

        XCTAssertEqual(try makeStore().loadGoalHistory(), goals)
        try store.deleteAll()
        XCTAssertNil(try store.loadProfile())
        XCTAssertEqual(try store.loadGoalHistory(), GoalHistory())
    }

    func testDecodingIsTolerantToMissingAndUnknownFields() throws {
        let json = """
        [{"id":"8D1B2C3A-0000-4000-8000-000000000001","timestamp":"2026-10-01T11:30:00Z","type":"kombucha","volumeMl":330}]
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let records = try decoder.decode([DrinkRecord].self, from: Data(json.utf8))
        XCTAssertEqual(records.first?.type, .other)
        XCTAssertEqual(records.first?.revision, 1)
    }

    func testLegacyProfileMigratesQuickAmountsToShortcuts() throws {
        let json = """
        {"id":"8D1B2C3A-0000-4000-8000-000000000002","gender":"male","heightCm":178,"weightKg":113,
         "ageYears":34,"quickAmounts":[500,300],"createdAt":"2026-10-01T11:30:00Z"}
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let profile = try decoder.decode(UserProfile.self, from: Data(json.utf8))
        XCTAssertEqual(profile.shortcuts, [.water(300), .water(500)])
        XCTAssertEqual(profile.reminders, .default)

        // Regravado no formato novo e lido de volta.
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let roundTrip = try decoder.decode(UserProfile.self, from: try encoder.encode(profile))
        XCTAssertEqual(roundTrip, profile)
    }

    func testManyYearsOfHistory() throws {
        let store = makeStore()
        let service = makeService(store: store, clock: TestClock(TestCalendar.date(2026, 10, 1, 12, 0)))
        try service.saveProfile(makeProfile(createdAt: TestCalendar.date(2023, 1, 1)))
        var day = DayKey(year: 2023, month: 1, day: 1)
        let today = service.today
        while day <= today {
            try store.insert(DrinkRecord(timestamp: day.startDate(calendar: TestCalendar.calendar).addingTimeInterval(9 * 3600), type: .water, volumeMl: 2000))
            day = day.adding(days: 30, calendar: TestCalendar.calendar)
        }
        let months = service.history.days(of: MonthKey(year: 2024, month: 2), upTo: today)
        XCTAssertEqual(months.count, 29) // 2024 é bissexto
        XCTAssertGreaterThan(try service.statistics(for: months).totalMl, 0)
    }
}
