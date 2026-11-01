import Foundation

enum TerminalServiceError: LocalizedError {
    case failedToOpen(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .failedToOpen(let underlying):
            return "Couldn't open Terminal: \(underlying.localizedDescription)"
        }
    }
}

class TerminalService {
    // Shell-quotes a string for safe use as a single argument to /bin/sh
    private func shellQuoted(_ string: String) -> String {
        "'" + string.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    // Escapes a string for embedding inside a double-quoted AppleScript
    private func appleScriptQuoted(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    func openShell(containerName: String) throws {
        let quotedName = shellQuoted(containerName)
        let host       = shellQuoted(DockerEnvironment.dockerHost)
        let docker     = "DOCKER_HOST=\(host) " + (DockerEnvironment.isCLICustom
            ? shellQuoted(DockerEnvironment.cliPath)
            : "docker")
        let dockerCommand = ConsoleShell.current.candidates
            .map { "\(docker) exec -it \(quotedName) \($0)" }
            .joined(separator: " || ")
        let escapedCommand = appleScriptQuoted(dockerCommand)

        let script = """
        tell application "Terminal"
            do script "\(escapedCommand)"
            activate
        end tell
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]

        do {
            try process.run()
        } catch {
            throw TerminalServiceError.failedToOpen(underlying: error)
        }
    }
}
