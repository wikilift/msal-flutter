## 1.0.0

Initial independent `flutter_msal_plus` release, derived from the WikiLift fork of `msal_flutter`. Historical upstream version numbers are not versions of this package.

- Rename package, native modules and registration metadata; retain the legacy Dart filename and method-channel name intentionally.
- Unify CocoaPods/SPM registration around one Swift class and standard Flutter package layout.
- Target iOS 15.0 and pin Apple MSAL to 2.0.0. MSAL 2.1.0 and newer ship SwiftPM binaries requiring iOS 16 or newer.
- Preserve structured authentication/configuration models and adapt the legacy token-string API.
- Validate configuration and token parameters before native calls.
- Handle malformed native arguments, cancellation and completion delivery on the main thread.
- Redact native error details, remove token logging and redundant token retention.
- Apply account enumeration filters on iOS and honor silent authority overrides.
- Modernize the example, tests, documentation and publication exclusions.
- Require Flutter 3.44 / Dart 3.12 for built-in Kotlin compatibility; the example uses Flutter 3.47.

Migration requires changing the dependency/import namespace and rebuilding native dependencies. HTTPS authorities, early validation, failed-initialization exceptions and redacted errors are intentional behavior changes. See README for platform differences and limitations.
