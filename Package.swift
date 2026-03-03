// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ai-presents-app-ios",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "aiPresentsApp",
            targets: ["aiPresentsApp"]
        )
    ],
    targets: [
        .target(
            name: "aiPresentsApp",
            path: "Sources/aiPresentsApp",
            exclude: ["aiPresentsApp.swift"]
        ),
        .testTarget(
            name: "aiPresentsAppTests",
            dependencies: ["aiPresentsApp"],
            path: "Tests/aiPresentsAppTests"
        )
    ]
)
