// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UseCase",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "UseCase",
            targets: ["UseCase"]),
    ],
    dependencies: [
        .package(path: "../Domain"),
        .package(path: "../Repository")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "UseCase",
            dependencies: [
                "Domain",
                "Repository"
            ]
        ),
        .testTarget(
            name: "UseCaseTests",
            dependencies: ["UseCase"]
        ),
    ]
)
