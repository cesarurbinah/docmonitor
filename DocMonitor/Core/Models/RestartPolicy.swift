import Foundation

nonisolated enum RestartPolicy: String, CaseIterable, Identifiable {
    case no            = "no"
    case always        = "always"
    case unlessStopped = "unless-stopped"
    case onFailure     = "on-failure"

    static let defaultsKey = "defaultRestartPolicy"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .no:            return "No"
        case .always:        return "Always"
        case .unlessStopped: return "Unless Stopped"
        case .onFailure:     return "On Failure"
        }
    }

    // Policy preselected in the Create Container form (set in Preferences)
    static var preferred: RestartPolicy {
        UserDefaults.standard.string(forKey: defaultsKey).flatMap(RestartPolicy.init(rawValue:)) ?? .no
    }
}
