import Foundation

nonisolated enum ComposeProjectStore {

    static let enabledKey     = "persistComposeProjects"
    static let defaultEnabled = true
    private static let pathsKey = "composeProjectPaths"

    // `object(forKey:)` distinguishes "never set" (use the default) from "off"
    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? defaultEnabled
    }

    static func load() -> [String] {
        guard isEnabled else { return [] }
        return UserDefaults.standard.stringArray(forKey: pathsKey) ?? []
    }

    // Saves the list when persistence is on; clears it when it's off
    static func save(_ paths: [String]) {
        if isEnabled {
            UserDefaults.standard.set(paths.sorted(), forKey: pathsKey)
        } else {
            clear()
        }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: pathsKey)
    }
}
