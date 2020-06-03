// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "ProcessGraphQL",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        //        .library(name: "SqlToPostgres", targets: ["SqlToPostgres"]),
        //        .library(name: "LaunchHasura", targets: ["LaunchHasura"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.0.1"),
        .package(name: "Apollo",
                 url: "https://github.com/apollographql/apollo-ios.git",
                 .upToNextMinor(from: "0.25.0"))
    ],
    targets: [
        .target(name: "Utilities"),
        .target(
            name: "SqlToPostgres",
            dependencies: [.product(name: "ArgumentParser",package: "swift-argument-parser"),
                           .target(name: "Utilities")]
        ),
        .target(
            name: "LaunchHasura",
            dependencies: [.product(name: "ArgumentParser", package: "swift-argument-parser"),
                           .target(name: "Utilities")]
        ),
        .target(
            name: "DownloadSchemas",
            dependencies: [.product(name: "ArgumentParser", package: "swift-argument-parser"),
                           .target(name: "Utilities"),
                           .product(name: "ApolloCodegenLib", package: "Apollo")]
        ),
        .target(
            name: "SQLtoGraphQL",
            dependencies: [.product(name: "ArgumentParser", package: "swift-argument-parser"),
            .target(name: "Utilities"),
            .product(name: "ApolloCodegenLib", package: "Apollo")]
        ),
        .target(
            name: "VerifyQueryExecution",
            dependencies: [.product(name: "ArgumentParser", package: "swift-argument-parser"),
                           .target(name: "Utilities")]
        ),
        .target(
            name: "SavePostgres",
            dependencies: [.product(name: "ArgumentParser", package: "swift-argument-parser"),
                           .target(name: "Utilities")]
        )
    ]
)
