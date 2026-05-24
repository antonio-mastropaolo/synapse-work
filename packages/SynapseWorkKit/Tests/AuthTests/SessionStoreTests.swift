import XCTest
@testable import Auth
@testable import Models

final class SessionStoreTests: XCTestCase {

    @MainActor
    func test_bootstrap_loadsPersistedSession() async throws {
        let storage = InMemoryKeychain()
        // Pre-seed the envelope a previous run would have written.
        let session = Session(
            userId: "u-1",
            jwt: "tok-abc",
            expiresAt: Date(timeIntervalSinceNow: 3_600)
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(session)
        try await storage.writeData(data, forKey: SessionStore.envelopeKey)

        let store = SessionStore(storage: storage)
        XCTAssertFalse(store.isSignedIn, "Pre-bootstrap is signed out")
        await store.bootstrap()
        XCTAssertTrue(store.isSignedIn)
        XCTAssertEqual(store.jwt, "tok-abc")
        XCTAssertEqual(store.userId, "u-1")
    }

    @MainActor
    func test_setSession_persistsAndRoundTrips() async throws {
        let storage = InMemoryKeychain()
        let store = SessionStore(storage: storage)
        let expires = Date(timeIntervalSinceNow: 7_200)
        await store.setSession(jwt: "tok-xyz", expiresAt: expires, userId: "u-2")

        XCTAssertEqual(store.jwt, "tok-xyz")
        XCTAssertEqual(store.userId, "u-2")
        let liveToken = await store.currentToken(); XCTAssertEqual(liveToken, "tok-xyz")

        // A second store instance should observe the same envelope.
        let reloaded = SessionStore(storage: storage)
        await reloaded.bootstrap()
        XCTAssertTrue(reloaded.isSignedIn)
        XCTAssertEqual(reloaded.jwt, "tok-xyz")
        XCTAssertEqual(reloaded.userId, "u-2")
    }

    @MainActor
    func test_signOut_clearsInMemoryAndKeychain() async throws {
        let storage = InMemoryKeychain()
        let store = SessionStore(storage: storage)
        await store.setSession(
            jwt: "tok",
            expiresAt: Date(timeIntervalSinceNow: 3_600),
            userId: "u"
        )
        XCTAssertTrue(store.isSignedIn)
        await store.signOut()
        XCTAssertFalse(store.isSignedIn)
        XCTAssertNil(store.jwt)
        XCTAssertNil(store.userId)
        let raw = try await storage.readData(forKey: SessionStore.envelopeKey)
        XCTAssertNil(raw, "signOut must remove the envelope from Keychain")
    }

    @MainActor
    func test_expiredSession_isNotReturned() async throws {
        let storage = InMemoryKeychain()
        let store = SessionStore(storage: storage)
        await store.setSession(
            jwt: "tok",
            // Note: setSession writes the envelope and updates in-memory
            // state. Expiry is enforced at read time via currentToken()
            // and isSignedIn, so a session set with a past expiresAt is
            // observable as "not signed in" even though the envelope was
            // written.
            expiresAt: Date(timeIntervalSinceNow: -60),
            userId: "u"
        )
        XCTAssertFalse(store.isSignedIn)
        let t = await store.currentToken(); XCTAssertNil(t)
    }

    @MainActor
    func test_bootstrap_expiredEnvelopeIsWiped() async throws {
        let storage = InMemoryKeychain()
        let stale = Session(
            userId: "u",
            jwt: "tok",
            expiresAt: Date(timeIntervalSinceNow: -60)
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try await storage.writeData(
            try encoder.encode(stale),
            forKey: SessionStore.envelopeKey
        )

        let store = SessionStore(storage: storage)
        await store.bootstrap()
        XCTAssertFalse(store.isSignedIn)
        let raw = try await storage.readData(forKey: SessionStore.envelopeKey)
        XCTAssertNil(raw, "bootstrap must wipe an expired envelope")
    }

    @MainActor
    func test_currentToken_returnsNilWhenSignedOut() async {
        let store = SessionStore(storage: InMemoryKeychain())
        let t = await store.currentToken(); XCTAssertNil(t)
    }

    @MainActor
    func test_didBootstrap_flipsAfterBootstrap() async {
        let store = SessionStore(storage: InMemoryKeychain())
        XCTAssertFalse(store.didBootstrap)
        await store.bootstrap()
        XCTAssertTrue(store.didBootstrap)
    }
}
