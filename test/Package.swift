// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AroosiTests",
    platforms: [
        .iOS(.v17)
    ],
    dependencies: [
        .package(path: "../native_ios"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.21.0")
    ],
    targets: [
        .testTarget(
            name: "AroosiAppTests",
            dependencies: [
                "AroosiKit",
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk")
            ],
            path: ".",
            sources: [
                "UnitTests/AuthenticationTests.swift",
                "UnitTests/DashboardTests.swift",
                "UnitTests/ChatTests.swift",
                "IntegrationTests/FirebaseIntegrationTests.swift",
                "UITests/UserJourneyTests.swift"
            ],
            resources: [
                .process("TestResources")
            ]
        )
    ]
)
