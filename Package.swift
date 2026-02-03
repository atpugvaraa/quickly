// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "quickly",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "quickly", targets: ["CLI"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
    ],
    targets: [
        .target(name: "Core", path: "Sources/Core"),
        .target(name: "IO", dependencies: ["Core"], path: "Sources/IO"),
        .target(name: "Bob", path: "Sources/Bob"),
        .executableTarget(
            name: "CLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "Core",
                "IO",
                "Bob"
            ],
            path: "Sources/CLI"
        ),
        
    ]
)
