import SwiftUI
import AppKit

struct DockerPreferencesView: View {

    @AppStorage(DockerEnvironment.Keys.socketMode)       private var socketMode       = DockerEnvironment.Mode.automatic
    @AppStorage(DockerEnvironment.Keys.socketCustomPath) private var socketCustomPath = ""
    @AppStorage(DockerEnvironment.Keys.cliMode)          private var cliMode          = DockerEnvironment.Mode.automatic
    @AppStorage(DockerEnvironment.Keys.cliCustomPath)    private var cliCustomPath    = ""

    @State private var socketCaption = "Detecting…"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PathPreferenceRow(
                title: "Docker socket",
                description: "Where DocMonitor talks to Docker. Automatic checks Docker Desktop, OrbStack, Colima and Rancher Desktop.",
                placeholder: "~/.colima/default/docker.sock",
                mode: $socketMode,
                customPath: $socketCustomPath,
                automaticCaption: socketCaption,
                validationMessage: validation(for: socketCustomPath, requiresExecutable: false),
                onBrowse: nil
            )

            Divider()

            PathPreferenceRow(
                title: "Docker CLI",
                description: "The docker executable used for Compose and image builds.",
                placeholder: "/opt/homebrew/bin/docker",
                mode: $cliMode,
                customPath: $cliCustomPath,
                automaticCaption: DockerEnvironment.automaticCLIPath.map { "In use: \($0)" } ?? "Docker CLI not found",
                validationMessage: validation(for: cliCustomPath, requiresExecutable: true),
                onBrowse: chooseCLI
            )

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task { await refreshSocketCaption() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task { await refreshSocketCaption() }
        }
    }

    private func refreshSocketCaption() async {
        let path = await Task.detached { DockerEnvironment.detectAutomaticSocket() }.value
        socketCaption = path.map { "In use: \($0)" } ?? "No running Docker found"
    }

    private func validation(for rawPath: String, requiresExecutable: Bool) -> String? {
        let path = DockerEnvironment.expandedPath(rawPath)
        guard !path.isEmpty else { return "Enter a path." }
        if requiresExecutable {
            return FileManager.default.isExecutableFile(atPath: path) ? nil : "File not found or not executable."
        }
        return FileManager.default.fileExists(atPath: path) ? nil : "No file at this path."
    }

    private func chooseCLI() {
        let panel = NSOpenPanel()
        panel.canChooseFiles          = true
        panel.canChooseDirectories    = false
        panel.allowsMultipleSelection = false
        panel.showsHiddenFiles        = true
        panel.message                 = "Select the docker executable"
        if panel.runModal() == .OK, let url = panel.url {
            cliCustomPath = url.path
        }
    }
}

private struct PathPreferenceRow: View {
    let title: String
    let description: String
    let placeholder: String
    @Binding var mode: DockerEnvironment.Mode
    @Binding var customPath: String
    let automaticCaption: String
    let validationMessage: String?
    let onBrowse: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PreferenceRow(title: title, description: description) {
                Picker(title, selection: $mode) {
                    ForEach(DockerEnvironment.Mode.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 110)
            }

            switch mode {
            case .automatic:
                Text(automaticCaption)
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            case .custom:
                HStack(spacing: 8) {
                    TextField(placeholder, text: $customPath)
                        .textFieldStyle(.roundedBorder)
                    if let onBrowse {
                        Button("Choose…", action: onBrowse)
                    }
                }
                if let validationMessage {
                    Text(validationMessage)
                        .font(AppFont.caption)
                        .foregroundStyle(.red)
                }
            }
        }
    }
}
