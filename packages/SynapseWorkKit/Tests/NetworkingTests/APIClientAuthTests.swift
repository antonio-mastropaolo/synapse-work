import XCTest
@testable import Networking
@testable import Auth
@testable import Models

/// Verifies APIClient's auth contract:
///   1. Injects `Authorization: Bearer <jwt>` on every outgoing request.
///   2. On 401, calls the `UnauthorizedHandler` (which clears the
///      SessionStore in production) and surfaces `WorkError.unauthenticated`.
final class APIClientAuthTests: XCTestCase {

    // Records the latest outbound request so tests can assert headers.
    private final class RecordingHandler: URLProtocol, @unchecked Sendable {
        nonisolated(unsafe) static var nextResponse: (status: Int, body: Data) = (200, Data())
        nonisolated(unsafe) static var requests: [URLRequest] = []
        static let lock = NSLock()

        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
        override func startLoading() {
            Self.lock.lock()
            Self.requests.append(self.request)
            let (status, body) = Self.nextResponse
            Self.lock.unlock()
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: status,
                httpVersion: "HTTP/1.1",
                headerFields: [:]
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if !body.isEmpty { client?.urlProtocol(self, didLoad: body) }
            client?.urlProtocolDidFinishLoading(self)
        }
        override func stopLoading() {}

        static func reset(response: (status: Int, body: Data)) {
            lock.lock()
            requests = []
            nextResponse = response
            lock.unlock()
        }
    }

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [RecordingHandler.self]
        return URLSession(configuration: config)
    }

    private struct Payload: Codable, Sendable, Equatable {
        let ok: Bool
    }

    @MainActor
    func test_injectsAuthorizationHeader() async throws {
        let body = try JSONEncoder().encode(Payload(ok: true))
        RecordingHandler.reset(response: (200, body))

        let session = makeSession()
        let store = SessionStore(storage: InMemoryKeychain())
        await store.setSession(
            jwt: "tok-aaa",
            expiresAt: Date(timeIntervalSinceNow: 3_600),
            userId: "u"
        )

        let client = APIClient(
            environment: APIEnvironment(
                baseURL: URL(string: "https://api.synapse.test/")!,
                deviceID: "dev-1"
            ),
            tokenProvider: store,
            unauthorizedHandler: store,
            session: session
        )
        let response = try await client.get("ping", as: Payload.self)
        XCTAssertEqual(response.value.ok, true)

        let recorded = try XCTUnwrap(RecordingHandler.requests.first)
        XCTAssertEqual(recorded.value(forHTTPHeaderField: "Authorization"), "Bearer tok-aaa")
        XCTAssertEqual(recorded.value(forHTTPHeaderField: "X-Device-Id"), "dev-1")
    }

    @MainActor
    func test_401_clearsSessionAndThrows() async throws {
        RecordingHandler.reset(response: (401, Data()))

        let session = makeSession()
        let store = SessionStore(storage: InMemoryKeychain())
        await store.setSession(
            jwt: "stale",
            expiresAt: Date(timeIntervalSinceNow: 3_600),
            userId: "u"
        )
        XCTAssertTrue(store.isSignedIn)

        let client = APIClient(
            environment: APIEnvironment(
                baseURL: URL(string: "https://api.synapse.test/")!,
                deviceID: "dev"
            ),
            tokenProvider: store,
            unauthorizedHandler: store,
            session: session
        )

        do {
            _ = try await client.get("ping", as: Payload.self)
            XCTFail("Expected WorkError.unauthenticated")
        } catch let err as WorkError {
            XCTAssertEqual(err, .unauthenticated)
        }
        // Session must be wiped after the 401.
        XCTAssertFalse(store.isSignedIn)
        XCTAssertNil(store.jwt)
    }

    @MainActor
    func test_missingToken_throwsUnauthenticated() async {
        RecordingHandler.reset(response: (200, Data()))
        let session = makeSession()
        let store = SessionStore(storage: InMemoryKeychain())
        // Don't set a session — token provider returns nil.

        let client = APIClient(
            environment: APIEnvironment(
                baseURL: URL(string: "https://api.synapse.test/")!,
                deviceID: "dev"
            ),
            tokenProvider: store,
            unauthorizedHandler: store,
            session: session
        )
        do {
            _ = try await client.get("ping", as: Payload.self)
            XCTFail("Expected WorkError.unauthenticated")
        } catch let err as WorkError {
            XCTAssertEqual(err, .unauthenticated)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
