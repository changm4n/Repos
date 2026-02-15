// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "Feature",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "Feature", targets: ["Search", "WebView"]),
    .library(name: "FeatureImpl", targets: ["SearchImpl", "WebViewImpl"]),
    .library(name: "FeatureTestSupport", targets: ["SearchTestSupport", "WebViewTestSupport"]),
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
        "WebView",
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
    .target(
      name: "WebView",
      dependencies: [],
      path: "WebView/Interface"
    ),
    .target(
      name: "WebViewImpl",
      dependencies: [
        "WebView",
        .product(name: "SharedPackage", package: "SharedPackage"),
      ],
      path: "WebView/Implementation"
    ),
    .target(
      name: "WebViewTestSupport",
      dependencies: ["WebView"],
      path: "WebView/TestSupport"
    ),
  ]
)
