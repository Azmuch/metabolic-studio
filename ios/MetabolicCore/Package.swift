// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MetabolicCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "MetabolicCore", targets: ["MetabolicCore"])
    ],
    targets: [
        .target(name: "MetabolicCore"),
        .testTarget(name: "MetabolicCoreTests", dependencies: ["MetabolicCore"])
    ]
)
