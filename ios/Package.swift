// swift-tools-version: 5.9
// TB3 iOS — Swift Package Dependencies
// Note: This file defines SPM dependencies. The Xcode project references these.
// GoogleCast SDK is added separately via CocoaPods (Podfile).

import PackageDescription

let package = Package(
    name: "TB3",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "TB3", targets: ["TB3"]),
    ],
    dependencies: [
        // AWS SDK for Swift — CognitoIdentityProvider only (SRP auth)
        .package(url: "https://github.com/awslabs/aws-sdk-swift.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "TB3",
            dependencies: [
                .product(name: "AWSCognitoIdentityProvider", package: "aws-sdk-swift"),
            ],
            path: "TB3"
        ),
        .testTarget(
            name: "TB3Tests",
            dependencies: ["TB3"],
            path: "TB3Tests"
        ),
    ]
)
