import SwiftUI

enum PreferenceKey {
    static let alwaysExpandImages = "alwaysExpandImages"
}

struct PreferencesView: View {

    @AppStorage(PreferenceKey.alwaysExpandImages) private var alwaysExpandImages = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Always expand Docker Images")
                        .font(AppFont.body)
                    Text("Show the images section expanded every time DocMonitor opens.")
                        .font(AppFont.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle("Always expand Docker Images", isOn: $alwaysExpandImages)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}
