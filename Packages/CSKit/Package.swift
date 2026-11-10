// swift-tools-version: 6.2
import PackageDescription

// Foundation-only targets (Contracts, Content, Review, VisualsLayout) build and test on Linux.
// UI targets wrap their sources in `#if canImport(UIKit)` so `swift test` still builds everywhere.

// Headers for CPythonBridge. The simulator slice's headers are a superset of the device slice's
// (pyconfig.h picks the architecture), so one path serves both.
let packageDirectory = String(#filePath.dropLast("/Package.swift".count))
let pythonFrameworkSlice = packageDirectory + "/../../Frameworks/Python.xcframework/ios-arm64_x86_64-simulator"
let package = Package(
    name: "CSKit",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "CSKit", targets: [
            "Contracts", "Content", "Runtime", "Editor", "Visuals", "VisualsLayout",
            "Lessons", "Exercises", "Playground", "Review", "Tutor", "Linux", "Store",
        ]),
        // Dumps loaded content as JSON for tools/validate_content.py, so parsing lives in one place.
        .executable(name: "cs-content", targets: ["ContentTool"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.1.0"),
        .package(url: "https://github.com/krzyzanowskim/STTextView.git", from: "2.4.1"),
        .package(url: "https://github.com/krzyzanowskim/STTextView-Plugin-Neon.git", revision: "482b73cf442b2262525a0aa4355603b6467b6084"), // 0.8.1, pinned by revision: it depends on Neon by branch
        .package(url: "https://github.com/krzyzanowskim/STTextView-Plugin-TextFormation.git", from: "0.7.0"),
        .package(url: "https://github.com/gonzalezreal/textual.git", from: "0.5.0"),
    ],
    targets: [
        .target(name: "Contracts"),
        .target(name: "Content", dependencies: ["Contracts", "Yams"]),
        // C bridge to the embedded interpreter. Compiles against Python.framework's headers on iOS
        // (fetched by tools/fetch_python.sh) and to a stub elsewhere. The app target links and
        // embeds Python.xcframework, which resolves the symbols.
        .target(
            name: "CPythonBridge",
            cSettings: [
                .unsafeFlags(
                    ["-F", pythonFrameworkSlice, "-Wno-quoted-include-in-framework-header"],
                    .when(platforms: [.iOS])
                ),
            ]
        ),
        .target(name: "Runtime", dependencies: ["Contracts", "CPythonBridge"]),
        // UI libraries are iOS-only dependencies, so `swift test` on macOS and Linux never builds them.
        .target(name: "Editor", dependencies: [
            "Contracts",
            .product(name: "STTextView", package: "STTextView", condition: .when(platforms: [.iOS])),
            .product(name: "STTextView-Plugin-Neon", package: "STTextView-Plugin-Neon", condition: .when(platforms: [.iOS])),
            .product(name: "TextFormationPlugin", package: "STTextView-Plugin-TextFormation", condition: .when(platforms: [.iOS])),
        ]),
        .target(name: "VisualsLayout", dependencies: ["Contracts"]),
        .target(name: "Visuals", dependencies: ["Contracts", "VisualsLayout"]),
        // Screen areas may depend on the component areas Editor and Visuals, and Lessons embeds Exercises.
        .target(name: "Lessons", dependencies: [
            "Contracts", "Editor", "Visuals", "Exercises",
            .product(name: "Textual", package: "textual", condition: .when(platforms: [.iOS])),
        ]),
        .target(name: "Exercises", dependencies: [
            "Contracts", "Editor",
            .product(name: "Textual", package: "textual", condition: .when(platforms: [.iOS])),
        ]),
        .target(name: "Playground", dependencies: ["Contracts", "Editor"]),
        .target(name: "Review", dependencies: ["Contracts"]),
        .target(name: "Tutor", dependencies: ["Contracts"]),
        .target(name: "Linux", dependencies: ["Contracts"]),
        .target(name: "Store", dependencies: ["Contracts", "Review"]),
        .executableTarget(name: "ContentTool", dependencies: ["Content"]),

        .testTarget(name: "ContractsTests", dependencies: ["Contracts"]),
        .testTarget(name: "ContentTests", dependencies: ["Content"]),
        .testTarget(name: "VisualsLayoutTests", dependencies: ["VisualsLayout"]),
        .testTarget(name: "ReviewTests", dependencies: ["Review"]),
        .testTarget(name: "RuntimeTests", dependencies: ["Runtime"]),
        .testTarget(name: "StoreTests", dependencies: ["Store"]),
    ]
)
