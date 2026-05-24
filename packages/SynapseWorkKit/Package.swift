// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SynapseWorkKit",
    platforms: [
        .iOS(.v17),
        .macCatalyst(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "Models", targets: ["Models"]),
        .library(name: "Networking", targets: ["Networking"]),
        .library(name: "Auth", targets: ["Auth"]),
        .library(name: "Persistence", targets: ["Persistence"]),
        .library(name: "Connectors", targets: ["Connectors"]),
        .library(name: "Intelligence", targets: ["Intelligence"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "Charts", targets: ["SynapseWorkCharts"]),
        .library(name: "Features", targets: ["Features"]),
        .library(name: "AppLifecycle", targets: ["AppLifecycle"]),
        .library(name: "Tools", targets: ["Tools"])
    ],
    targets: [
        .target(name: "Models", path: "Sources/Models"),
        .target(
            name: "Networking",
            dependencies: ["Models"],
            path: "Sources/Networking"
        ),
        .target(
            name: "Auth",
            dependencies: ["Models", "Networking"],
            path: "Sources/Auth"
        ),
        .target(
            name: "Persistence",
            dependencies: ["Models"],
            path: "Sources/Persistence"
        ),
        .target(
            name: "Connectors",
            dependencies: ["Models", "Networking", "Persistence"],
            path: "Sources/Connectors"
        ),
        .target(
            name: "Intelligence",
            dependencies: ["Models", "Networking", "Persistence"],
            path: "Sources/Intelligence"
        ),
        .target(name: "DesignSystem", path: "Sources/DesignSystem"),
        .target(
            name: "SynapseWorkCharts",
            dependencies: ["DesignSystem"],
            path: "Sources/Charts"
        ),
        .target(
            name: "Features",
            dependencies: ["Models", "Networking", "DesignSystem", "Auth", "Persistence", "SynapseWorkCharts"],
            path: "Sources/Features"
        ),
        .target(
            name: "Tools",
            path: "Sources/Tools"
        ),
        .target(
            name: "AppLifecycle",
            dependencies: ["Models", "Networking", "Auth", "DesignSystem", "Features", "Persistence", "Intelligence"],
            path: "Sources/AppLifecycle"
        ),
        .testTarget(
            name: "ModelsTests",
            dependencies: ["Models"],
            path: "Tests/ModelsTests"
        ),
        .testTarget(
            name: "PersistenceTests",
            dependencies: ["Persistence", "Models"],
            path: "Tests/PersistenceTests"
        )
    ],
    swiftLanguageModes: [.v6]
)
