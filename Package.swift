// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "swift-fluent-theme-designer",
	platforms: [.macOS(.v12), .iOS(.v15), .watchOS(.v8), .tvOS(.v15)],
	products: [
		.library(
			name: "FluentThemeDesigner",
			targets: ["FluentThemeDesigner"]
		),
	],
	targets: [
		.target(
			name: "FluentThemeDesigner"
		),
		.testTarget(
			name: "FluentThemeDesignerTests",
			dependencies: ["FluentThemeDesigner"]
		),
	]
)
