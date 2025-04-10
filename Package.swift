// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "FreeScreenshot",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "FreeScreenshot",
            targets: ["FreeScreenshot"]),
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey", from: "0.1.3"),
    ],
    targets: [
        .executableTarget(
            name: "FreeScreenshot",
            dependencies: ["HotKey"],
            path: "freescreenshot",
            resources: [
                .process("Assets.xcassets")
            ]),
    ]
) 