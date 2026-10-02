import SwiftUI
import DrinklyCore

/// Decide entre onboarding (primeiro acesso) e a navegação principal.
struct RootView: View {
    @EnvironmentObject private var model: HydrationViewModel

    var body: some View {
        Group {
            if model.profile == nil {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
        .sheet(isPresented: $model.isQuickAddPresented) {
            QuickAddView()
                .environmentObject(model)
        }
        .alert("Ops", isPresented: isShowingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var isShowingError: Binding<Bool> {
        Binding(get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } })
    }
}

/// Páginas horizontais: Início · Hoje · Histórico · Ajustes.
/// Funciona em watchOS 8 (sem APIs de navegação exclusivas do watchOS 10).
struct MainTabView: View {
    @EnvironmentObject private var model: HydrationViewModel

    var body: some View {
        TabView(selection: $model.selectedTab) {
            NavigationView { DashboardView() }
                .tag(MainTab.dashboard)
            NavigationView { TodayRecordsView() }
                .tag(MainTab.today)
            NavigationView { HistoryView() }
                .tag(MainTab.history)
            NavigationView { SettingsView() }
                .tag(MainTab.settings)
        }
        .tabViewStyle(.page)
    }
}

enum MainTab: Hashable {
    case dashboard, today, history, settings
}
