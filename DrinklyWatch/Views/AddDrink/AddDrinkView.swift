import SwiftUI
import DrinklyCore

/// "Adicionar bebida": escolha do tipo → volume. Dois toques no total.
struct AddDrinkView: View {
    @EnvironmentObject private var model: HydrationViewModel
    let onFinish: () -> Void

    var body: some View {
        NavigationView {
            List {
                ForEach(BeverageType.allCases) { type in
                    NavigationLink(destination: VolumeSelectionView(type: type, onFinish: onFinish)) {
                        Label {
                            Text(type.displayName)
                                .font(Theme.rounded(.body, weight: .medium))
                        } icon: {
                            Image(systemName: type.symbolName)
                                .foregroundColor(type.tint)
                        }
                    }
                    .accessibilityIdentifier("beverage-\(type.rawValue)")
                }
            }
            .navigationTitle("Adicionar bebida")
        }
    }
}

/// Volumes rápidos para o tipo escolhido + "Personalizar".
struct VolumeSelectionView: View {
    @EnvironmentObject private var model: HydrationViewModel
    let type: BeverageType
    let onFinish: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                ForEach(model.quickAmounts, id: \.self) { amount in
                    QuickAddButton(volumeMl: amount, type: type.spokenLabel, identifierPrefix: "volume") {
                        model.add(volumeMl: amount, type: type)
                        onFinish()
                    }
                }
                NavigationLink(destination: CustomVolumeView(type: type, onFinish: onFinish)) {
                    Label("Personalizar", systemImage: "slider.horizontal.3")
                }
                .buttonStyle(BigButtonStyle(background: Color.white.opacity(0.14)))
                .accessibilityIdentifier("customVolume")
            }
        }
        .navigationTitle(type.displayName)
    }
}

/// Volume livre (ex.: 150, 330, 1000 ml) com a Digital Crown.
struct CustomVolumeView: View {
    @EnvironmentObject private var model: HydrationViewModel
    let type: BeverageType
    let onFinish: () -> Void

    @State private var volumeMl = 250

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                VolumeCrownPicker(volumeMl: $volumeMl)
                Button {
                    model.add(volumeMl: volumeMl, type: type)
                    onFinish()
                } label: {
                    Label("Adicionar", systemImage: "plus.circle.fill")
                }
                .buttonStyle(BigButtonStyle(background: Theme.waterDeep))
                .accessibilityLabel("Adicionar \(volumeMl) mililitros de \(type.displayName.lowercased())")
                .accessibilityIdentifier("confirmCustomVolume")
            }
        }
        .navigationTitle("Personalizar")
    }
}
