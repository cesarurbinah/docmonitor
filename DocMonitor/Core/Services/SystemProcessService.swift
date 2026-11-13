import Foundation
import AppKit

nonisolated class SystemProcessService {

    func runningProcessNames() -> [String] {
        let process = Process()
        let pipe    = Pipe()
        process.executableURL  = URL(fileURLWithPath: "/bin/ps")
        process.arguments      = ["-eo", "comm"]
        process.standardOutput = pipe

        do { try process.run() } catch { return [] }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        let output = String(data: data, encoding: .utf8) ?? ""
        return output.components(separatedBy: "\n").filter { !$0.isEmpty }
    }
}
