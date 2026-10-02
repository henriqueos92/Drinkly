import SwiftUI
import DrinklyCore

/// Tela inicial: progresso + avatar + botões de adição rápida.
/// Registrar água leva um único toque.
struct DashboardView: View {
    @EnvironmentObject private var model: HydrationViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isAddDrinkPresented = false

    /// Largura mínima (pt) para colocar o avatar à esquerda dos números.
    /// 40/41/44/45/49 mm (≥ 162 pt) usam lado a lado; 38/42 mm (Series 3)
    /// empilham o avatar acima.
    private static let sideBySideMinWidth: CGFloat = 160

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 10) {
                    header(width: proxy.size.width)
                    quickAddGrid
                    Button {
                        isAddDrinkPresented = true
                    } label: {
                        Label("Outras bebidas", systemImage: "cup.and.saucer.fill")
                    }
                    .buttonStyle(BigButtonStyle(background: Color.white.opacity(0.14)))
                    .accessibilityIdentifier("otherDrinks")
                    undoBar
                }
                .padding(.horizontal, 2)
            }
        }
        .navigationTitle("💧 Hidratação")
        .sheet(isPresented: $isAddDrinkPresented) {
            AddDrinkView(onFinish: { isAddDrinkPresented = false })
                .environmentObject(model)
        }
    }

    // MARK: - Partes

    @ViewBuilder
    private func header(width: CGFloat) -> some View {
        let summary = model.today
        let gender = model.profile?.gender ?? .male
        let avatar = AvatarView(gender: gender, fraction: summary.progress.fraction, status: summary.status)
        if width >= Self.sideBySideMinWidth && !dynamicTypeSize.isAccessibilitySize {
            HStack(alignment: .center, spacing: 8) {
                avatar
                    .frame(width: width * 0.28)
                    .frame(maxHeight: width * 0.56)
                ProgressSummaryView(summary: summary, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            VStack(spacing: 6) {
                avatar
                    .frame(height: min(width * 0.45, 80))
                ProgressSummaryView(summary: summary)
            }
        }
    }

    private var quickAddGrid: some View {
        let amounts = Array(model.quickAmounts.prefix(4))
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
            ForEach(amounts, id: \.self) { amount in
                QuickAddButton(volumeMl: amount) {
                    model.add(volumeMl: amount)
                }
            }
        }
    }

    @ViewBuilder
    private var undoBar: some View {
        if let record = model.undoableRecord {
            Button {
                model.undoLastAdd()
            } label: {
                Label("Desfazer +\(record.volumeMl) ml", systemImage: "arrow.uturn.backward")
                    .font(Theme.rounded(.footnote))
            }
            .buttonStyle(BigButtonStyle(background: Color.white.opacity(0.08), foreground: Theme.secondaryText))
            .transition(.opacity)
            .accessibilityLabel("Desfazer registro de \(record.volumeMl) mililitros")
            .accessibilityIdentifier("undo")
        }
    }
}

#if DEBUG
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let store = InMemoryHydrationStore(profile: UserProfile(gender: .female, heightCm: 165, weightKg: 60, ageYears: 30, goalMode: .manual, manualGoalMl: 2500))
        let service = HydrationService(store: store)
        _ = try? service.addDrink(volumeMl: 1250)
        return NavigationView { DashboardView() }
            .environmentObject(HydrationViewModel(service: service))
    }
}
#endif
