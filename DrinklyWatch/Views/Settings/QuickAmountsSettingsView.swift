import SwiftUI
import DrinklyCore

/// Escolha dos volumes dos botões rápidos (até 6) e volumes personalizados.
struct QuickAmountsSettingsView: View {
    @EnvironmentObject private var model: HydrationViewModel
    @State private var selected: Set<Int>
    @State private var customVolume = 330
    @State private var extraOptions: [Int] = []

    private static let presets = [100, 150, 200, 250, 300, 330, 400, 500, 600, 750, 1000]

    init(profile: UserProfile) {
        _selected = State(initialValue: Set(profile.quickAmounts))
    }

    private var options: [Int] {
        Array(Set(Self.presets + extraOptions + Array(selected))).sorted()
    }

    var body: some View {
        List {
            Section {
                ForEach(options, id: \.self) { amount in
                    Button {
                        toggle(amount)
                    } label: {
                        HStack {
                            Text(VolumeFormatter.string(ml: amount))
                            Spacer()
                            if selected.contains(amount) {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.water)
                            }
                        }
                    }
                    .accessibilityAddTraits(selected.contains(amount) ? .isSelected : [])
                }
            } header: {
                Text("Até \(UserProfile.maxQuickAmounts) botões")
            }

            Section {
                VolumeCrownPicker(volumeMl: $customVolume)
                Button("Adicionar volume") {
                    extraOptions.append(customVolume)
                    if selected.count < UserProfile.maxQuickAmounts { selected.insert(customVolume) }
                    save()
                }
            } header: {
                Text("Personalizar")
            }
        }
        .navigationTitle("Bebidas rápidas")
    }

    private func toggle(_ amount: Int) {
        if selected.contains(amount) {
            guard selected.count > 1 else { return }
            selected.remove(amount)
        } else {
            guard selected.count < UserProfile.maxQuickAmounts else { return }
            selected.insert(amount)
        }
        save()
    }

    private func save() {
        guard var profile = model.profile else { return }
        profile.quickAmounts = Array(selected)
        model.saveProfile(profile)
    }
}
