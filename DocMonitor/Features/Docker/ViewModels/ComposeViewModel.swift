import Foundation
import AppKit
import UniformTypeIdentifiers

@Observable
class ComposeViewModel {

    var projects: [DockerComposeProject] = []
    var error: String?
    var isLoadingProjectId: UUID?
    
    private let dockerClient = DockerClient.shared

    // filePath -> real Compose project name (known only while the project has containers)
    private var resolvedNames: [String: String] = [:]

    private func composeName(for project: DockerComposeProject) -> String {
        resolvedNames[project.filePath] ?? project.displayName.lowercased()
    }

    var lockedComposeProject: String? {
        guard let loadingId = isLoadingProjectId,
              let project   = projects.first(where: { $0.id == loadingId }) else {
            return nil
        }
        return composeName(for: project)
    }

    var activeComposeProjects: Set<String> {
        Set(
            projects
                .filter { $0.overallStatus == .running || $0.overallStatus == .partial }
                .map { composeName(for: $0) }
        )
    }
    
    init() {
        let saved = ComposeProjectStore.load()
            .filter { FileManager.default.fileExists(atPath: $0) }

        manualPaths = Set(saved)
        projects    = saved
            .map { path in
                DockerComposeProject(
                    name: URL(fileURLWithPath: path).deletingLastPathComponent().lastPathComponent,
                    filePath: path
                )
            }
            .sorted { $0.displayName.lowercased() < $1.displayName.lowercased() }
    }
    
    private var manualPaths = Set<String>()

    private let composeService = ComposeService.shared

    private func performBlocking<T: Sendable>(_ work: @escaping @Sendable () -> T) async -> T {
        await Task.detached(priority: .userInitiated, operation: work).value
    }
    
    @MainActor
    func persistProjects() {
        ComposeProjectStore.save(Array(manualPaths))
    }

    @MainActor
    func refresh() async {
        // If Docker is unreachable, ContainersViewModel already surfaces the error; here it just means "no containers"
        let containers = (try? await dockerClient.fetchContainers()) ?? []
        apply(containers)
    }

    // Pure derivation from an already-fetched list: no I/O, so callers that just refreshed containers can reuse it
    @MainActor
    func apply(_ containers: [DockerContainer]) {
        for index in projects.indices {
            let project = projects[index]
            projects[index].serviceStatuses = project.statuses(from: containers)
            resolvedNames[project.filePath] = project.composeProjectName(from: containers)
        }
    }

    @MainActor
    func up(_ project: DockerComposeProject) async {
        isLoadingProjectId = project.id
        error = nil
        NSApp.setActivationPolicy(.regular)

        let service = composeService
        let failure: String? = await performBlocking {
            do { try service.up(project: project); return nil }
            catch { return error.localizedDescription }
        }
        if let failure { error = failure }

        try? await Task.sleep(nanoseconds: DockerSettleDelay.composeUp)
        NSApp.setActivationPolicy(.accessory)
        await refresh()
        isLoadingProjectId = nil
    }

    @MainActor
    func down(_ project: DockerComposeProject) async {
        isLoadingProjectId = project.id
        error = nil

        let service = composeService
        let failure: String? = await performBlocking {
            do { try service.down(project: project); return nil }
            catch { return error.localizedDescription }
        }
        if let failure { error = failure }

        try? await Task.sleep(nanoseconds: DockerSettleDelay.composeDown)
        await refresh()
        isLoadingProjectId = nil
    }
    
    @MainActor
    func remove(_ project: DockerComposeProject) {
        projects.removeAll { $0.id == project.id }
        manualPaths.remove(project.filePath)
        persistProjects()
    }

    // Add a project manually via file picker
    @MainActor
    func addManualProject() {
        let panel = NSOpenPanel()
        panel.title                 = "Select a Compose file"
        panel.allowedContentTypes   = [.yaml]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories  = false
        panel.canChooseFiles        = true

        // Bring the app to front so the panel gets proper focus
        NSApp.activate(ignoringOtherApps: true)

        panel.begin { [weak self] response in
            guard let self,
                  response == .OK,
                  let url = panel.url else { return }

            let project = DockerComposeProject(
                name: url.deletingLastPathComponent().lastPathComponent,
                filePath: url.path
            )

            // Avoid duplicates
            guard !self.manualPaths.contains(url.path) else { return }
            self.manualPaths.insert(url.path)

            Task { @MainActor in
                self.projects.append(project)
                self.projects.sort { $0.displayName.lowercased() < $1.displayName.lowercased() }
                self.persistProjects()
                await self.refresh()
            }
        }
    }
}
