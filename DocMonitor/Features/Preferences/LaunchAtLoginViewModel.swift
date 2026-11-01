import SwiftUI
import ServiceManagement

@Observable
final class LaunchAtLoginViewModel {

    private(set) var status: SMAppService.Status = .notRegistered
    private(set) var errorMessage: String?

    var isEnabled: Bool    { status == .enabled }
    var needsApproval: Bool { status == .requiresApproval }

    @MainActor
    func refresh() async {
        status = await Task.detached { SMAppService.mainApp.status }.value
    }

    @MainActor
    func setEnabled(_ enabled: Bool) async {
        do {
            try await Task.detached {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            }.value
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        await refresh()
    }

    func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
