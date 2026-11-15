import Foundation

struct DockerContainer: Identifiable, Decodable {
    let id: String
    let names: [String]
    let image: String
    let imageId: String
    let state: String
    let status: String
    let labels: [String: String]

    enum CodingKeys: String, CodingKey {
        case id      = "Id"
        case names   = "Names"
        case image   = "Image"
        case imageId = "ImageID"
        case state   = "State"
        case status  = "Status"
        case labels  = "Labels"
    }

    var displayName: String {
        names.first?.replacingOccurrences(of: "/", with: "") ?? id
    }

    var isRunning: Bool { state == "running" }
    
    // Docker Compose project name as assigned internally by Compose
    var composeProject: String? {
        labels["com.docker.compose.project"]
    }
    
    var composeService: String? { labels["com.docker.compose.service"] }

    var composeWorkingDir: String? { labels["com.docker.compose.project.working_dir"] }

    // Comma-separated absolute paths of the files the project was started with
    var composeConfigFiles: [String]? {
        guard let raw = labels["com.docker.compose.project.config_files"], !raw.isEmpty else { return nil }
        return raw.split(separator: ",").map(String.init)
    }

    // Containers created by `docker compose run` are not part of the project's services
    var isComposeOneOff: Bool { labels["com.docker.compose.oneoff"]?.lowercased() == "true" }
}
