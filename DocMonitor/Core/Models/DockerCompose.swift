import Foundation

struct DockerComposeProject: Identifiable {
    let id = UUID()
    let name: String
    let filePath: String
    var serviceStatuses: [String: ComposeServiceStatus] = [:]

    enum ComposeServiceStatus {
        case running
        case stopped
        case partial
    }

    var overallStatus: ComposeServiceStatus {
        guard !serviceStatuses.isEmpty else { return .stopped }
        let statuses = serviceStatuses.values
        if statuses.allSatisfy({ $0 == .running })  { return .running }
        if statuses.allSatisfy({ $0 == .stopped })  { return .stopped }
        return .partial
    }

    var displayName: String {
        URL(fileURLWithPath: filePath)
            .deletingLastPathComponent()
            .lastPathComponent
    }
    
    private var standardizedFilePath: String {
        URL(fileURLWithPath: filePath).standardizedFileURL.path
    }

    // Matches by file path, not by folder name: Compose normalizes project names
    func owns(_ container: DockerContainer) -> Bool {
        guard container.composeProject != nil, !container.isComposeOneOff else { return false }

        if let files = container.composeConfigFiles {
            return files.contains { URL(fileURLWithPath: $0).standardizedFileURL.path == standardizedFilePath }
        }
        // Fallback if the label is missing
        let directory = URL(fileURLWithPath: standardizedFilePath).deletingLastPathComponent().path
        return container.composeWorkingDir == directory
    }

    // Per-service status derived from the containers that belong to this project
    func statuses(from containers: [DockerContainer]) -> [String: ComposeServiceStatus] {
        var byService: [String: [DockerContainer]] = [:]
        for container in containers where owns(container) {
            guard let service = container.composeService else { continue }
            byService[service, default: []].append(container)
        }
        return byService.mapValues { (replicas: [DockerContainer]) -> ComposeServiceStatus in
            if replicas.allSatisfy(\.isRunning)       { return .running }
            if replicas.contains(where: \.isRunning)  { return .partial }
            return .stopped
        }
    }

    // Real Compose project name, as the label carries it
    func composeProjectName(from containers: [DockerContainer]) -> String? {
        containers.first(where: { owns($0) })?.composeProject
    }
}
