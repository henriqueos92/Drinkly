import SwiftUI
import DrinklyCore

@main
struct DrinklyApp: App {
    @StateObject private var model = AppEnvironment.shared.viewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .onOpenURL { url in
                    if DeepLink(url: url) == .quickAdd {
                        model.isQuickAddPresented = true
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
                    // Virada de dia com o app aberto: o progresso volta a zero
                    // (o histórico permanece, pois é calculado dos registros).
                    model.refresh()
                }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                model.refresh()
                AppEnvironment.shared.appDidBecomeActive()
            }
        }
    }
}
