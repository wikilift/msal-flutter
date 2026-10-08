# Authentication example

The example demonstrates initialization, interactive authentication, silent acquisition, selecting accounts and browser sign-out. It displays expiry and account information, never token values. The initial client ID is empty so no real registration is bundled.

Configure an Entra public client registration and the iOS URL scheme/keychain entitlements described in the package README. The checked-in iOS bundle identifier is `com.example.a`, with redirect `msauth.com.example.a://auth`; replace both together for your own app.

```sh
flutter pub get
flutter run \
  --dart-define=CLIENT_ID=YOUR-CLIENT-ID \
  --dart-define=REDIRECT_URI=msauth.com.example.a://auth \
  --dart-define=SCOPE=https://api.example.com/application/user_impersonation
```

No tenant ID is required. The example omits authority configuration and uses MSAL’s generic default. `SCOPE` defaults to a placeholder enterprise API scope; replace it with your existing application’s exact registered API scope. For optional tenant-specific configuration, follow the advanced authority section in the package README. Android requires a different redirect with the application ID and certificate hash, and matching `BrowserTabActivity` manifest configuration. Replace the signature placeholder before testing Android login.

```sh
flutter analyze
flutter test
flutter config --enable-swift-package-manager
flutter build ios --simulator
flutter config --no-enable-swift-package-manager
flutter build ios --simulator
```

Both iOS integration paths target iOS 15.0. Use a signed device to verify keychain/broker behavior and real authentication. Builds without credentials only verify compilation.
