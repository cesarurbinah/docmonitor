import Foundation
import AppKit

@Observable
class ServicesViewModel {

    var services: [LocalService] = [
        LocalService(name: "Docker", processName: "Docker", isRunning: false, icon: "shippingbox")
    ]

    private let processService = SystemProcessService()

    func refresh() {
        Task.detached(priority: .utility) {
            let processNames    = await self.processService.runningProcessNames()
            let socketReachable = self.isDockerSocketReachable()
            let runningApps     = NSWorkspace.shared.runningApplications
                .compactMap { $0.localizedName?.lowercased() }

            await MainActor.run {
                for index in self.services.indices {
                    let name = self.services[index].processName.lowercased()

                    let processRunning =
                        runningApps.contains(where: { $0.contains(name) }) ||
                        processNames.contains(where: { $0.lowercased().contains(name) })

                    self.services[index].isRunning = processRunning
                }

                if let index = self.services.indices.first(where: {
                    self.services[$0].processName.lowercased() == "docker"
                }) {
                    self.services[index].isRunning = socketReachable
                }
            }
        }
    }

    private nonisolated func isDockerSocketReachable() -> Bool {
        guard let connection = try? DockerEnvironment.connect() else { return false }
        close(connection.fd)
        return true
    }
}
