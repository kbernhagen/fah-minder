// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "fah-minder",
  platforms: [
    .macOS(.v10_14),
  ],
  products: [
    .executable(name: "fah-minder", targets: ["fah-minder"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser",
             from: "1.0.0"),
    .package(url: "https://github.com/daltoniam/Starscream",
             .upToNextMajor(from: "4.0.0")),
  ],
  targets: [
    .executableTarget(
      name: "fah-minder",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "Starscream", package: "Starscream"),
      ]),
    .testTarget(
      name: "FahMinderTests",
      dependencies: ["fah-minder"]),
  ]
)
