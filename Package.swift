// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacLiveEngine",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "MacLiveEngine", targets: ["MacLiveEngine"])
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey.git", from: "0.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "MacLiveEngine",
            dependencies: ["HotKey"],
            path: "Sources/MacLiveEngine",
            resources: [
                .process("../../Resources")
            ]
        ),
        .testTarget(
            name: "MacLiveEngineTests",
            dependencies: ["MacLiveEngine"],
            path: "Tests/MacLiveEngineTests"
        )
    ]
)
