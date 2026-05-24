import Foundation
import Models
// WorkRepositories will hold the Live (URLSession-backed) implementations of
// each surface's repository protocol. The first Live repo lands once
// /api/auth/apple and the Spotlight server contract (?after= + X-Daemon-Last-Tick)
// are in place. Until then this module is a placeholder so the package layout
// is stable and `swift build` succeeds.
public enum WorkRepositoriesModule {
    public static let placeholder: String = "WorkRepositories"
}
