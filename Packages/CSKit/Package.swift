// swift-tools-version: 6.2
import PackageDescription

// Foundation-only targets (Contracts, Content, Review, VisualsLayout) build and test on Linux.
// UI targets wrap their sources in `#if canImport(UIKit)` so `swift test` still builds everywhere.
let package = Package(
    name: "CSKit",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "CSKit", targets: [
            "Contracts", "Content", "Runtime", "Editor", "Visuals", "VisualsLayout",
            "Lessons", "Exercises", "Review", "Tutor", "Linux", "Store",
        ]),
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.1.0"),
    ],
    targets: [
        .target(name: "Contracts"),
        .target(name: "Content", dependencies: ["Contracts", "Yams"]),
        .target(name: "Runtime", dependencies: ["Contracts"]),
        .target(name: "Editor", dependencies: ["Contracts"]),
        .target(name: "VisualsLayout", dependencies: ["Contracts"]),
        .target(name: "Visuals", dependencies: ["Contracts", "VisualsLayout"]),
        .target(name: "Lessons", dependencies: ["Contracts"]),
        .target(name: "Exercises", dependencies: ["Contracts"]),
        .target(name: "Review", dependencies: ["Contracts"]),
        .target(name: "Tutor", dependencies: ["Contracts"]),
        .target(name: "Linux", dependencies: ["Contracts"]),
        .target(name: "Store", dependencies: ["Contracts"]),

        .testTarget(name: "ContractsTests", dependencies: ["Contracts"]),
        .testTarget(name: "ContentTests", dependencies: ["Content"]),
        .testTarget(name: "VisualsLayoutTests", dependencies: ["VisualsLayout"]),
        .testTarget(name: "ReviewTests", dependencies: ["Review"]),
    ]
)
