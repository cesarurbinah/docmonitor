import SwiftUI

struct ComposePreferencesView: View {

    @AppStorage(ComposeProjectStore.enabledKey) private var persistProjects = ComposeProjectStore.defaultEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PreferenceRow(
                title: "Remember Compose projects",
                description: "Keep the Compose files you add listed after you quit and reopen DocMonitor. Only the file locations are saved, and turning this off clears them."
            ) {
                Toggle("Remember Compose projects", isOn: $persistProjects)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onChange(of: persistProjects) { _, isOn in
            if !isOn { ComposeProjectStore.clear() }
        }
    }
}
