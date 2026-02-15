// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "SharedPackage",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "SharedPackage", targets: ["SharedPackage"]),
  ],
  targets: [
    .target(
      name: "SharedPackage",
      path: "Sources"
    ),
  ]
)
