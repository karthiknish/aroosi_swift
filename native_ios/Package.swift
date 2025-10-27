// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AroosiSwift",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "AroosiKit",
            targets: ["AroosiKit"]
        )
    ],
    dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.21.0")
],
    targets: [
        .target(
            name: "AroosiKit",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk")
            ],
            path: "Sources",
            resources: [
                .process("Resources")
            ],
            cSettings: [
                .define("DISABLE_MACOS", .when(platforms: [.iOS]))
            ],
            swiftSettings: [
                .define("DISABLE_MACOS", .when(platforms: [.iOS]))
            ],
            linkerSettings: [
                .linkedFramework("AuthenticationServices", .when(platforms: [.iOS])),
                .linkedFramework("CryptoKit", .when(platforms: [.iOS])),
                .linkedFramework("Security", .when(platforms: [.iOS])),
                .linkedFramework("AVFoundation", .when(platforms: [.iOS])),
                .linkedFramework("Photos", .when(platforms: [.iOS])),
                .linkedFramework("CoreLocation", .when(platforms: [.iOS])),
                .linkedFramework("UserNotifications", .when(platforms: [.iOS])),
                .linkedFramework("AppTrackingTransparency", .when(platforms: [.iOS]))
            ]
        ),
        .testTarget(
            name: "AroosiKitTests",
            dependencies: [
                "AroosiKit",
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk")
            ],
            path: "Tests"
        )
    ]
)
