// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EkaVoiceToRx",
    platforms: [
      .iOS(.v17)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "EkaVoiceToRx",
            targets: ["EkaVoiceToRx"]),
    ],
    dependencies: [
      .package(url: "https://github.com/aws-amplify/aws-sdk-ios-spm.git", .upToNextMajor(from: "2.36.6")),
      .package(url: "https://github.com/firebase/firebase-ios-sdk.git", .upToNextMajor(from: "12.0.0")),
      .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", .upToNextMajor(from: "5.0.0")),
      .package(url: "https://github.com/gfreezy/libfvad.git", .upToNextMajor(from: "1.0.0")),
      .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.10.2")),
      .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.6.0"),
      .package(url: "git@github.com:eka-care/EkaUI.git", branch: "main")
    ],
    targets: [
        .target(
            name: "EkaVoiceToRx",
            dependencies: [
              .product(name: "AWSS3", package: "aws-sdk-ios-spm"),
              .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
              .product(name: "SwiftyJSON", package: "SwiftyJSON"),
              .product(name: "libfvad", package: "libfvad"),
              .product(name: "Alamofire", package: "Alamofire"),
              .product(name: "SwiftProtobuf", package: "swift-protobuf"),
              .product(name: "EkaUI", package: "EkaUI")
            ],
            resources: [
              .process("Resources")
            ]
        ),

    ]
)
