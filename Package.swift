// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "WikipediaKit",
    platforms: [
        .iOS(.v12),
        .macOS("10.12"),
        .watchOS(.v3),
        .tvOS(.v12)
    ],
    products: [
        .library(
            name: "WikipediaKit",
            targets: ["WikipediaKit"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "WikipediaKit",
            dependencies: [],
            path: "Sources"),
        .testTarget(
            name: "WikipediaKitTests",
            dependencies: ["WikipediaKit"],
            path: "WikipediaKitTests"
            ),
    ]
)

