import Foundation

/// Preferências de lembretes. Horários são guardados em minutos desde a
/// meia-noite (ex.: 08:00 → 480) para não depender de fuso horário.
public struct ReminderSettings: Codable, Hashable, Sendable {
    /// Intervalos oferecidos na interface (minutos). Qualquer valor dentro de
    /// `allowedIntervalRange` também é aceito (opção "Personalizado").
    public static let presetIntervals = [30, 60, 90, 120]
    public static let allowedIntervalRange = 15...360

    public var isEnabled: Bool
    public var intervalMinutes: Int
    public var startMinuteOfDay: Int
    public var endMinuteOfDay: Int
    /// Deixa de lembrar depois que a meta do dia foi atingida.
    public var stopWhenGoalReached: Bool

    public init(isEnabled: Bool = true,
                intervalMinutes: Int = 30,
                startMinuteOfDay: Int = 8 * 60,
                endMinuteOfDay: Int = 22 * 60,
                stopWhenGoalReached: Bool = true) {
        self.isEnabled = isEnabled
        self.intervalMinutes = intervalMinutes
        self.startMinuteOfDay = startMinuteOfDay
        self.endMinuteOfDay = endMinuteOfDay
        self.stopWhenGoalReached = stopWhenGoalReached
    }

    public static let `default` = ReminderSettings()

    /// Intervalo efetivamente usado (limitado a uma faixa segura).
    public var clampedIntervalMinutes: Int {
        min(max(intervalMinutes, Self.allowedIntervalRange.lowerBound), Self.allowedIntervalRange.upperBound)
    }

    /// A janela precisa começar antes de terminar no mesmo dia.
    public var hasValidWindow: Bool {
        (0..<(24 * 60)).contains(startMinuteOfDay)
            && (1...(24 * 60)).contains(endMinuteOfDay)
            && startMinuteOfDay < endMinuteOfDay
    }

    public static func format(minuteOfDay: Int) -> String {
        let clamped = min(max(minuteOfDay, 0), 24 * 60)
        return String(format: "%02d:%02d", clamped / 60, clamped % 60)
    }

    private enum CodingKeys: String, CodingKey {
        case isEnabled, intervalMinutes, startMinuteOfDay, endMinuteOfDay, stopWhenGoalReached
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = ReminderSettings.default
        isEnabled = try c.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? d.isEnabled
        intervalMinutes = try c.decodeIfPresent(Int.self, forKey: .intervalMinutes) ?? d.intervalMinutes
        startMinuteOfDay = try c.decodeIfPresent(Int.self, forKey: .startMinuteOfDay) ?? d.startMinuteOfDay
        endMinuteOfDay = try c.decodeIfPresent(Int.self, forKey: .endMinuteOfDay) ?? d.endMinuteOfDay
        stopWhenGoalReached = try c.decodeIfPresent(Bool.self, forKey: .stopWhenGoalReached) ?? d.stopWhenGoalReached
    }
}
