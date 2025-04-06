// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "FreeScreenshot",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "FreeScreenshot",
            targets: ["FreeScreenshot"]),
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey", from: "0.1.3"),
    ],
    targets: [
        .target(
            name: "FreeScreenshot",
            dependencies: ["HotKey"]),
    ]
) 