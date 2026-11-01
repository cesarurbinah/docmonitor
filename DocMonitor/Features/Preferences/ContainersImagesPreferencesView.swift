import SwiftUI

struct ContainersImagesPreferencesView: View {

    @AppStorage(RestartPolicy.defaultsKey)        private var defaultRestartPolicy = RestartPolicy.no
    @AppStorage(PreferenceKey.showUntaggedImages) private var showUntaggedImages   = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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

            Divider()

            PreferenceRow(
                title: "Show untagged images",
                description: "Include images without a name or tag, such as the old version left behind after rebuilding an image. Useful to find and delete them."
            ) {
                Toggle("Show untagged images", isOn: $showUntaggedImages)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
