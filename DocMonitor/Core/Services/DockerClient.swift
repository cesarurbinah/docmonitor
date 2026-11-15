import Foundation

class DockerClient {

    static let shared = DockerClient()
    
    private static let jsonDecoder = JSONDecoder()

    // MARK: - Containers
    func fetchContainers() async throws -> [DockerContainer] {
        let response = try await request("GET /containers/json?all=true HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n", timeout: 5)
        return try decode([DockerContainer].self, from: response.body)
    }

    func startContainer(id: String) async throws {
        try await request("POST /containers/\(id)/start HTTP/1.1\r\nHost: localhost\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")
    }

    func stopContainer(id: String) async throws {
        try await request("POST /containers/\(id)/stop HTTP/1.1\r\nHost: localhost\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")
    }

    func deleteContainer(id: String) async throws {
        try await request("DELETE /containers/\(id)?force=true HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n")
    }
    
    func createContainer(
        name: String,
        imageName: String,
        portBindings: [String],
        envVars: [String],
        restartPolicy: String
    ) async throws {
        let containerName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name

        // Build PortBindings: {"80/tcp": [{"HostPort": "8080"}, ...]}
        // Accepts "host:container", "host:container/udp" and "hostIP:host:container"
        var bindingsByKey: [String: [CreateContainerRequestBody.HostBinding]] = [:]
        var exposedPorts: [String: CreateContainerRequestBody.EmptyObject]    = [:]
        for binding in portBindings where !binding.trimmingCharacters(in: .whitespaces).isEmpty {
            let parts = binding.components(separatedBy: ":").map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2 || parts.count == 3 else { continue }

            let hostIP: String?
            let hostPort: String
            let containerPart: String
            if parts.count == 3 {
                hostIP        = parts[0]
                hostPort      = parts[1]
                containerPart = parts[2]
            } else {
                hostIP        = nil
                hostPort      = parts[0]
                containerPart = parts[1]
            }

            // containerPart may already carry a protocol suffix, e.g. "80/udp"
            let containerProtoParts = containerPart.components(separatedBy: "/")
            let containerPort       = containerProtoParts[0]
            let proto               = containerProtoParts.count > 1
                                     ? containerProtoParts[1].lowercased()
                                     : "tcp"
            let key = "\(containerPort)/\(proto)"

            bindingsByKey[key, default: []].append(
                CreateContainerRequestBody.HostBinding(hostIp: hostIP, hostPort: hostPort)
            )
            exposedPorts[key] = CreateContainerRequestBody.EmptyObject()
        }

        let filteredEnv = envVars.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        let requestBody = CreateContainerRequestBody(
            image: imageName,
            env: filteredEnv,
            exposedPorts: exposedPorts,
            hostConfig: .init(
                portBindings: bindingsByKey,
                restartPolicy: .init(name: restartPolicy)
            )
        )

        let bodyData  = try JSONEncoder().encode(requestBody)
        let bodyJSON  = String(data: bodyData, encoding: .utf8) ?? "{}"
        let bodyBytes = bodyData.count

        let httpRequest = "POST /containers/create?name=\(containerName) HTTP/1.1\r\n" +
                          "Host: localhost\r\n" +
                          "Content-Type: application/json\r\n" +
                          "Content-Length: \(bodyBytes)\r\n" +
                          "Connection: close\r\n\r\n" +
                          bodyJSON

        let response = try await send(httpRequest)
        switch response.status {
        case 201: return
        case 404: throw DockerError.requestFailed("Image '\(imageName)' not found locally")
        case 409: throw DockerError.requestFailed("Container name '\(name)' already exists")
        default:  try response.requireSuccess()
        }
    }
    
    // MARK: - Images
    func fetchImages() async throws -> [DockerImage] {
        let response = try await request("GET /images/json HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n", timeout: 5)
        return try decode([DockerImage].self, from: response.body)
    }
    
    func deleteImage(id: String) async throws {
        try await request("DELETE /images/\(id)?force=false HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n")
    }
    
