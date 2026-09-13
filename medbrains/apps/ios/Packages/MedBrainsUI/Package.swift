// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MedBrainsUI",
    platforms: [.iOS(.v17)],
    products: [.library(name: "MedBrainsUI", targets: ["MedBrainsUI"])],
    targets: [.target(name: "MedBrainsUI")]
)
