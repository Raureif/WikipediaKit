// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "WikipediaKit",
    platforms: [
        .iOS(.v9),
        .macOS("10.10"),
        .watchOS(.v3),
        .tvOS(.v9)
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

