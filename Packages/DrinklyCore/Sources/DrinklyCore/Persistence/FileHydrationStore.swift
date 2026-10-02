import Foundation

/// Persistência local em arquivos JSON, compatível com watchOS 8 (Apple Watch
/// Series 3), sem dependências externas.
///
/// Layout do diretório:
/// ```
/// profile.json
/// goals.json
/// records/2026-10.json   ← um arquivo por mês
/// ```
/// O particionamento mensal mantém cada gravação pequena (apenas o mês
/// alterado é reescrito) e suporta vários anos de histórico. As gravações são
/// atômicas, então a extensão de widgets (outro processo) sempre lê um arquivo
/// íntegro do App Group compartilhado.
public final class FileHydrationStore: HydrationStore {
    public let directory: URL
    private let fileManager: FileManager
    private let calendar: Calendar
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let lock = NSLock()

    /// Cache por mês, invalidado pela data de modificação do arquivo
    /// (outro processo pode ter gravado).
    private var monthCache: [MonthKey: (modified: Date?, records: [DrinkRecord])] = [:]

    public init(directory: URL, fileManager: FileManager = .default, calendar: Calendar = .current) {
        self.directory = directory
        self.fileManager = fileManager
        self.calendar = calendar
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Perfil e metas

    public func loadProfile() throws -> UserProfile? {
        lock.lock(); defer { lock.unlock() }
        return try read(UserProfile.self, from: profileURL)
    }

    public func saveProfile(_ profile: UserProfile) throws {
        lock.lock(); defer { lock.unlock() }
        try write(profile, to: profileURL)
    }

    public func loadGoalHistory() throws -> GoalHistory {
        lock.lock(); defer { lock.unlock() }
        return try read(GoalHistory.self, from: goalsURL) ?? GoalHistory()
    }

    public func saveGoalHistory(_ history: GoalHistory) throws {
        lock.lock(); defer { lock.unlock() }
        try write(history, to: goalsURL)
    }

    // MARK: - Registros

    public func records(in interval: DateInterval) throws -> [DrinkRecord] {
        lock.lock(); defer { lock.unlock() }
        var result: [DrinkRecord] = []
        for month in months(covering: interval) {
            result += try loadMonth(month).filter { $0.timestamp >= interval.start && $0.timestamp < interval.end }
        }
        return result.sorted { $0.timestamp < $1.timestamp }
    }

    public func record(id: UUID) throws -> DrinkRecord? {
        lock.lock(); defer { lock.unlock() }
        guard let month = try findMonth(of: id) else { return nil }
        return try loadMonth(month).first { $0.id == id }
    }

    public func insert(_ record: DrinkRecord) throws {
        lock.lock(); defer { lock.unlock() }
        let month = MonthKey(record.timestamp, calendar: calendar)
        var records = try loadMonth(month)
        records.removeAll { $0.id == record.id }
        records.append(record)
        try saveMonth(month, records: records)
    }

    public func update(_ record: DrinkRecord) throws {
        lock.lock(); defer { lock.unlock() }
        guard let oldMonth = try findMonth(of: record.id) else {
            throw HydrationStoreError.recordNotFound(record.id)
        }
        let newMonth = MonthKey(record.timestamp, calendar: calendar)
        var old = try loadMonth(oldMonth)
        old.removeAll { $0.id == record.id }
        if oldMonth == newMonth {
            old.append(record)
            try saveMonth(oldMonth, records: old)
        } else {
            // O horário foi movido para outro mês: troca de arquivo.
            var new = try loadMonth(newMonth)
            new.append(record)
            try saveMonth(newMonth, records: new)
            try saveMonth(oldMonth, records: old)
        }
    }

    public func deleteRecord(id: UUID) throws {
        lock.lock(); defer { lock.unlock() }
        guard let month = try findMonth(of: id) else { throw HydrationStoreError.recordNotFound(id) }
        var records = try loadMonth(month)
        records.removeAll { $0.id == id }
        try saveMonth(month, records: records)
    }

    public func deleteAll() throws {
        lock.lock(); defer { lock.unlock() }
        monthCache = [:]
        for url in [profileURL, goalsURL, recordsDirectory] where fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    // MARK: - Arquivos

    private var profileURL: URL { directory.appendingPathComponent("profile.json") }
    private var goalsURL: URL { directory.appendingPathComponent("goals.json") }
    private var recordsDirectory: URL { directory.appendingPathComponent("records", isDirectory: true) }

    private func monthURL(_ month: MonthKey) -> URL {
        recordsDirectory.appendingPathComponent("\(month.description).json")
    }

    private func months(covering interval: DateInterval) -> [MonthKey] {
        var months: [MonthKey] = []
        var current = MonthKey(interval.start, calendar: calendar)
        // `end` é exclusivo.
        let last = MonthKey(interval.end.addingTimeInterval(-0.001), calendar: calendar)
        while current <= last {
            months.append(current)
            current = current.adding(months: 1, calendar: calendar)
        }
        return months
    }

    /// Meses existentes em disco, do mais recente ao mais antigo.
    private func storedMonths() -> [MonthKey] {
        let names = (try? fileManager.contentsOfDirectory(atPath: recordsDirectory.path)) ?? []
        return names.compactMap { name -> MonthKey? in
            guard name.hasSuffix(".json") else { return nil }
            let parts = name.dropLast(5).split(separator: "-")
            guard parts.count == 2, let y = Int(parts[0]), let m = Int(parts[1]) else { return nil }
            return MonthKey(year: y, month: m)
        }.sorted(by: >)
    }

    private func findMonth(of id: UUID) throws -> MonthKey? {
        for month in storedMonths() where try loadMonth(month).contains(where: { $0.id == id }) {
            return month
        }
        return nil
    }

    private func modificationDate(of url: URL) -> Date? {
        (try? fileManager.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date
    }

    private func loadMonth(_ month: MonthKey) throws -> [DrinkRecord] {
        let url = monthURL(month)
        let modified = modificationDate(of: url)
        if let cached = monthCache[month], cached.modified == modified {
            return cached.records
        }
        let records = try read([DrinkRecord].self, from: url) ?? []
        monthCache[month] = (modified, records)
        return records
    }

    private func saveMonth(_ month: MonthKey, records: [DrinkRecord]) throws {
        let url = monthURL(month)
        let sorted = records.sorted { $0.timestamp < $1.timestamp }
        if sorted.isEmpty {
            if fileManager.fileExists(atPath: url.path) { try fileManager.removeItem(at: url) }
        } else {
            try write(sorted, to: url)
        }
        monthCache[month] = (modificationDate(of: url), sorted)
    }

    private func read<T: Decodable>(_ type: T.Type, from url: URL) throws -> T? {
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try decoder.decode(T.self, from: data)
    }

    private func write<T: Encodable>(_ value: T, to url: URL) throws {
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try encoder.encode(value)
        #if os(watchOS) || os(iOS)
        // Protege os dados com a criptografia do dispositivo, mas permite que
        // widgets/complicações leiam com o relógio bloqueado após o 1º desbloqueio.
        try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        #else
        try data.write(to: url, options: .atomic)
        #endif
    }
}
