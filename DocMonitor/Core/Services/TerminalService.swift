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
        let candidates = ConsoleShell.current.candidates.joined(separator: " ")
        let cli        = DockerEnvironment.isCLICustom ? DockerEnvironment.cliPath : "docker"

        // Probe each shell with a non-interactive `-c true` (unambiguous exit status),
        // then replace the process with the real interactive session
        let script = [
            "export DOCKER_HOST=\(shellQuoted(DockerEnvironment.dockerHost));",
            "d=\(shellQuoted(cli)); n=\(shellQuoted(containerName));",
            "for s in \(candidates); do",
            "\"$d\" exec \"$n\" \"$s\" -c true >/dev/null 2>&1 && exec \"$d\" exec -it \"$n\" \"$s\";",
            "done;",
            "echo \"No supported shell found in $n (tried: \(candidates))\" >&2; exit 127",
        ].joined(separator: " ")

        let dockerCommand  = "/bin/sh -c " + shellQuoted(script)
        let escapedCommand = appleScriptQuoted(dockerCommand)

        let appleScript = """
        tell application "Terminal"
            do script "\(escapedCommand)"
            activate
        end tell
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", appleScript]

        do {
            try process.run()
        } catch {
            throw TerminalServiceError.failedToOpen(underlying: error)
        }
    }
}
