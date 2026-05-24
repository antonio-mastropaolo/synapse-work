import Foundation
import Networking

/// Bridge `SessionStore` into the `Networking` layer's `TokenProvider` and
/// `UnauthorizedHandler` seams. Lives in `Auth` (not `Networking`) so the
/// dependency points the right way — `Auth` already imports `Networking`.
extension SessionStore: TokenProvider, UnauthorizedHandler {
    nonisolated public func currentJWT() async -> String? {
        await self.currentToken()
    }

    nonisolated public func handleUnauthorized() async {
        await self.signOut()
    }
}
