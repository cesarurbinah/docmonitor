import SwiftUI
import AppKit

// Centers the MenuBarExtra window under its status item icon.
struct CenterUnderStatusItem: NSViewRepresentable {

    func makeNSView(context: Context) -> NSView { CenteringView() }
    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class CenteringView: NSView {

        private var observers: [NSObjectProtocol] = []

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()

            observers.forEach(NotificationCenter.default.removeObserver)
            observers.removeAll()
            guard let panel = window else { return }

            let names: [Notification.Name] = [
                NSWindow.didMoveNotification,
                NSWindow.didResizeNotification,
                NSWindow.didBecomeKeyNotification
            ]
            observers = names.map { name in
                NotificationCenter.default.addObserver(
                    forName: name, object: panel, queue: .main
                ) { [weak self] _ in
                    MainActor.assumeIsolated { self?.recenter() }
                }
            }

            recenter()
            DispatchQueue.main.async { [weak self] in self?.recenter() }
        }

        private func recenter() {
            guard let panel = window,
                  let statusWindow = NSApp.windows.first(where: {
                      $0.className.contains("NSStatusBarWindow")
                  }) else { return }

            var x = statusWindow.frame.midX - panel.frame.width / 2

            // Keep the panel inside the screen (icon near the right edge)
            if let visible = (statusWindow.screen ?? panel.screen)?.visibleFrame {
                x = min(max(x, visible.minX + 8), visible.maxX - panel.frame.width - 8)
            }

            // Also stops the move notification from looping on itself
            guard abs(panel.frame.origin.x - x) > 0.5 else { return }
            panel.setFrameOrigin(NSPoint(x: x, y: panel.frame.origin.y))
        }
    }
}
