// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TextLens",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "TextLens", targets: ["TextLens"]),
        .executable(name: "TextLensChecks", targets: ["TextLensChecks"])
    ],
    targets: [
        .executableTarget(name: "TextLens", dependencies: ["TextLensCore"]),
        .target(name: "TextLensCore"),
        .executableTarget(name: "TextLensChecks", dependencies: ["TextLensCore"], path: "Checks/TextLensChecks")
    ]
)
