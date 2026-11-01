import Foundation

nonisolated enum DockerEnvironment {

    enum Mode: String, CaseIterable, Identifiable {
        case automatic
        case custom

        var id: String { rawValue }
        var title: String { self == .automatic ? "Automatic" : "Custom" }
    }

    enum Keys {
        static let socketMode       = "dockerSocketMode"
        static let socketCustomPath = "dockerSocketCustomPath"
        static let cliMode          = "dockerCLIMode"
        static let cliCustomPath    = "dockerCLICustomPath"
    }

    // MARK: - Preferences (read on every call, so changes apply without restart)

    private static func mode(for key: String) -> Mode {
        UserDefaults.standard.string(forKey: key).flatMap(Mode.init(rawValue:)) ?? .automatic
    }

    static func expandedPath(_ raw: String) -> String {
        (raw.trimmingCharacters(in: .whitespacesAndNewlines) as NSString).expandingTildeInPath
    }

    private static func customPath(for key: String) -> String {
        expandedPath(UserDefaults.standard.string(forKey: key) ?? "")
    }

    // MARK: - Socket

    static let automaticSocketCandidates: [String] = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return [
            "/var/run/docker.sock",
            "\(home)/.docker/run/docker.sock",
            "\(home)/.orbstack/run/docker.sock",
            "\(home)/.colima/default/docker.sock",
            "\(home)/.rd/docker.sock",
        ]
    }()

    static var socketCandidates: [String] {
        switch mode(for: Keys.socketMode) {
        case .automatic: return automaticSocketCandidates
        case .custom:    return [customPath(for: Keys.socketCustomPath)]
        }
    }

    /// Connects to the first socket that accepts a connection.
    /// Throws `.connectFailed` if some socket file exists but none accepted, `.notFound` otherwise.
    static func connect() throws -> (fd: Int32, path: String) {
        var sawExistingSocket = false
        for path in socketCandidates {
            do {
                let fd = try UnixSocket.makeConnection(to: path)
                return (fd, path)
            } catch UnixSocketError.notFound {
                continue
            } catch {
                sawExistingSocket = true
            }
        }
        throw sawExistingSocket ? UnixSocketError.connectFailed : UnixSocketError.notFound
    }

    /// Socket that DocMonitor is using (or would try first); used for DOCKER_HOST.
    static var activeSocketPath: String {
        if let connection = try? connect() {
            close(connection.fd)
            return connection.path
        }
        return socketCandidates.first { FileManager.default.fileExists(atPath: $0) }
            ?? socketCandidates[0]
    }

    static var dockerHost: String { "unix://\(activeSocketPath)" }

    /// First automatic candidate that accepts a connection (for the Preferences caption).
    static func detectAutomaticSocket() -> String? {
        for path in automaticSocketCandidates {
            if let fd = try? UnixSocket.makeConnection(to: path) {
                close(fd)
                return path
            }
        }
        return nil
    }

    // MARK: - CLI

    static let automaticCLICandidates = [
        "/usr/local/bin/docker",
        "/opt/homebrew/bin/docker",
        "/usr/bin/docker",
    ]

    static var automaticCLIPath: String? {
        automaticCLICandidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    static var isCLICustom: Bool { mode(for: Keys.cliMode) == .custom }

    static var cliPath: String {
        isCLICustom
            ? customPath(for: Keys.cliCustomPath)
            : (automaticCLIPath ?? "/usr/local/bin/docker")
    }
}
