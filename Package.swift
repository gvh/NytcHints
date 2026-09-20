// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "nytcHints",
    platforms: [.macOS(.v13), .iOS(.v17)],
    products: [
        .executable(name: "nytcHints", targets: ["nytcHints"]),
        .library(name: "NytcHintsCore", targets: ["NytcHintsCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    ],
    targets: [
        // Shared by the command-line tool and the iPad app (iPad/NytcHintsiPad.xcodeproj).
        .target(name: "NytcHintsCore"),
        .executableTarget(
            name: "nytcHints",
            dependencies: [
                "NytcHintsCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "NytcHintsCoreTests",
            dependencies: ["NytcHintsCore"]
        ),
    ]
)
