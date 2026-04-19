// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "TaskitSwift",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .executable(name: "TaskitSwift", targets: ["TaskitSwift"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "TaskitSwift",
            dependencies: [],
            path: "TaskitSwift",
            exclude: ["README.md"]
        )
    ]
)
