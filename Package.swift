// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "ComposableHealthStore",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(name: "ComposableHealthStore", targets: ["ComposableHealthStore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.15.0")
    ],
    targets: [
        .target(name: "ComposableHealthStore", dependencies: [
            .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
        ]),
        .testTarget(name: "ComposableHealthStoreTests", dependencies: ["ComposableHealthStore"]),
    ]
)
