// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "flutter_msal_plus",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "flutter-msal-plus", targets: ["flutter_msal_plus"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(
            url: "https://github.com/AzureAD/microsoft-authentication-library-for-objc",
            exact: "2.0.0"
        )
    ],
    targets: [
        .target(
            name: "flutter_msal_plus",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "MSAL", package: "microsoft-authentication-library-for-objc")
            ],
            path: "Sources/flutter_msal_plus"
        )
    ]
)
