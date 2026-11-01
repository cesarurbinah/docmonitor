import Foundation

nonisolated enum DockerCLILocator {
    static var executablePath: String { DockerEnvironment.cliPath }
}
