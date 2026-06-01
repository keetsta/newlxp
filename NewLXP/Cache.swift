import Foundation

/// Лёгкий дисковый кэш под `Caches/LXPCache/`. Каждый ключ — отдельный JSON-файл,
/// чтобы запись одного раздела не блокировала остальные.
///
/// Используется для тёплого старта: данные, прогруженные в прошлый запуск, рендерятся
/// мгновенно, пока сетевой `refreshAll` тянет свежие.
enum DiskCache {

    enum Key: String, CaseIterable {
        case profile
        case lessonsByDay
        case loadedRanges
        case disciplines
        case disciplineDetails
        case topicDetails
        case assignments
    }

    private static let directoryName = "LXPCache"

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private static let directoryURL: URL = {
        let fm = FileManager.default
        let base = (try? fm.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fm.temporaryDirectory
        let dir = base.appendingPathComponent(directoryName, isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private static func url(for key: Key) -> URL {
        directoryURL.appendingPathComponent("\(key.rawValue).json", isDirectory: false)
    }

    static func load<T: Decodable>(_ key: Key, as type: T.Type) -> T? {
        let url = url(for: key)
        guard let data = try? Data(contentsOf: url) else { return nil }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            LXPLog.debug("[Cache] decode \(key.rawValue) failed: \(error)")
            try? FileManager.default.removeItem(at: url)
            return nil
        }
    }

    static func save<T: Encodable>(_ key: Key, _ value: T) {
        let url = url(for: key)
        do {
            let data = try encoder.encode(value)
            try data.write(to: url, options: .atomic)
        } catch {
            LXPLog.debug("[Cache] encode \(key.rawValue) failed: \(error)")
        }
    }

    static func clearAll() {
        let fm = FileManager.default
        for k in Key.allCases {
            try? fm.removeItem(at: url(for: k))
        }
    }
}
