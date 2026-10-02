import Foundation
@testable import DrinklyCore

enum TestCalendar {
    static let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
        c.locale = Locale(identifier: "pt_BR")
        c.firstWeekday = 2
        return c
    }()

    static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}

/// Relógio controlável para simular a passagem do tempo (virada de dia).
final class TestClock {
    var now: Date
    init(_ now: Date) { self.now = now }
}

func makeProfile(weight: Double = 70,
                 goalMode: GoalMode = .automatic,
                 manualGoal: Int = 2500,
                 reminders: ReminderSettings = .default,
                 createdAt: Date = TestCalendar.date(2026, 9, 1)) -> UserProfile {
    UserProfile(gender: .male, heightCm: 175, weightKg: weight, ageYears: 34,
                goalMode: goalMode, manualGoalMl: manualGoal,
                reminders: reminders, createdAt: createdAt)
}

func makeService(store: HydrationStore = InMemoryHydrationStore(), clock: TestClock) -> HydrationService {
    HydrationService(store: store, calendar: TestCalendar.calendar, clock: { clock.now })
}

final class RecordingObserver: HydrationObserver {
    var changes: [HydrationChange] = []
    func hydrationService(_ service: HydrationService, didApply change: HydrationChange) {
        changes.append(change)
    }
}
