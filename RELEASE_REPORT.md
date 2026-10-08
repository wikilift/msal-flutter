# flutter_msal_plus modernization report

Validation date: 8 October 2026. Recommended first package release: **1.0.0**. No package publication, commit, push or Git remote change was performed. Identified generated files and obsolete paths were removed from Git tracking; source changes remain available for review.

## 1. Initial findings

The checkout was `msal_flutter` 3.1.1-alpha3, with two Dart APIs, implemented iOS and Android bridges, an obsolete legacy native implementation, and inconsistent documentation. A tracked underscore symlink exposed a differently named Swift package. CocoaPods used an Objective-C registration wrapper while SPM used a Swift wrapper. The existing user-edited podspec declared 16.6; the SPM manifest declared 15 while depending on MSAL 2.14.1. Several example Xcode configurations and Podfile overrides also declared 16.6. Generated environment files, dependency records and IDE metadata were tracked.

The legacy Dart API expected string tokens although registered native bridges returned structured maps. Native iOS calls used forced argument casts, ignored some authority/filter parameters, retained a redundant token string and returned unrestricted error descriptions. Android had missing early returns after uninitialized-client errors and stale Activity retention. The example printed authentication output and used obsolete Android Gradle integration.

## 2. Implemented changes

Rebranded package/imports, native modules, registration declarations, example and documentation. Kept Android functionality and modernized its namespace/build integration. Removed unused legacy native implementations, duplicate registration wrappers, empty obsolete source directories, unused JSON templates and tracked IDE/generated material. Added formatting/static analysis configuration, meaningful tests, CI build jobs and explicit publication exclusions. Incorporated WikiLift maintenance identity from the existing checkout while preserving LICENSE verbatim.

## 3. Package structure

```text
lib/flutter_msal_plus.dart          Main public import
lib/msal_flutter.dart              Intentional compatible filename
lib/src/                          Clients, models, typed exceptions
android/src/main/kotlin/org/wikilift/flutter_msal_plus/
ios/flutter_msal_plus.podspec
ios/flutter_msal_plus/Package.swift
ios/flutter_msal_plus/Sources/flutter_msal_plus/
  FlutterMsalPlusPlugin.swift      Shared Swift registration class
  MsalMethodHandler.swift          Channel handling and authentication
  MsalExtensions.swift             Native configuration/serialization
example/                           Material 3 app and native targets
test/                              Dart configuration/channel regressions
.github/workflows/validate.yml     Dart, iOS integration matrix, Android
validation/                        Excluded local verification evidence
```

## 4. Public Dart API

Preserved `MSALPublicClientApplication`, its models and methods: initialization, webview parameters, account enumeration, interactive/silent acquisition and logout. Preserved nullable results and mutable configuration/model fields. Exposed associated parameter enums/configuration types from the main entry point so callers do not need internal imports. Added tenant-profile claims parsing.

`PublicClientApplication` now adapts structured results to the historical token-string contract, converts account maps and removes cached accounts through the supported API. It retains private-session, platform redirect and keychain configuration. The method-channel identifier remains `msal_flutter` intentionally. A native type alias retains historical access to the custom webview hook.

Added validation for client ID presence, authority HTTPS syntax, redirect scheme, finite/nonnegative expiration buffer, nonempty scopes, query value types and correlation UUIDs. False/null initialization now fails. Native error mapping retains cancellation and established configuration/account exception types. Arbitrary native error details are no longer incorporated into Dart error messages. Native domain/code is a controlled diagnostic detail on the channel; existing Dart exception classes do not expose every native diagnostic field.

## 5. CocoaPods

Renamed the podspec to `flutter_msal_plus`, synchronized its version to 1.0.0, set iOS 15.0 and pinned MSAL 2.0.0. Only shared Swift sources compile; no redundant Objective-C wrapper or unnecessary public header remains. Swift 5 language mode and module generation are specified.

