import SwiftUI

struct AboutPreferencesView: View {

    @State private var updateVM = UpdateCheckViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 2) {
                    Text("DocMonitor")
                        .font(.title2.weight(.semibold))
                    Text("Version \(updateVM.currentVersion) (\(updateVM.currentBuild))")
                        .font(AppFont.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                PreferenceRow(
                    title: "Check for updates",
                    description: "Looks for a newer release on GitHub when you press the button. DocMonitor doesn't update itself: you download and install new versions manually."
                ) {
                    Button("Check for updates") {
                        Task { await updateVM.check() }
                    }
                    .disabled(updateVM.state == .checking)
                }

                updateResult
            }
            
            Divider()

            PreferenceRow(
                title: "Source code",
                description: "Browse the repository, report issues and read the contributing guide on GitHub."
            ) {
                Button("Open") {
                    NSWorkspace.shared.open(AppLinks.repository)
                }
            }

            Divider()

            PreferenceRow(
                title: "License",
                description: "Released under PolyForm Strict 1.0.0. The source is available, but it isn't an open-source license: read it for what you can and can't do."
            ) {
                Button("View license") {
                    NSWorkspace.shared.open(AppLinks.license)
                }
            }

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var updateResult: some View {
        switch updateVM.state {
        case .idle:
            EmptyView()

        case .checking:
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text("Checking…")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
            }

        case .upToDate:
            Text("You're up to date.")
                .font(AppFont.caption)
                .foregroundStyle(.secondary)

        case .updateAvailable(let version, let url):
            HStack(spacing: 8) {
                Text("Version \(version) is available.")
                    .font(AppFont.caption)
                Button("View release") {
                    NSWorkspace.shared.open(url)
                }
                .controlSize(.small)
            }
            Text("Download the .zip from the release page and follow the installation steps in the README.")
                .font(AppFont.caption)
                .foregroundStyle(.secondary)

        case .failed(let message):
            Text(message)
                .font(AppFont.caption)
                .foregroundStyle(.red)
        }
    }
}
