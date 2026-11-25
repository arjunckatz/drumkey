// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DrumKey",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "DrumKey", targets: ["DrumKey"]),
        .library(name: "DrumKeyCore", targets: ["DrumKeyCore"])
    ],
    targets: [
        .target(name: "DrumKeyCore"),
        .executableTarget(
            name: "DrumKey",
            dependencies: ["DrumKeyCore"]
        ),
        .testTarget(
            name: "DrumKeyCoreTests",
            dependencies: ["DrumKeyCore"]
        ),
        .testTarget(
            name: "DrumKeyAppTests",
            dependencies: ["DrumKey", "DrumKeyCore"]
        )
    ]
)
