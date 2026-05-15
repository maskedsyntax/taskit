// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "TaskitSwift",
    platforms: [
        .macOS(.v14)
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
            exclude: ["README.md"],
            resources: [
                .process("AppIcon.png"),
                .process("AppIcon_alt.png"),
                .process("Screenshot.png")
            ]
        )
    ]
)
