// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "OnboardingKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "OnboardingKit", targets: ["OnboardingKit"]),
    ],
    targets: [
        .target(
            name: "OnboardingKit",
            resources: [.process("Resources")],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "OnboardingKitTests",
            dependencies: ["OnboardingKit"],
            swiftSettings: swiftSettings
        ),
    ],
    swiftLanguageModes: [.v5]
)

/// Matches the settings the kit was written with in the app target.
var swiftSettings: [SwiftSetting] {
    [
        .defaultIsolation(MainActor.self),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("MemberImportVisibility"),
    ]
}
