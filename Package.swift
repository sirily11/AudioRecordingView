// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AudioRecorder",
    platforms: [.macOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AudioRecorder",
            targets: ["AudioRecorder"]),
    ],
    dependencies: [
        .package(url: "https://github.com/AudioKit/AudioKit", exact: "5.6.2"),
        .package(url: "https://github.com/AudioKit/SoundpipeAudioKit", branch: "main"),
        .package(url: "https://github.com/AudioKit/AudioKitEX", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "AudioRecorder", dependencies: [
                .product(name: "AudioKit", package: "AudioKit"),
                .product(name: "SoundpipeAudioKit", package: "SoundpipeAudioKit"),
                .product(name: "AudioKitEX", package: "AudioKitEX"),
            ]),
        .testTarget(
            name: "AudioRecorderTests",
            dependencies: ["AudioRecorder"]),
    ])
