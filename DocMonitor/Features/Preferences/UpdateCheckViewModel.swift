import Foundation

@Observable
final class UpdateCheckViewModel {

    enum State: Equatable {
        case idle
        case checking
        case upToDate
        case updateAvailable(version: String, url: URL)
        case failed(String)
    }

    private(set) var state: State = .idle

    let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    let currentBuild   = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"

    private let service = UpdateService()

    @MainActor
    func check() async {
        state = .checking
        do {
            let release = try await service.fetchLatestRelease()
            let remote  = release.tag.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))

            // `.numeric` compares each dot-separated segment as a number (1.0.10 > 1.0.9)
            if remote.compare(currentVersion, options: .numeric) == .orderedDescending {
                state = .updateAvailable(version: remote, url: release.url)
            } else {
                state = .upToDate
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
