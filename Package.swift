// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NotionGraph",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "NotionGraphKit",
            targets: ["NotionGraphKit"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "NotionGraphKit",
            dependencies: [],
            path: "NotionGraph/Sources",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
