// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CoffeeBeanCore",
    platforms: [.macOS(.v13), .iOS(.v17)],
    products: [
        .library(name: "CoffeeBeanCore", targets: ["CoffeeBeanCore"]),
    ],
    targets: [
        .target(name: "CoffeeBeanCore"),
        .testTarget(name: "CoffeeBeanCoreTests", dependencies: ["CoffeeBeanCore"],
                    resources: [.copy("Fixtures")]),
    ]
)