    func pullImage(name: String, onProgress: @escaping @MainActor (String) -> Void) async throws {
        let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        let request = "POST /images/create?fromImage=\(encoded) HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n"

        try await performBlocking {
            let fd = try self.openDockerSocket()
            defer { close(fd) }

            var requestBytes = Array(request.utf8)
            guard write(fd, &requestBytes, requestBytes.count) >= 0 else {
                throw DockerError.connectionFailed
            }

            var headerBuffer = Data()
            var bigBuffer    = [UInt8](repeating: 0, count: 4096)
            let separator    = Data("\r\n\r\n".utf8)

            while !headerBuffer.contains(separator) {
                let n = read(fd, &bigBuffer, bigBuffer.count)
                if n <= 0 { break }
                headerBuffer.append(contentsOf: bigBuffer[..<n])
            }

            // A non-200 here means the pull never started (e.g. 404 repository not found)
            let head   = String(data: headerBuffer, encoding: .utf8) ?? ""
            let status = Self.statusCode(inHead: head)
            guard status == 200 else {
                var rest = Data()
                while true {
                    let n = read(fd, &bigBuffer, bigBuffer.count)
                    if n <= 0 { break }
                    rest.append(contentsOf: bigBuffer[..<n])
                }
                let body = headerBuffer.range(of: separator).map { headerBuffer[$0.upperBound...] } ?? Data()
                let raw  = String(data: body + rest, encoding: .utf8) ?? ""
                let message = raw
                    .components(separatedBy: "\n")
                    .compactMap { line -> String? in
                        guard let data = line.data(using: .utf8) else { return nil }
                        return (try? Self.jsonDecoder.decode(PullProgressEvent.self, from: data))?.message
                    }
                    .first
                throw DockerError.requestFailed(message ?? "Docker returned status \(status)")
            }

            var pullFailure: String?
            var lineBuffer = ""
            var readBuf    = [UInt8](repeating: 0, count: 512)
            while true {
                let n = read(fd, &readBuf, readBuf.count)
                if n <= 0 { break }
                lineBuffer += String(bytes: readBuf[..<n], encoding: .utf8) ?? ""

                while let newline = lineBuffer.firstIndex(of: "\n") {
                    let line = String(lineBuffer[..<newline]).trimmingCharacters(in: .whitespaces)
                    lineBuffer = String(lineBuffer[lineBuffer.index(after: newline)...])

                    guard line.hasPrefix("{"),
                          let data  = line.data(using: .utf8),
                          let event = try? Self.jsonDecoder.decode(PullProgressEvent.self, from: data) else { continue }

                    if let failure = event.error {
                        pullFailure = failure          // mid-stream failure arrives as {"error": ...}
                    } else if let status = event.status {
                        let progress = event.progress ?? ""
                        let msg      = progress.isEmpty ? status : "\(status) \(progress)"
                        Task { @MainActor in onProgress(msg) }
                    }
                }
            }

            if let pullFailure { throw DockerError.requestFailed(pullFailure) }
        }
    }
    
    // /_ping answers 200 "OK" only when the engine behind the socket is alive
    func isDaemonResponding() async -> Bool {
        guard let response = try? await send("GET /_ping HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n", timeout: 2) else {
            return false
        }
        return response.status == 200
    }

    // One line of the streaming `/images/create` response: progress, a mid-stream error, or an HTTP-level message
    private nonisolated struct PullProgressEvent: Decodable {
        let status: String?
        let progress: String?
        let error: String?
        let message: String?
    }

    private static func decodeChunked(_ data: Data) -> Data {
        var result = Data()
        var index  = data.startIndex
        let crlf   = Data("\r\n".utf8)

        while index < data.endIndex {
            guard let lineEnd = data.range(of: crlf, in: index..<data.endIndex) else { break }

            let sizeLine = String(data: data[index..<lineEnd.lowerBound], encoding: .utf8)?
                .trimmingCharacters(in: .whitespaces) ?? ""
            let hexPart  = sizeLine.components(separatedBy: ";").first ?? sizeLine

            guard let chunkSize = Int(hexPart, radix: 16) else { break }
            if chunkSize == 0 { break }

            let chunkStart = lineEnd.upperBound
            let chunkEnd   = data.index(chunkStart, offsetBy: chunkSize, limitedBy: data.endIndex) ?? data.endIndex

            result.append(data[chunkStart..<chunkEnd])
            index = data.index(chunkEnd, offsetBy: 2, limitedBy: data.endIndex) ?? data.endIndex
        }

        return result
    }

