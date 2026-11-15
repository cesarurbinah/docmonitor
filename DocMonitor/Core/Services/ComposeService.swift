import Foundation
import AppKit

class ComposeService {

    static let shared = ComposeService()

    func up(project: DockerComposeProject) throws {
        let projectDir = URL(fileURLWithPath: project.filePath)
            .deletingLastPathComponent().path
        try runCompose(args: ["compose", "up", "-d"], workingDirectory: projectDir)
    }

    func down(project: DockerComposeProject) throws {
        let projectDir = URL(fileURLWithPath: project.filePath)
            .deletingLastPathComponent().path
        try runCompose(args: ["compose", "down"], workingDirectory: projectDir)
    }

    @discardableResult
    private func runCompose(args: [String], workingDirectory: String) throws -> Data {
        let process = Process()
        let outPipe = Pipe()
        let errPipe = Pipe()

        process.executableURL       = URL(fileURLWithPath: DockerCLILocator.executablePath)
        process.arguments           = args
        process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
        process.standardOutput      = outPipe
        process.standardError       = errPipe

        // Provide a clean environment with required PATH
        process.environment = [
            "PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:/Applications/Docker.app/Contents/Resources/bin",
            "HOME": FileManager.default.homeDirectoryForCurrentUser.path,
            "DOCKER_HOST": DockerEnvironment.dockerHost,
        ]

        try process.run()

        var outputData = Data()
        var errorData  = Data()

        let outputDone = DispatchSemaphore(value: 0)
        DispatchQueue.global(qos: .userInitiated).async {
            outputData = outPipe.fileHandleForReading.readDataToEndOfFile()
            outputDone.signal()
        }

        let errorDone = DispatchSemaphore(value: 0)
        DispatchQueue.global(qos: .userInitiated).async {
            errorData = errPipe.fileHandleForReading.readDataToEndOfFile()
            errorDone.signal()
        }

        process.waitUntilExit()
        outputDone.wait()
        errorDone.wait()

        // If exit code is non-zero, surface the stderr message
        if process.terminationStatus != 0 {
            let errMsg = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw ComposeError.commandFailed(errMsg.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return outputData
    }
}

enum ComposeError: Error, LocalizedError {
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .commandFailed(let msg): return msg
        }
    }
}
