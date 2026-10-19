// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-decimals",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(name: "Decimals", targets: ["Decimals"])
    ],
    dependencies: [
        .package(url: "https://github.com/swift-ieee/swift-ieee-754.git", branch: "main"),
        .package(
            url: "https://github.com/swift-atoms/swift-decimal.git",
            branch: "main"
        ),
        .package(url: "https://github.com/swift-atoms/swift-ascii.git", branch: "main", traits: ["Serializer"]),
        .package(url: "https://github.com/swift-atoms/swift-rounding.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-division.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "Decimals",
            dependencies: [
                .product(name: "IEEE 754", package: "swift-ieee-754"),
                .product(name: "Decimal", package: "swift-decimal"),
                .product(name: "ASCII", package: "swift-ascii"),
                .product(name: "Rounding", package: "swift-rounding"),
                .product(name: "Division", package: "swift-division"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
                .enableUpcomingFeature("MemberImportVisibility"),
            ]
        ),
        .testTarget(
            name: "Decimals Tests",
            dependencies: [
                .target(name: "Decimals"),
                .product(name: "Rounding", package: "swift-rounding"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    target.swiftSettings =
        (target.swiftSettings ?? []) + [
            .strictMemorySafety(),
            .enableUpcomingFeature("ExistentialAny"),
            .enableUpcomingFeature("InternalImportsByDefault"),
            .enableUpcomingFeature("MemberImportVisibility"),
            .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            .enableUpcomingFeature("InferIsolatedConformances"),
            .enableExperimentalFeature("Lifetimes"),
            .treatAllWarnings(as: .error),
        ]
}
