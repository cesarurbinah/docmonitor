import SwiftUI
import AppKit

@main
struct DocMonitorApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("DocMonitor", image: "MenuBarIcon") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
        
        Window("Preferences", id: "preferences") {
            PreferencesView()
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // Observe TCC permission dialogs to prevent panel dismissal
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func appDidBecomeActive() {
        // Re-assert accessory policy after any modal (TCC or otherwise)
        // takes and returns focus
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
