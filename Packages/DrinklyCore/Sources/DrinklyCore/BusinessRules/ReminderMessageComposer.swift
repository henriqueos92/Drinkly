import Foundation

/// Gera textos variados e contextuais para os lembretes, evitando repetir a
/// mesma mensagem em sequência.
public struct ReminderMessageComposer: Sendable {
    public struct Message: Hashable, Sendable {
        public let title: String
        public let body: String
    }

    public init() {}

    /// - Parameters:
    ///   - index: posição do lembrete na sequência (0 = próximo).
    ///   - progress: progresso no momento do agendamento. Como qualquer nova
    ///     bebida reagenda tudo, os números continuam válidos quando o lembrete
    ///     dispara.
    ///   - minutesSinceLastDrink: tempo desde a última bebida no disparo.
    ///   - seed: varia a ordem entre dias (ex.: dia do mês).
    public func message(index: Int, progress: HydrationProgress, minutesSinceLastDrink: Int, seed: Int = 0) -> Message {
        let candidates = self.candidates(progress: progress, minutesSinceLastDrink: minutesSinceLastDrink)
        let body = candidates[(index + seed) % candidates.count]
        return Message(title: "Hora de beber água 💧", body: body)
    }

    func candidates(progress: HydrationProgress, minutesSinceLastDrink: Int) -> [String] {
        let consumed = VolumeFormatter.string(ml: progress.consumedMl)
        let remaining = VolumeFormatter.string(ml: progress.remainingMl)
        var list: [String] = []

        if progress.goalReached {
            list.append("Meta de hoje atingida. Um gole extra mantém o ritmo!")
            list.append("Você já bebeu \(consumed) hoje. Continue assim!")
            return list
        }

        if progress.fraction >= 0.8 {
            list.append("Você está quase chegando à sua meta!")
        }
        list.append("Que tal mais um copo de água?")
        list.append("Você já bebeu \(consumed) hoje.")
        list.append("Faltam \(remaining) para sua meta.")
        if minutesSinceLastDrink >= 120 {
            let hours = minutesSinceLastDrink / 60
            list.append("Já faz \(hours) h desde sua última bebida.")
        }
        return list
    }
}
