import SwiftUI

struct ContentView: View {

    @State private var servicesVM                  = ServicesViewModel()
    @State private var containersVM                = ContainersViewModel()
    @State private var imagesVM                    = ImagesViewModel()
    @State private var isVisible                   = false
    @State private var pullImageName               = ""
    @State private var composeVM                   = ComposeViewModel()
    @State private var isComposeBusy               = false
    @State private var buildVM                     = BuildViewModel()
    
    @AppStorage("imagesExpanded") private var imagesExpanded = false
    @AppStorage("pullExpanded")   private var pullExpanded   = false
    @AppStorage("buildExpanded") private var buildExpanded   = false
    @AppStorage(PreferenceKey.showStoppedContainers) private var showStoppedContainers = PreferenceDefault.showStoppedContainers
    @AppStorage(PreferenceKey.refreshInterval) private var refreshInterval = PreferenceDefault.refreshInterval
    
    @Environment(\.openWindow) private var openWindow
    @AppStorage(PreferenceKey.alwaysExpandImages) private var alwaysExpandImages = false
    
    // The full list still drives image locks and name checks; this only affects what is shown
    private var visibleContainers: [DockerContainer] {
        showStoppedContainers ? containersVM.containers : containersVM.containers.filter(\.isRunning)
    }

    var body: some View {
        ZStack {
            Color.clear

            VStack(alignment: .leading, spacing: 0) {

                // Header
                HStack(spacing: 8) {
                    Text("DocMonitor")
                        .font(AppFont.title)
                    Spacer()
                    Button {
                        refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.glass)
                    .controlSize(.small)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                // Local Services
                ServicesView(services: servicesVM.services)
                
                if !buildExpanded && !pullExpanded {
                    // Containers
                    if !visibleContainers.isEmpty {
                        ContainersView(
                            containers: visibleContainers,
                            lockedComposeProject: composeVM.lockedComposeProject,
                            activeComposeProjects: composeVM.activeComposeProjects,
                            onToggle: { container in await containersVM.toggle(container) },
                            onDelete: { container in await containersVM.delete(container) },
                            onOpenTerminal: { container in containersVM.openTerminal(for: container) }
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // Compose Projects
                    ComposeView(
                        projects: composeVM.projects,
                        loadingProjectId: composeVM.isLoadingProjectId,
                        onUp: { project in
                            isComposeBusy = true
                            await composeVM.up(project)
                            await containersVM.refresh()
                            isComposeBusy = false
                        },
                        onDown: { project in
                            isComposeBusy = true
                            await composeVM.down(project)
                            await containersVM.refresh()
                            isComposeBusy = false
                        },
                        onRemove:    { project in composeVM.remove(project) },
                        onAddManual: { composeVM.addManualProject() }
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Images
                ImagesView(
                    images: imagesVM.images,
                    lockedImageIds: containersVM.imageIdsInUse,
                    count: imagesVM.images.count,
                    isExpanded: imagesExpanded,
                    pullExpanded: pullExpanded,
                    pullImageName: $pullImageName,
                    isPulling: imagesVM.isPulling,
                    pullProgress: imagesVM.pullProgress,
                    onHeaderTap: {
                        withAnimation(.spring(duration: 0.35, bounce: 0.3)) {
                            imagesExpanded.toggle()
                            if !imagesExpanded {
                                pullExpanded  = false
                                pullImageName = ""
                            }
                        }
                    },
                    onPullHeaderTap: {
                        withAnimation(.spring(duration: 0.35, bounce: 0.3)) {
                            pullExpanded.toggle()
                        }
                    },
                    onPull: {
                        Task { await imagesVM.pull(name: pullImageName) }
                    },
                    onDelete: {
                        image in await imagesVM.delete(image)
                    },
                    buildExpanded: buildExpanded,
                    buildVM: buildVM,
                    onBuildHeaderTap: {
                        withAnimation(.spring(duration: 0.35, bounce: 0.3)) {
                            if buildExpanded { buildVM.reset() }
                            buildExpanded.toggle()
                        }
                    },
                    onCreateContainer: { image, name, ports, envVars, restartPolicy in
                        return await containersVM.createContainer(
                            name: name,
                            imageName: image.reference,
                            portBindings: ports,
                            envVars: envVars,
                            restartPolicy: restartPolicy
                        )
                    }
                )

                // Error
                if let error = containersVM.error ?? imagesVM.error {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .padding(10)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
                }

                // Footer
                HStack {
                    Button {
                        openWindow(id: "preferences")
                        NSApp.activate()
                    } label: {
                        Text("Preferences")
                            .font(AppFont.action)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(CapsuleButtonStyle())

                    Spacer()

                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        Text("Quit")
                            .font(AppFont.action)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(CapsuleButtonStyle())
                    .keyboardShortcut("q")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .frame(width: 308)
        .fixedSize(horizontal: false, vertical: true)
        .scaleEffect(isVisible ? 1.0 : 0.92)
        .opacity(isVisible ? 1.0 : 0)
        .animation(.spring(duration: 0.35, bounce: 0.15), value: imagesVM.images.count)
        .animation(.spring(duration: 0.35, bounce: 0.15), value: imagesExpanded)
        .animation(.spring(duration: 0.35, bounce: 0.15), value: pullExpanded)
        .animation(.spring(duration: 0.35, bounce: 0.15), value: buildExpanded)
        .animation(isVisible
            ? .spring(duration: 0.3, bounce: 0.2)
            : .easeIn(duration: 0.15),
            value: isVisible
        )
        .onChange(of: buildVM.buildSuccess) { _, success in
            if success {
                withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
                    buildExpanded = false
                    buildVM.reset()
                }
            }
        }
        .onChange(of: imagesVM.pullSuccess) { _, success in
            if success {
                withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
                    pullExpanded  = false
                    pullImageName = ""
                }
            }
        }
        .onAppear {
            isVisible = true
            imagesExpanded = alwaysExpandImages
            if !alwaysExpandImages {
                pullExpanded  = false
                buildExpanded = false
            }
            composeVM.persistProjects()
            refresh()
        }
        .onDisappear {
            isVisible = false
            pullImageName = ""
            buildVM.reset()
            NSApp.keyWindow?.makeFirstResponder(nil)
        }
        .task(id: refreshInterval) {
            let seconds = max(refreshInterval, 1)
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(seconds))
                guard !Task.isCancelled, !isComposeBusy else { continue }
                refresh()
            }
        }
    }

    private func refresh() {
        servicesVM.refresh()
        Task {
            async let containers: () = containersVM.refresh()
            async let images: ()     = imagesVM.refresh()
            async let compose: ()    = composeVM.refresh()
            await containers
            await images
            await compose
        }
    }
}
