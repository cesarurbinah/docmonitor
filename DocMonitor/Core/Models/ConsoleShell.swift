import Foundation

nonisolated enum ConsoleShell: String, CaseIterable, Identifiable {
    case automatic
    case bash
    case sh
    case zsh

    static let key = "consoleShell"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic: return "Automatic"
        case .bash:      return "bash"
        case .sh:        return "sh"
        case .zsh:       return "zsh"
        }
    }

    /// Shells to try, in order, until one exists in the container
    var candidates: [String] {
        switch self {
        case .automatic: return ["bash", "sh"]
        case .bash:      return ["bash"]
        case .sh:        return ["sh"]
        case .zsh:       return ["zsh"]
        }
    }

    static var current: ConsoleShell {
        UserDefaults.standard.string(forKey: key).flatMap(ConsoleShell.init(rawValue:)) ?? .automatic
    }
}
