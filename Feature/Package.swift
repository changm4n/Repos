// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Feature",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Feature", targets: ["Search"]),
        .library(name: "FeatureImpl", targets: ["SearchImpl"]),
        .library(name: "FeatureTestSupport", targets: ["SearchTestSupport"]),
    ],
    dependencies: [
        .package(path: "../Domain"),
        .package(path: "../SharedPackage"),
    ],
    targets: [
        .target(
            name: "Search",
            dependencies: [],
            path: "Search/Interface"
        ),
        .target(
            name: "SearchImpl",
            dependencies: [
                "Search",
                .product(name: "Domain", package: "Domain"),
                .product(name: "SharedPackage", package: "SharedPackage"),
            ],
            path: "Search/Implementation"
        ),
        .target(
            name: "SearchTestSupport",
            dependencies: ["Search"],
            path: "Search/TestSupport"
        ),
    ]
)
