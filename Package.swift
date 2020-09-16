// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Turbolinks",
  platforms: [.iOS(.v10)],
  products: [
    .library(
    name: "Turbolinks",
    targets: ["Turbolinks"]),
  ],
  dependencies: [
  ],
  targets: [
    .target(
    name: "Turbolinks",
    dependencies: [],
    path: "Turbolinks",
    exclude:["Tests", "Info.plist"],
    resources: [.copy("WebView.js")]),
  ]
)