import SwiftUI
import DrinklyCore

/// Registro rápido aberto pela complicação/widget, Smart Stack ou atalho:
/// 💧 52% → TOQUE → +200 / +300 / +500. Fecha sozinho após registrar.
struct QuickAddView: View {
    @EnvironmentObject private var model: HydrationViewModel
    @State private var isAddDrinkPresented = false

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    DropProgressView(fraction: model.progress.fraction, fillColor: Theme.water)
                        .frame(height: 28)
                    Text("\(model.today.percentage)%")
                        .font(Theme.rounded(.title3))
                    Spacer(minLength: 0)
                    Text(VolumeFormatter.progress(consumedMl: model.today.consumedMl, goalMl: model.today.goalMl))
                        .font(Theme.rounded(.footnote))
                        .foregroundColor(Theme.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .accessibilityElement(children: .combine)

                ForEach(model.shortcuts) { shortcut in
                    QuickAddButton(volumeMl: shortcut.volumeMl, beverage: shortcut.type, compact: true) {
                        model.add(shortcut)
                        model.isQuickAddPresented = false
                    }
                }
                Button {
                    isAddDrinkPresented = true
                } label: {
                    Label("Outras bebidas", systemImage: "cup.and.saucer.fill")
                }
                .buttonStyle(BigButtonStyle(background: Color.white.opacity(0.14)))
            }
        }
        .sheet(isPresented: $isAddDrinkPresented) {
            AddDrinkView(onFinish: {
                isAddDrinkPresented = false
                model.isQuickAddPresented = false
            })
            .environmentObject(model)
        }
    }
}
