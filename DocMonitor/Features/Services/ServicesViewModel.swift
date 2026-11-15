import Foundation

@Observable
class ServicesViewModel {

    var services: [LocalService] = [
        LocalService(name: "Docker", isRunning: false, icon: "shippingbox")
    ]

    func refresh() {
        Task {
            let responding = await DockerClient.shared.isDaemonResponding()

            // Docker is the only service for now: "running" means the engine answers /_ping
            if let index = services.firstIndex(where: { $0.name == "Docker" }) {
                services[index].isRunning = responding
            }
        }
    }
}
