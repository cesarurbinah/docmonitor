import SwiftUI

struct GeneralPreferencesView: View {

    @AppStorage(PreferenceKey.alwaysExpandImages) private var alwaysExpandImages = false
    @AppStorage(PreferenceKey.refreshInterval)    private var refreshInterval    = PreferenceDefault.refreshInterval

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

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
