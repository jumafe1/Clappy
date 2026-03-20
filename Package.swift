// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Clappy",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Clappy",
            path: "Clappy",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("Combine"),
            ]
        )
    ]
)
