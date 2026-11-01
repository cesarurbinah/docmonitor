import SwiftUI

struct ContainersImagesPreferencesView: View {

    @AppStorage(RestartPolicy.defaultsKey)           private var defaultRestartPolicy  = RestartPolicy.no
    @AppStorage(PreferenceKey.showUntaggedImages)    private var showUntaggedImages    = false
    @AppStorage(PreferenceKey.showStoppedContainers) private var showStoppedContainers = PreferenceDefault.showStoppedContainers

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PreferenceRow(
                title: "Show stopped containers",
                description: "Include stopped containers in the list. When off, only running containers are shown; stopped ones still exist in Docker."
            ) {
                Toggle("Show stopped containers", isOn: $showStoppedContainers)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }

            Divider()

            PreferenceRow(
                title: "Show untagged images",
                description: "Include images without a name or tag, such as the old version left behind after rebuilding an image. Useful to find and delete them."
            ) {
                Toggle("Show untagged images", isOn: $showUntaggedImages)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }

            Divider()

            PreferenceRow(
                title: "Default restart policy",
                description: "Restart policy preselected when you create a container. You can still change it for each container."
            ) {
                Picker("Default restart policy", selection: $defaultRestartPolicy) {
                    ForEach(RestartPolicy.allCases) { policy in
                        Text(policy.label).tag(policy)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 150)
            }

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
