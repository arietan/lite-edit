// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LiteEdit",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "LiteEdit",
            path: "Sources/LiteEdit"
        )
    ]
)