Both simulator and unsigned device builds succeeded with SPM disabled. Plain standalone `pod lib lint` failed because Xcode 27 rejects Flutter's 11.0 and MSAL's 14.0 pod targets. Lint **passed** when an external xcconfig raised those dependency targets to 15.0. The example Podfile similarly raises targets below 15.0 without lowering any higher dependency requirement. No generated pod project was manually edited.

## 6. Swift Package Manager

Uses the standard directory `ios/flutter_msal_plus`, package/target `flutter_msal_plus`, library product `flutter-msal-plus`, Swift tools 5.9 and iOS 15. The `FlutterFramework` sibling dependency follows Flutter's supported generated package integration and contains no hardcoded development path. The native Microsoft package uses an exact 2.0.0 requirement and product `MSAL`.

Removed the example's obsolete direct Xcode plugin reference, which caused an identity override conflict against Flutter's generated package graph. Public dependency resolution succeeded at revision `03ed4aed29eceb75781f361bfad7f09635212bff`. An Xcode Keychain credential lookup initially stalled; `-packageAuthorizationProvider netrc` resolved the public packages successfully. Subsequent Flutter builds succeeded. The original SPM-enabled Flutter setting has been restored.

## 7. Root cause of iOS 15/16 errors

MSAL 2.14.1 genuinely declares iOS 16 in both its [Swift manifest](https://github.com/AzureAD/microsoft-authentication-library-for-objc/blob/2.14.1/Package.swift) and [podspec](https://github.com/AzureAD/microsoft-authentication-library-for-objc/blob/2.14.1/MSAL.podspec). A plugin/application declaration of 15 cannot override that requirement. The actual upstream public product is `MSAL`. Xcode synthesizes `MSAL-product` in project `MSAL` when it expands this Swift package; the validated build dependency graph confirms that target. It is not a product introduced by this plugin or another independent dependency.

Investigation also found a binary-level mismatch in older releases: 2.1.0–2.6.0 declare iOS 14 in their SPM manifests but their shipped iOS device binaries have `LC_BUILD_VERSION minos 16.0`. The 2.6.0 simulator slices also target 16.0. Version 2.4.3 references the 2.4.1 binary, and 2.5.2 references the 2.5.0 binary. Merely reading deployment declarations would have produced a false compatibility claim.

Every newer tag through 2.16.1 was checked for manifest requirements. Releases from 2.7.0 declare at least iOS 16, and 2.15.0 onward declare iOS 17. Of the checked release line, 2.0.0 is the newest whose manifests and actual iOS binary support iOS 15.

## 8. Verified minimum and limits

The plugin and built Runner device/simulator binaries target **15.0**. MSAL 2.0.0 device and both simulator architectures target **14.0**. Checksums and load commands were inspected directly using `shasum`/`xcrun vtool`.

There is no iOS 15 simulator runtime installed. Native tests ran on iOS 27. These checks verify build/dependency compatibility, not actual authentication on an iOS 15 device. No iOS 16-only API was found in the plugin implementation; both native integration paths compiled for iOS 15.

## 9. MSAL version and dependency chain

Apple MSAL is exactly **2.0.0** for both distributions. Its official binary SHA-256 is `e7e8e6107d5f652d0dabaebfcedfe250f0e363b3db277db30ff30fb622cea1c1`, matching the upstream [manifest](https://github.com/AzureAD/microsoft-authentication-library-for-objc/blob/2.0.0/Package.swift). Device and simulator requirements were inspected from that binary. Evidence is in `validation/msal-platforms.json`.

SPM's Microsoft package is a binary target with no further package dependencies. CocoaPods compiles MSAL and its vendored IdentityCore submodule and includes MSAL's privacy resource bundle; its [podspec](https://github.com/AzureAD/microsoft-authentication-library-for-objc/blob/2.0.0/MSAL.podspec) declares iOS 14 and no further pod dependency. The full application → Flutter generated package → plugin → Microsoft graph resolved and built.

The older SDK pin is a compatibility decision, **not a verified upstream support/security guarantee**. Microsoft maintenance of 2.0.0 has not been established. A requirement to use currently maintained Apple MSAL may necessitate raising the application's minimum iOS version. Android MSAL 4.0.2 was retained and compiled; no claim is made that it is the latest native Android SDK.

## 10. Security and native correctness

Removed plugin/example logging of authentication results and unrestricted native exception output. Removed redundant native access-token retention. Kept the supported MSAL cache and refresh mechanisms; no custom storage, crypto or OAuth flow was introduced. HTTPS authority validation is required and explicit known-authority configuration does not automatically trust additional endpoints.

The iOS handler validates malformed arguments, maps native cancellation, marshals replies to the main queue and guards completion against duplicate delivery. Silent authority overrides are honored, account filters reach native enumeration and sign-out only clears selected state after success. Channel serialization normalizes nested claims, dates and null values. Android returns immediately for uninitialized clients, clears detached Activity references, starts interactive presentation on the main thread and stops returning/logging unrestricted exception text.

Existing access/ID token and authorization-header result fields remain for compatibility; callers must treat them as credentials. Native account data still contains personal information by design. One active native client exists per Flutter engine; Dart instances do not isolate caches or native clients.

## 11. Documentation

Replaced README and changelog; added CONTRIBUTING, SECURITY and example setup instructions. README covers Entra registration, schemes, callbacks, keychain entitlements, both package managers, actual API examples, platform differences, errors, security, troubleshooting and migration. API comments use Spanish; documentation uses English. LICENSE and original legally required attribution remain unchanged. CI configuration was created but has not run on GitHub because no push occurred.

## 12. Executed validation

Toolchain: Flutter **3.47.6 stable**, Dart **3.13.5**, Xcode **27.0**, Swift **6.4** compiling manifest tools 5.9 and Swift 5 source mode, CocoaPods **1.17.0**.

| Check | Result |
| --- | --- |
| `dart format --output=none --set-exit-if-changed .` | Passed, 47 files unchanged |
| `flutter analyze` | Passed, no issues |
| `flutter test` | Passed, 24 package tests |
| `cd example && flutter test` | Passed, 1 widget test |
| Native XCTest bridge regressions | Passed, 6 tests on installed iOS 27 simulator |
| Independent Flutter consumer public import/API analysis | Passed, no issues |
| SPM package graph resolution | Passed, MSAL 2.0.0 expected revision |
| SPM simulator build | Passed |
| SPM unsigned device build | Passed |
| CocoaPods simulator build | Passed |
| CocoaPods unsigned device build | Passed |
| `pod ipc spec` and Ruby syntax | Passed |
| Podspec lint with external iOS 15 xcconfig | Passed |
| Unmodified standalone podspec lint on Xcode 27 | Failed for upstream deployment targets below Xcode's supported range |
| Local `pana` 0.23.19 | **150/160**, 149/197 documented API elements (75.6%) |
| `git diff --check` | Passed |

The package declares Flutter 3.44 / Dart 3.12 because of current built-in Kotlin integration requirements. Actual SDK execution used 3.47.6 / 3.13.5. Pana dependency lower-bound analysis passed, but an older Flutter SDK was not installed and tested separately. The example requires Flutter 3.47 for enabled built-in Kotlin.

## 13. Publication dry-runs and archive

The repository dry-run completed validation with one warning: uncommitted source changes. Pub returns exit 65 for this warning. No actionable package-content or metadata validation warning remains. An isolated copy of the reviewed archive files passed the same dry-run with **0 warnings and exit 0** (approximately 69 KB compressed).

Archive inventory checks found no build/cache directories, local development paths, private-key/certificate formats, credentials or unnecessary binary archives. Included PNGs are the example's launcher assets. Development validation evidence and this report are excluded by `.pubignore`. The source snapshot remains in `/tmp/flutter_msal_plus_release_final`; it is not an uploaded package.

## 14. Remaining warnings

- Remote repository validation costs 10 local pana points: the public branch still contains `name: msal_flutter`. Pushing the authorized release changes is required before that check can pass; the resulting pub.dev score is not guaranteed.
- Working-tree changes cause the root publication dry-run warning; review and commit before publication.
- Flutter warns about retained CocoaPods integration when building the SPM example. It is intentional for validating both paths. Confirmed SPM builds use the generated MSAL dependency, rather than duplicate native compilation.
- Upstream MSAL source emits deprecation/Clang warnings and static-library category objects with no symbols. No plugin compile warning remains after serialization cleanup.
- Xcode skips AppIntents metadata for targets without that framework. Its XCTest library also warns that it targets iOS 17 when linked to an iOS 15 test target; tests execute on the installed iOS 27 runtime. This does not raise the application deployment target.
- Newer Flutter-pinned transitive Dart dependency releases exist; they are SDK constraints and pana awards the full dependency score.

## 15. Breaking behavior and migration

Change imports to `package:flutter_msal_plus/flutter_msal_plus.dart` and replace the dependency name. The old namespace `package:msal_flutter/...` cannot survive a package rename. The old filename remains under the new namespace. Native registration and module names change; rebuild through Flutter after migration. Keep application callbacks/configuration aligned with your registration.

Behavior changes include early input validation, HTTPS-only authorities, failed-initialization exceptions, reduced error detail exposure, honored authority overrides/filters, UTC token-expiry serialization and the corrected legacy adapter. Minimum Flutter/Dart versions increase. Apple MSAL changes from 2.14.1 to 2.0.0 to meet iOS 15 binary requirements; integrations requiring newer SDK functionality cannot use that newer native dependency with this release's exact pin.

## 16. Unresolved compatibility/acceptance checks

Real Entra login, actual browser cancellation, consent, token refresh, broker SSO and logout need the maintainer's configured registration and a signed device. An iOS 15 runtime/device test remains outstanding. Android authentication was not exercised against a real registration. Android currently ignores the optional iOS account enumeration filters and browser/global-cache sign-out options; multiple-account operation is the supported bridge mode.

No macOS, Web, Windows or Linux implementation or validation is claimed. Microsoft upstream support for Apple MSAL 2.0.0 remains unverified. The local package modernization is complete, but production release acceptance should resolve these runtime/support checks.

## 17. Manual configuration

Configure example `CLIENT_ID`, `TENANT_ID`, `REDIRECT_URI` and `SCOPE` using `--dart-define`. Update the iOS bundle identifier and matching Info.plist scheme, keychain entitlements, signing/provisioning and Entra registration. Update Android application ID/certificate hash/BrowserTabActivity redirect and any Android authority configuration. No real credentials are bundled.

The existing Git origin is `https://github.com/wikilift/msal-flutter`; that verified historical URL remains as metadata. No renamed repository URL was invented. A verified pub.dev publisher association and private security reporting contact have not been supplied. The old podspec's contact information was not asserted as a verified publisher identity.

## 18. Readiness assessment

The package is locally prepared for publication with tested build paths, a clean isolated publication dry-run, preserved APIs, documentation and regression coverage. It has not been published and does not have a verified pub.dev score. Review the source, perform signed-device acceptance tests, evaluate the older native SDK support tradeoff, and configure publisher ownership before releasing.

## 19. First version

**1.0.0** is the initial version for the independently named package. The old package's 3.x history is explained as provenance rather than copied as release history for the new name.

## 20. Publication commands

After acceptance and explicit authorization for commits/pushes, review and commit/tag the release using the repository's normal process. Upload the renamed metadata to the existing repository so pub.dev can verify it. Then run:

```sh
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
(cd example && flutter test)
XCODE_XCCONFIG_FILE="$PWD/validation/ios15.xcconfig" \
  pod lib lint ios/flutter_msal_plus.podspec \
  --configuration=Debug --skip-tests --use-modular-headers --use-libraries
flutter pub publish --dry-run
flutter pub publish
```

The final command performs publication and requires the maintainer's authenticated pub.dev account and intended publisher ownership. It was not executed. No Git tag or pushed release was created.
