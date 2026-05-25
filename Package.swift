// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PDFCompressor",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "PDFCompressor", targets: ["PDFCompressorApp"]),
        .library(name: "PDFCompressorCore", targets: ["PDFCompressorCore"])
    ],
    targets: [
        .executableTarget(
            name: "PDFCompressorApp",
            dependencies: ["PDFCompressorCore"]
        ),
        .target(
            name: "PDFCompressorCore",
            dependencies: []
        ),
        .testTarget(
            name: "PDFCompressorCoreTests",
            dependencies: ["PDFCompressorCore"]
        )
    ]
)
