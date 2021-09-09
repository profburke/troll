// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Troll",
    products: [
        .executable(
            name: "troll",
            targets: ["shell"]),
        .library(
            name: "Troll",
            targets: ["Troll"]),
    ],
    dependencies: [
        .package(name: "LineNoise",
                 url: "https://github.com/andybest/linenoise-swift",
                 from: "0.0.0")
    ],
    targets: [
        .target(
            name: "Troll",
            dependencies: []),
        .target(
            name: "shell",
            dependencies: ["Troll", "LineNoise"]),
        .testTarget(
            name: "TrollTests",
            dependencies: ["Troll"]),
    ]
)
