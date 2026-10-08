# Contributing

Keep the native MSAL cache and preserve both public Dart APIs. Source identifiers use English; source comments use Spanish. Preserve copyright notices. Do not include credentials or token logs.

Run from the repository root:

```sh
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
(cd example && flutter test)
flutter pub publish --dry-run
```

For changes to Apple integration, build the example with SPM enabled and disabled. Confirm every application and dependency deployment target supports iOS 15. Never lower a dependency's declared target as a workaround. Verify a signed device sign-in, cancellation, silent acquisition, account selection and logout with your own Entra registration before a release.

Native dependency upgrades must consider both the upstream manifest and shipped XCFramework slices. Document platform/API changes in CHANGELOG. Do not claim a pub.dev score without an actual scoring result.

On Xcode 27, standalone pod lint rejects the older deployment targets in upstream Flutter/MSAL podspecs. Raise them using an external validation configuration:

```sh
XCODE_XCCONFIG_FILE="$PWD/validation/ios15.xcconfig" \
  pod lib lint ios/flutter_msal_plus.podspec \
  --configuration=Debug --skip-tests --use-modular-headers --use-libraries
```

This raises dependency deployment targets without changing generated files or lowering an upstream requirement. The example Podfile applies the same minimum during normal CocoaPods builds.
