import SwiftUI

enum PreferenceKey {
    static let alwaysExpandImages    = "alwaysExpandImages"
    static let refreshInterval       = "refreshInterval"
    static let showUntaggedImages    = "showUntaggedImages"
    static let showStoppedContainers = "showStoppedContainers"
}

enum PreferenceDefault {
    static let refreshInterval = 5
    static let showStoppedContainers = true
}

enum PreferencesPane: String, CaseIterable, Identifiable {
    case general
    case docker
    case containersImages
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general:          return "General"
        case .docker:           return "Docker"
        case .containersImages: return "Containers & Images"
        case .about:            return "About"
        }
    }

    var icon: String {
        switch self {
        case .general:          return "gearshape"
        case .docker:           return "shippingbox"
        case .containersImages: return "square.stack.3d.up"
        case .about:            return "info.circle"
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
            .navigationSplitViewColumnWidth(min: 190, ideal: 190, max: 190)
        } detail: {
            detail(for: selection ?? .general)
                .navigationTitle((selection ?? .general).title)
        }
        .toolbar(removing: .sidebarToggle)
        .frame(width: 660, height: 420)
    }

    @ViewBuilder
    private func detail(for pane: PreferencesPane) -> some View {
        switch pane {
        case .general:
            GeneralPreferencesView()
        case .docker:
            DockerPreferencesView()
        case .containersImages:
            ContainersImagesPreferencesView()
        case .about:
            AboutPreferencesView()
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