    private func sendRequest(_ httpRequest: String, timeout: Int? = nil) throws -> Data {
        let fd = try openDockerSocket()
        defer { close(fd) }
        if let timeout { UnixSocket.setTimeout(timeout, on: fd) }

        var requestBytes = Array(httpRequest.utf8)
        guard write(fd, &requestBytes, requestBytes.count) >= 0 else {
            throw DockerError.connectionFailed
        }

        var response = Data()
        var buffer   = [UInt8](repeating: 0, count: 8192)
        while true {
            let n = read(fd, &buffer, buffer.count)
            if n < 0, errno == EAGAIN {
                throw DockerError.requestFailed("Docker is not responding")
            }
            if n <= 0 { break }
            response.append(contentsOf: buffer[..<n])
        }

        guard !response.isEmpty else { throw DockerError.emptyResponse }
        return response
    }
    
    private func openDockerSocket() throws -> Int32 {
        do {
            return try DockerEnvironment.connect().fd
        } catch UnixSocketError.notFound {
            throw DockerError.socketNotFound
        } catch {
            throw DockerError.connectionFailed
        }
    }
    
    private struct CreateContainerRequestBody: Encodable {
        struct HostBinding: Encodable {
            let hostIp: String?
            let hostPort: String
            enum CodingKeys: String, CodingKey {
                case hostIp   = "HostIp"
                case hostPort = "HostPort"
            }
        }
        struct RestartPolicy: Encodable {
            let name: String
            enum CodingKeys: String, CodingKey { case name = "Name" }
        }
        struct HostConfig: Encodable {
            let portBindings: [String: [HostBinding]]
            let restartPolicy: RestartPolicy
            enum CodingKeys: String, CodingKey {
                case portBindings  = "PortBindings"
                case restartPolicy = "RestartPolicy"
            }
        }
        // Docker expects `{}` per exposed port key; a property-less struct encodes to an empty JSON object.
        struct EmptyObject: Encodable {}

        let image: String
        let env: [String]
        let exposedPorts: [String: EmptyObject]
        let hostConfig: HostConfig

        enum CodingKeys: String, CodingKey {
            case image        = "Image"
            case env          = "Env"
            case exposedPorts = "ExposedPorts"
            case hostConfig   = "HostConfig"
        }
    }
    
    private func performBlocking<T: Sendable>(
        _ work: @escaping @Sendable () throws -> T
    ) async throws -> T {
        try await Task.detached(priority: .userInitiated) {
            try work()
        }.value
    }
    
    // HTTP response
    private nonisolated struct HTTPResponse {
        let status: Int
        let body: Data

        private struct DaemonErrorBody: Decodable { let message: String }

        // 304 = "already started/stopped": Docker uses it for no-op start/stop
        @discardableResult
        func requireSuccess() throws -> HTTPResponse {
            guard (200..<300).contains(status) || status == 304 else {
                let message = (try? JSONDecoder().decode(DaemonErrorBody.self, from: body))?.message
                throw DockerError.requestFailed(message ?? "Docker returned status \(status)")
            }
            return self
        }
    }

    private nonisolated static func statusCode(inHead head: String) -> Int {
        let statusLine = head.components(separatedBy: "\r\n").first ?? ""
        return Int(statusLine.split(separator: " ").dropFirst().first ?? "") ?? 0
    }

    private nonisolated static func parse(_ raw: Data) throws -> HTTPResponse {
        guard let separator = raw.range(of: Data("\r\n\r\n".utf8)) else {
            throw DockerError.emptyResponse
        }
        let head      = String(data: raw[..<separator.lowerBound], encoding: .utf8) ?? ""
        let rawBody   = Data(raw[separator.upperBound...])
        let isChunked = head.lowercased().contains("transfer-encoding: chunked")
        return HTTPResponse(
            status: statusCode(inHead: head),
            body: isChunked ? decodeChunked(rawBody) : rawBody
        )
    }

    private func send(_ httpRequest: String, timeout: Int? = nil) async throws -> HTTPResponse {
        let raw = try await performBlocking { try self.sendRequest(httpRequest, timeout: timeout) }
        return try Self.parse(raw)
    }

    @discardableResult
    private func request(_ httpRequest: String, timeout: Int? = nil) async throws -> HTTPResponse {
        try await send(httpRequest, timeout: timeout).requireSuccess()
    }

    private func decode<T: Decodable>(_ type: T.Type, from body: Data) throws -> T {
        do {
            return try Self.jsonDecoder.decode(T.self, from: body)
        } catch {
            let raw = String(data: body, encoding: .utf8) ?? "unreadable"
            throw DockerError.decodingFailed(String(raw.prefix(300)))
        }
    }
}
