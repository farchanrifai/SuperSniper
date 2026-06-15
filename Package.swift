// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SuperSniper",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .executable(name: "SuperSniper", targets: ["SuperSniper"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "SuperSniper",
            dependencies: [],
            path: "Sources/SuperSniper"
        )
    ]
)
