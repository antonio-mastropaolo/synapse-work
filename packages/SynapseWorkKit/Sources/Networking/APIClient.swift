import Foundation
import Models

public struct APIEnvironment: Sendable {
    public let baseURL: URL
    public let deviceID: String

    public init(baseURL: URL, deviceID: String) {
        self.baseURL = baseURL
        self.deviceID = deviceID
    }
}

/// Source of the bearer token presented on every request. `SessionStore`
/// conforms (via an `Auth`-side extension); tests pass a closure-backed
/// fake.
public protocol TokenProvider: Sendable {
    func currentJWT() async -> String?
}

/// Hook invoked when the server returns 401. The default `APIClient`
/// wiring calls into `SessionStore.signOut()` so the next render lands
/// on the sign-in screen.
public protocol UnauthorizedHandler: Sendable {
    func handleUnauthorized() async
}

/// Typed transport for synapse-v2 work endpoints. Injects `Authorization`
/// from the `TokenProvider`, surfaces 401 as `APIError.unauthorized`
/// after notifying the `UnauthorizedHandler`, and threads
/// `ETag` / `X-Daemon-Last-Tick` through to the caller.
public actor APIClient {
    private let environment: APIEnvironment
    private let tokenProvider: TokenProvider
    private let unauthorizedHandler: UnauthorizedHandler?
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(
        environment: APIEnvironment,
        tokenProvider: TokenProvider,
        unauthorizedHandler: UnauthorizedHandler? = nil,
        session: URLSession = .shared
    ) {
        self.environment = environment
        self.tokenProvider = tokenProvider
        self.unauthorizedHandler = unauthorizedHandler
        self.session = session
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        d.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = d
    }

    public struct Response<T: Sendable & Decodable>: Sendable {
        public let value: T
        public let etag: String?
        public let daemonLastTick: Date?

        public init(value: T, etag: String?, daemonLastTick: Date?) {
            self.value = value
            self.etag = etag
            self.daemonLastTick = daemonLastTick
        }
    }

    public func get<T: Decodable & Sendable>(
        _ path: String,
        query: [URLQueryItem] = [],
        ifNoneMatch: String? = nil,
        as: T.Type = T.self
    ) async throws -> Response<T> {
        guard var components = URLComponents(
            url: environment.baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else {
            throw WorkError.network("Bad URL: \(path)")
        }
        if !query.isEmpty { components.queryItems = query }
        guard let url = components.url else {
            throw WorkError.network("Bad URL components: \(path)")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let tag = ifNoneMatch { request.setValue(tag, forHTTPHeaderField: "If-None-Match") }
        try await applyAuth(&request)

        let (data, response) = try await session.data(for: request)
        return try await decode(data: data, response: response)
    }

    public func post<Body: Encodable & Sendable, T: Decodable & Sendable>(
        _ path: String,
        body: Body,
        as: T.Type = T.self
    ) async throws -> Response<T> {
        var request = URLRequest(url: environment.baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(body)
        try await applyAuth(&request)

        let (data, response) = try await session.data(for: request)
        return try await decode(data: data, response: response)
    }

    private func applyAuth(_ request: inout URLRequest) async throws {
        guard let token = await tokenProvider.currentJWT() else {
            throw WorkError.unauthenticated
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(environment.deviceID, forHTTPHeaderField: "X-Device-Id")
    }

    private func decode<T: Decodable & Sendable>(
        data: Data,
        response: URLResponse
    ) async throws -> Response<T> {
        guard let http = response as? HTTPURLResponse else {
            throw WorkError.network("Non-HTTP response")
        }
        if http.statusCode == 401 {
            // Server rejected the bearer. Wipe the session so the next
            // root render lands on the sign-in screen, then surface the
            // typed error.
            await unauthorizedHandler?.handleUnauthorized()
            throw WorkError.unauthenticated
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8)
            throw WorkError.server(status: http.statusCode, message: body)
        }
        let etag = http.value(forHTTPHeaderField: "ETag")
        let tickHeader = http.value(forHTTPHeaderField: "X-Daemon-Last-Tick")
        let tick = tickHeader.flatMap { ISO8601DateFormatter().date(from: $0) }
        do {
            let value = try decoder.decode(T.self, from: data)
            return Response(value: value, etag: etag, daemonLastTick: tick)
        } catch {
            throw WorkError.decoding(String(describing: error))
        }
    }
}
