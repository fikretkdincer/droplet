// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DropletCore",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(
            name: "DropletCore",
            targets: ["DropletCore"]
        )
    ],
    targets: [
        .target(name: "DropletCore"),
        .testTarget(
            name: "DropletCoreTests",
            dependencies: ["DropletCore"]
        )
    ]
)
