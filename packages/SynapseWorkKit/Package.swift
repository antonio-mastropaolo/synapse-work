// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SynapseWorkKit",
    platforms: [
        .iOS(.v17),
        .macCatalyst(.v17)
    ],
    products: [
        .library(name: "WorkCore", targets: ["WorkCore"]),
        .library(name: "WorkUI", targets: ["WorkUI"]),
        .library(name: "WorkRepositories", targets: ["WorkRepositories"]),
        .library(name: "WorkFeatures", targets: ["WorkFeatures"])
    ],
    targets: [
        .target(
            name: "WorkCore",
            path: "Sources/WorkCore"
        ),
        .target(
            name: "WorkUI",
            dependencies: ["WorkCore"],
            path: "Sources/WorkUI"
        ),
        .target(
            name: "WorkRepositories",
            dependencies: ["WorkCore"],
            path: "Sources/WorkRepositories"
        ),
        .target(
            name: "WorkFeatures",
            dependencies: ["WorkCore", "WorkUI", "WorkRepositories"],
            path: "Sources/WorkFeatures"
        ),
        .testTarget(
            name: "WorkCoreTests",
            dependencies: ["WorkCore"],
            path: "Tests/WorkCoreTests"
        ),
        .testTarget(
            name: "WorkRepositoriesTests",
            dependencies: ["WorkRepositories", "WorkCore"],
            path: "Tests/WorkRepositoriesTests"
        )
    ],
    swiftLanguageModes: [.v6]
)
