// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Platform",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Platform", targets: ["Platform"]),
        .library(name: "PlatformImpl", targets: ["PlatformImpl"]),
        .library(name: "PlatformTestSupport", targets: ["PlatformTestSupport"]),
    ],
    targets: [
        .target(name: "Platform", path: "Interface"),
        .target(name: "PlatformImpl", dependencies: ["Platform"], path: "Implementation"),
        .target(name: "PlatformTestSupport", dependencies: ["Platform"], path: "TestSupport"),
        .testTarget(
            name: "PlatformTests",
            dependencies: ["Platform", "PlatformImpl", "PlatformTestSupport"],
            path: "Tests"
        ),
    ]
)
