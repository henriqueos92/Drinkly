import SwiftUI
import DrinklyCore

/// Tela inicial.
///
/// ```
/// ┌──────────────────────────┐
/// │        │ 32%             │
/// │ avatar │ 1.250 / 3.950 ml│
/// │ (fixo) │ Faltam 2.700 ml │
/// │        │ [💧 +300 ml]    │  ← coluna rola com a Digital Crown
/// │        │ [🥥 +300 ml]    │  ← atalhos criados em "Outras bebidas"
/// │        │ [Outras]        │
/// │        │ [Editar atalhos]│
/// └──────────────────────────┘
/// ```
/// O avatar fica sempre visível à esquerda; os botões ficam à direita.
/// Registrar água leva um único toque. Com Dynamic Type de acessibilidade, a
/// tela empilha avatar e conteúdo para não espremer o texto.
struct DashboardView: View {
    @EnvironmentObject private var model: HydrationViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isAddDrinkPresented = false

    var body: some View {
        GeometryReader { proxy in
            if dynamicTypeSize.isAccessibilitySize {
                stackedLayout(size: proxy.size)
            } else {
                sideBySideLayout(size: proxy.size)
            }
        }
        .navigationTitle("💧 Hidratação")
        .sheet(isPresented: $isAddDrinkPresented) {
            AddDrinkView(onFinish: { isAddDrinkPresented = false })
                .environmentObject(model)
        }
    }

    // MARK: - Layouts

    /// Avatar fixo à esquerda (~38% da largura) e coluna rolável à direita.
    private func sideBySideLayout(size: CGSize) -> some View {
        HStack(alignment: .center, spacing: 6) {
            avatar
                .frame(width: size.width * 0.38, height: size.height)

            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressSummaryView(summary: model.today, alignment: .leading, compact: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 2)
                    actions(compact: true)
                }
            }
        }
    }

    /// Avatar acima e conteúdo abaixo (tamanhos de texto de acessibilidade).
    private func stackedLayout(size: CGSize) -> some View {
        ScrollView {
            VStack(spacing: 8) {
                avatar.frame(height: min(size.width * 0.5, 90))
                ProgressSummaryView(summary: model.today)
                actions(compact: false)
            }
        }
    }

    // MARK: - Partes

    private var avatar: some View {
        AvatarView(gender: model.profile?.gender ?? .male,
                   fraction: model.today.progress.fraction,
                   status: model.today.status)
    }

    @ViewBuilder
    private func actions(compact: Bool) -> some View {
        ForEach(model.shortcuts) { shortcut in
            QuickAddButton(volumeMl: shortcut.volumeMl, beverage: shortcut.type, compact: compact) {
                model.add(shortcut)
            }
        }

        Button {
            isAddDrinkPresented = true
        } label: {
            Label("Outras", systemImage: "cup.and.saucer.fill")
        }
        .buttonStyle(BigButtonStyle(background: Color.white.opacity(0.14), minHeight: compact ? 36 : 44))
        .accessibilityLabel("Outras bebidas")
        .accessibilityIdentifier("otherDrinks")

        NavigationLink(destination: ShortcutsSettingsView()) {
            Label("Editar atalhos", systemImage: "pencil")
                .font(Theme.rounded(.footnote))
        }
        .buttonStyle(BigButtonStyle(background: Color.white.opacity(0.08),
                                    foreground: Theme.secondaryText,
                                    minHeight: compact ? 30 : 38))
        .accessibilityIdentifier("editShortcuts")

        if let record = model.undoableRecord {
            Button {
                model.undoLastAdd()
            } label: {
                Label("Desfazer", systemImage: "arrow.uturn.backward")
                    .font(Theme.rounded(.footnote))
            }
            .buttonStyle(BigButtonStyle(background: Color.white.opacity(0.08),
                                        foreground: Theme.secondaryText,
                                        minHeight: compact ? 32 : 40))
            .transition(.opacity)
            .accessibilityLabel("Desfazer registro de \(record.volumeMl) mililitros")
            .accessibilityIdentifier("undo")
        }
    }
}

#if DEBUG
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let store = InMemoryHydrationStore(profile: UserProfile(gender: .male, heightCm: 178, weightKg: 113, ageYears: 34))
        let service = HydrationService(store: store)
        _ = try? service.addDrink(volumeMl: 1250)
        return NavigationView { DashboardView() }
            .environmentObject(HydrationViewModel(service: service))
    }
}
#endif
