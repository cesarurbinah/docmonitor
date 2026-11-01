import SwiftUI

struct GeneralPreferencesView: View {

    @AppStorage(PreferenceKey.alwaysExpandImages) private var alwaysExpandImages = false
    @AppStorage(PreferenceKey.refreshInterval)    private var refreshInterval    = PreferenceDefault.refreshInterval
    @State private var launchVM = LaunchAtLoginViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PreferenceRow(
                title: "Always expand Docker Images",
                description: "Show the images section expanded every time DocMonitor opens."
            ) {
                Toggle("Always expand Docker Images", isOn: $alwaysExpandImages)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }

            Divider()

            PreferenceRow(
                title: "Refresh interval",
                description: "How often DocMonitor refreshes Docker data automatically."
            ) {
                Picker("Refresh interval", selection: $refreshInterval) {
                    ForEach([2, 5, 10, 30], id: \.self) { seconds in
                        Text("\(seconds) s").tag(seconds)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 90)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                PreferenceRow(
                    title: "Launch at login",
                    description: "Open DocMonitor automatically when you log in to your Mac."
                ) {
                    Toggle("Launch at login", isOn: Binding(
                        get: { launchVM.isEnabled },
                        set: { newValue in Task { await launchVM.setEnabled(newValue) } }
                    ))
                    .labelsHidden()
                    .toggleStyle(.switch)
                }

                launchNotice
            }

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task { await launchVM.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task { await launchVM.refresh() }
        }
    }

    @ViewBuilder
    private var launchNotice: some View {
        if launchVM.needsApproval {
            HStack(spacing: 8) {
                Text("macOS needs your approval to launch DocMonitor at login.")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                Button("Open Login Items Settings") {
                    launchVM.openLoginItemsSettings()
                }
                .controlSize(.small)
            }
        } else if let message = launchVM.errorMessage {
            Text(message)
                .font(AppFont.caption)
                .foregroundStyle(.red)
        }
    }
}
