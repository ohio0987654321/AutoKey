// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AutoKey",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "AutoKey",
            targets: ["AutoKey"]
        )
    ],
    targets: [
        .executableTarget(
            name: "AutoKey",
            dependencies: [],
            path: "Sources/AutoKey",
            resources: [
                .process("../Resources")
            ]
        )
    ]
)
