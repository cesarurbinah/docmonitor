import Foundation

nonisolated enum UpdateError: LocalizedError {
    case invalidResponse
    case noReleases
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:      return "Couldn't read GitHub's response."
        case .noReleases:           return "No published releases were found."
        case .httpStatus(let code): return "GitHub returned status \(code)."
        }
    }
}

nonisolated struct LatestRelease {
    let tag: String
    let url: URL
}

nonisolated struct UpdateService {

    static let latestReleaseURL = URL(string: "https://github.com/cessadev/docmonitor/releases/latest")!

    // Follows GitHub's `releases/latest` redirect, which ends on `/releases/tag/<tag>`.
    // Unlike the REST API, this isn't capped at 60 requests/hour per IP.
    func fetchLatestRelease() async throws -> LatestRelease {
        var request = URLRequest(url: Self.latestReleaseURL)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, let finalURL = http.url else {
            throw UpdateError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw UpdateError.httpStatus(http.statusCode)
        }

        // With no releases, GitHub redirects to the releases list instead of a tag page
        let parts = finalURL.pathComponents
        guard parts.contains("tag"), let tag = parts.last, tag != "tag" else {
            throw UpdateError.noReleases
        }
        return LatestRelease(tag: tag, url: finalURL)
    }
}
