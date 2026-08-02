// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "msal-flutter",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "msal-flutter", targets: ["msal_flutter"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(
            url: "https://github.com/AzureAD/microsoft-authentication-library-for-objc",
            exact: "2.14.1"
        )
    ],
    targets: [
        .target(
            name: "msal_flutter",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "MSAL", package: "microsoft-authentication-library-for-objc")
            ],
            path: "Sources/msal_flutter",
            exclude: [
                "CocoaPods",
                "include"
            ]
        )
    ]
)
