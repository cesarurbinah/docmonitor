import SwiftUI

enum PreferenceKey {
    static let alwaysExpandImages = "alwaysExpandImages"
    static let refreshInterval    = "refreshInterval"
}

enum PreferenceDefault {
    static let refreshInterval = 5
}

enum PreferencesPane: String, CaseIterable, Identifiable {
    case general
    case docker
    case containersImages

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general:          return "General"
        case .docker:           return "Docker"
        case .containersImages: return "Containers & Images"
        }
    }

    var icon: String {
        switch self {
        case .general:          return "gearshape"
        case .docker:           return "shippingbox"
        case .containersImages: return "square.stack.3d.up"
        }
    }
}

struct PreferencesView: View {

    @State private var selection: PreferencesPane? = .general

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(PreferencesPane.allCases) { pane in
                    Label(pane.title, systemImage: pane.icon)
                        .tag(pane)
                }
            }
            .navigationSplitViewColumnWidth(190)
            .onGeometryChange(for: CGSize.self) { $0.size } action: { print("SIDEBAR:", $0) }
        } detail: {
            detail(for: selection ?? .general)
                .onGeometryChange(for: CGSize.self) { $0.size } action: { print("DETAIL:", $0) }
        }
        .frame(width: 660, height: 420)
        .onGeometryChange(for: CGSize.self) { $0.size } action: { print("SPLIT:", $0) }
        .onAppear {
            print("WINDOWS:", NSApp.windows.map { "\($0.title) \($0.frame)" })
        }
    }

    @ViewBuilder
    private func detail(for pane: PreferencesPane) -> some View {
        switch pane {
        case .general:
            GeneralPreferencesView()
        case .docker, .containersImages:
            ContentUnavailableView(
                "No settings yet",
                systemImage: pane.icon,
                description: Text("Options for \(pane.title) will appear here.")
            )
        }
    }
}

struct PreferenceRow<Control: View>: View {
    let title: String
    let description: String
    @ViewBuilder let control: () -> Control

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.body)
                Text(description)
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            control()
        }
    }
}
