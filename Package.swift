// swift-tools-version:5.5
import PackageDescription

let package =
  Package(
    name: "SwiftSimpleCloudStore",
    platforms: [
      .iOS(.v15),
      .watchOS(.v8),
    ],
    products: [
      .library(
        name: "SwiftSimpleCloudStore",
        targets: ["SwiftSimpleCloudStore"]
      ),
    ],
    dependencies: [
      .package(name: "SwiftConcurrency", url: "https://github.com/xiiagency/SwiftConcurrency", .branchItem("main")),
      .package(name: "SwiftFoundationExtensions", url: "https://github.com/xiiagency/SwiftFoundationExtensions", .branchItem("main")),
    ],
    targets: [
      .target(
        name: "SwiftSimpleCloudStore",
        dependencies: [
          "SwiftConcurrency",
          "SwiftFoundationExtensions",
        ]
      ),
      // NOTE: Re-enable when tests are added.
//      .testTarget(
//        name: "SwiftSimpleCloudStoreTests",
//        dependencies: ["SwiftSimpleCloudStore"]
//      ),
    ]
  )
