// swift-tools-version:5.5
import PackageDescription

let package =
  Package(
    name: "SwiftSimpleCloudStore",
    platforms: [
      .iOS(.v15),
      .watchOS(.v8),
      .macOS(.v12),
    ],
    products: [
      .library(
        name: "SwiftSimpleCloudStore",
        targets: ["SwiftSimpleCloudStore"]
      ),
    ],
    dependencies: [
      .package(
        name: "SwiftFoundationExtensions",
        url: "https://github.com/xiiagency/SwiftFoundationExtensions",
        .upToNextMinor(from: "1.0.0")
      ),
    ],
    targets: [
      .target(
        name: "SwiftSimpleCloudStore",
        dependencies: [
          "SwiftFoundationExtensions",
        ]
      ),
    ]
  )
