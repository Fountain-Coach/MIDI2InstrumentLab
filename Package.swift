// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MIDI2InstrumentLab",
    platforms: [ .macOS(.v13) ],
    products: [
        .executable(name: "lab-service", targets: ["LabService"]),
        .executable(name: "lab-runner", targets: ["LabRunner"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.60.0")
    ],
    targets: [
        .executableTarget(
            name: "LabService",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio")
            ],
            path: "Sources/LabService"
        ),
        .executableTarget(
            name: "LabRunner",
            dependencies: [],
            path: "Sources/LabRunner"
        )
    ]
)

