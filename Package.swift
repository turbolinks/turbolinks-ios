// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Turbolinks",
    products: [
        .library(name: "Turbolinks", targets: ["Turbolinks"]),
    ],
    targets: [
        .target(
            name: "Turbolinks",
            path: "Turbolinks",
            exclude: ["Info.plist", "Tests"],
            resources: [.copy("WebView.js")]
        ),
        .testTarget(
            name: "TurbolinksTests",
            dependencies: ["Turbolinks"],
            path: "Turbolinks/Tests",
            exclude: ["Info.plist"]
        ),
    ]
)
