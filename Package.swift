// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Orilo",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Orilo", targets: ["Orilo"])
    ],
    targets: [
        .executableTarget(
            name: "Orilo",
            path: "Sources/Orilo"
        ),
        .testTarget(
            name: "OriloTests",
            dependencies: ["Orilo"],
            path: "Tests/OriloTests"
        )
    ]
)
