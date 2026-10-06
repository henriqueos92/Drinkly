import SwiftUI
import DrinklyCore

/// "Editar atalhos": lista dos atalhos da tela inicial (água e outras
/// bebidas), com exclusão por deslize e criação de novos atalhos.
///
/// Atalhos também são criados automaticamente ao registrar uma bebida por
/// "Outras bebidas".
struct ShortcutsSettingsView: View {
    @EnvironmentObject private var model: HydrationViewModel
    @State private var newType: BeverageType = .water
    @State private var newVolume = 300
    @State private var feedback: String?

    var body: some View {
        let shortcuts = model.shortcuts
        List {
            Section {
                if shortcuts.isEmpty {
                    Text("Nenhum atalho. Registre uma bebida em \"Outras\" ou crie um abaixo.")
                        .font(.footnote)
                        .foregroundColor(Theme.secondaryText)
                }
                ForEach(shortcuts) { shortcut in
                    ShortcutRow(shortcut: shortcut)
                }
                .onDelete { offsets in
                    offsets.map { shortcuts[$0] }.forEach(model.removeShortcut)
                }
            } header: {
                Text("Atalhos (\(shortcuts.count)/\(UserProfile.maxShortcuts))")
            } footer: {
                Text("Deslize um atalho para a esquerda para excluir.")
            }

            Section {
                Picker("Bebida", selection: $newType) {
                    ForEach(BeverageType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                VolumeCrownPicker(volumeMl: $newVolume)
                Button {
                    let shortcut = DrinkShortcut(type: newType, volumeMl: newVolume)
                    if model.addShortcut(shortcut) {
                        feedback = nil
                    } else if shortcuts.contains(shortcut) {
                        feedback = "Esse atalho já existe."
                    } else {
                        feedback = "Limite de \(UserProfile.maxShortcuts) atalhos. Exclua um para adicionar outro."
                    }
                } label: {
                    Label("Adicionar atalho", systemImage: "plus.circle.fill")
                }
                .accessibilityIdentifier("addShortcut")
                if let feedback = feedback {
                    Text(feedback)
                        .font(.footnote)
                        .foregroundColor(.orange)
                }
            } header: {
                Text("Novo atalho")
            }
        }
        .navigationTitle("Atalhos")
    }
}

private struct ShortcutRow: View {
    let shortcut: DrinkShortcut

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: shortcut.type.symbolName)
                .foregroundColor(shortcut.type.tint)
                .frame(width: 18)
            Text(shortcut.type.displayName)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 4)
            Text(VolumeFormatter.string(ml: shortcut.volumeMl))
                .font(Theme.rounded(.footnote))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(shortcut.type.displayName), \(VolumeFormatter.spoken(ml: shortcut.volumeMl))")
        .accessibilityHint("Deslize para excluir")
    }
}
