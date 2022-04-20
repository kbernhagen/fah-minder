// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "fah-minder",
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
    .target(
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
