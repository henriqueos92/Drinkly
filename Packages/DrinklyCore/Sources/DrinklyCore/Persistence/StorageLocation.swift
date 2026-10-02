import Foundation

/// Resolve onde os dados ficam gravados.
///
/// No relógio usamos o contêiner do App Group, compartilhado entre o app e a
/// extensão de widgets/complicações. Sem App Group configurado (ex.: testes),
/// cai para Application Support do próprio app. Os dados nunca saem do
/// dispositivo.
public enum StorageLocation {
    public static let folderName = "Drinkly"

    public static func directory(appGroupIdentifier: String?, fileManager: FileManager = .default) -> URL {
        #if canImport(Darwin)
        if let group = appGroupIdentifier, !group.isEmpty,
           let container = fileManager.containerURL(forSecurityApplicationGroupIdentifier: group) {
            return container.appendingPathComponent(folderName, isDirectory: true)
        }
        #endif
        let base = (try? fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
            ?? fileManager.temporaryDirectory
        return base.appendingPathComponent(folderName, isDirectory: true)
    }
}
