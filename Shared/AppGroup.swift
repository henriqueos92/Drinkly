import Foundation
import DrinklyCore

/// Configuração compartilhada entre o app e a extensão de widgets.
///
/// O identificador do App Group vem do Info.plist (`DrinklyAppGroup`), que por
/// sua vez é preenchido pela build setting `APP_GROUP_IDENTIFIER`. Assim o
/// identificador é alterado em um único lugar (project.yml / Build Settings).
enum AppGroup {
    static var identifier: String? {
        Bundle.main.object(forInfoDictionaryKey: "DrinklyAppGroup") as? String
    }

    static var storageDirectory: URL {
        StorageLocation.directory(appGroupIdentifier: identifier)
    }

    static func makeStore() -> FileHydrationStore {
        FileHydrationStore(directory: storageDirectory)
    }
}
