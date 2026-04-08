import Foundation

enum RecentItems {
    private static let filesKey = "RecentFiles"
    private static let foldersKey = "RecentFolders"
    private static let maxFiles = 15
    private static let maxFolders = 5

    // MARK: - Read

    static var files: [URL] {
        paths(for: filesKey).map { URL(fileURLWithPath: $0) }
    }

    static var folders: [URL] {
        paths(for: foldersKey).map { URL(fileURLWithPath: $0) }
    }

    // MARK: - Write

    static func addFile(_ url: URL) {
        add(url.path, to: filesKey, max: maxFiles)
    }

    static func addFolder(_ url: URL) {
        add(url.path, to: foldersKey, max: maxFolders)
    }

    static func clearAll() {
        UserDefaults.standard.removeObject(forKey: filesKey)
        UserDefaults.standard.removeObject(forKey: foldersKey)
    }

    // MARK: - Internal

    private static func paths(for key: String) -> [String] {
        (UserDefaults.standard.stringArray(forKey: key) ?? [])
            .filter { FileManager.default.fileExists(atPath: $0) }
    }

    private static func add(_ path: String, to key: String, max: Int) {
        var list = UserDefaults.standard.stringArray(forKey: key) ?? []
        list.removeAll { $0 == path }
        list.insert(path, at: 0)
        if list.count > max { list = Array(list.prefix(max)) }
        UserDefaults.standard.set(list, forKey: key)
    }
}
