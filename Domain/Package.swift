// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Domain",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Domain", targets: ["Usecase", "Entity"]),
        .library(name: "DomainImpl", targets: ["UsecaseImpl", "Entity"]),
        .library(name: "Entity", targets: ["Entity"]),
        .library(name: "DomainTestSupport", targets: ["UsecaseTestSupport"]),
    ],
    dependencies: [
        .package(path: "../Platform"),
    ],
    targets: [
        .target(name: "Entity", path: "Entity"),
        .target(name: "Usecase", dependencies: ["Entity"], path: "Usecase/Interface"),
        .target(
            name: "UsecaseImpl",
            dependencies: ["Usecase", "Entity", .product(name: "Platform", package: "Platform")],
            path: "Usecase/Implementation"
        ),
        .target(name: "UsecaseTestSupport", dependencies: ["Usecase"], path: "Usecase/TestSupport"),
        .testTarget(
            name: "UsecaseImplTests",
            dependencies: [
                "UsecaseImpl",
                "Usecase",
                "Entity",
                .product(name: "Platform", package: "Platform"),
                .product(name: "PlatformTestSupport", package: "Platform"),
            ],
            path: "Usecase/Tests"
        ),
    ]
)
