import Foundation
import DrinklyCore
#if canImport(AppIntents)
import AppIntents

// Ações para Siri, app Atalhos e Smart Stack (watchOS 9+).
// No watchOS 8 o framework AppIntents não existe; lá o atalho equivalente é
// a própria complicação ClockKit, que abre o app direto nos botões rápidos.

@available(watchOS 9.0, *)
enum BeverageAppEnum: String, AppEnum {
    case water, coconutWater, juice, coffee, tea, soda, other

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Bebida"
    static var caseDisplayRepresentations: [BeverageAppEnum: DisplayRepresentation] = [
        .water: "Água",
        .coconutWater: "Água de coco",
        .juice: "Suco",
        .coffee: "Café",
        .tea: "Chá",
        .soda: "Refrigerante",
        .other: "Outra bebida"
    ]

    var beverage: BeverageType { BeverageType(rawValue: rawValue) ?? .other }
}

/// Lógica comum a todos os intents de registro.
@available(watchOS 9.0, *)
enum DrinkIntentPerformer {
    static func add(volumeMl: Int, type: BeverageType) throws -> String {
        let service = AppEnvironment.shared.service
        guard UserProfile.allowedVolumeRange.contains(volumeMl) else {
            return "Informe um volume entre \(UserProfile.allowedVolumeRange.lowerBound) e \(UserProfile.allowedVolumeRange.upperBound) ml."
        }
        guard service.hasCompletedOnboarding else {
            return "Abra o Drinkly para configurar seu perfil primeiro."
        }
        try service.addDrink(type: type, volumeMl: volumeMl)
        let summary = try service.todaySummary()
        let total = VolumeFormatter.progress(consumedMl: summary.consumedMl, goalMl: summary.goalMl)
        return "\(type.displayName): +\(VolumeFormatter.string(ml: volumeMl)). Hoje: \(total) (\(summary.percentage)%)."
    }

    static var firstQuickAmount: Int {
        AppEnvironment.shared.service.profile()?.quickAmounts.first ?? 300
    }
}

@available(watchOS 9.0, *)
struct AddDrinkIntent: AppIntent {
    static var title: LocalizedStringResource = "Registrar bebida"
    static var description = IntentDescription("Registra uma bebida com o volume escolhido.")

    @Parameter(title: "Volume (ml)", default: 300)
    var volumeMl: Int

    @Parameter(title: "Bebida", default: .water)
    var beverage: BeverageAppEnum

    static var parameterSummary: some ParameterSummary {
        Summary("Registrar \(\.$volumeMl) ml de \(\.$beverage)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let message = try DrinkIntentPerformer.add(volumeMl: volumeMl, type: beverage.beverage)
        return .result(dialog: "\(message)")
    }
}

@available(watchOS 9.0, *)
struct AddWaterIntent: AppIntent {
    static var title: LocalizedStringResource = "Adicionar água"
    static var description = IntentDescription("Adiciona o primeiro volume rápido configurado.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let message = try DrinkIntentPerformer.add(volumeMl: DrinkIntentPerformer.firstQuickAmount, type: .water)
        return .result(dialog: "\(message)")
    }
}

@available(watchOS 9.0, *)
struct AddWater200Intent: AppIntent {
    static var title: LocalizedStringResource = "Adicionar 200 ml"

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let message = try DrinkIntentPerformer.add(volumeMl: 200, type: .water)
        return .result(dialog: "\(message)")
    }
}

@available(watchOS 9.0, *)
struct AddWater300Intent: AppIntent {
    static var title: LocalizedStringResource = "Adicionar 300 ml"

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let message = try DrinkIntentPerformer.add(volumeMl: 300, type: .water)
        return .result(dialog: "\(message)")
    }
}

@available(watchOS 9.0, *)
struct AddWater500Intent: AppIntent {
    static var title: LocalizedStringResource = "Adicionar 500 ml"

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let message = try DrinkIntentPerformer.add(volumeMl: 500, type: .water)
        return .result(dialog: "\(message)")
    }
}

/// Abre o app direto na tela de registro rápido.
@available(watchOS 9.0, *)
struct OpenQuickAddIntent: AppIntent {
    static var title: LocalizedStringResource = "Registro rápido"
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppEnvironment.shared.viewModel.isQuickAddPresented = true
        return .result()
    }
}

/// Frases para a Siri. Toda frase precisa conter o nome do app.
@available(watchOS 9.0, *)
struct DrinklyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: AddWaterIntent(), phrases: [
            "Adicionar água no \(.applicationName)",
            "Registrar água no \(.applicationName)"
        ])
        AppShortcut(intent: AddWater200Intent(), phrases: [
            "Adicionar 200 ml no \(.applicationName)"
        ])
        AppShortcut(intent: AddWater300Intent(), phrases: [
            "Adicionar 300 ml no \(.applicationName)"
        ])
        AppShortcut(intent: AddWater500Intent(), phrases: [
            "Adicionar 500 ml no \(.applicationName)"
        ])
        AppShortcut(intent: OpenQuickAddIntent(), phrases: [
            "Abrir registro rápido do \(.applicationName)"
        ])
    }
}
#endif
