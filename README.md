# flutter_msal_plus

Flutter integration with Microsoft's native Authentication Library (MSAL), maintained by WikiLift. It provides interactive authentication, silent token acquisition, account enumeration, and sign-out using MSAL's native cache. It originated from `msal_flutter`; original copyright and license notices remain in [LICENSE](LICENSE).

## Features and platform requirements

- Structured authentication results, account information, authority and redirect configuration.
- Interactive browser authentication, configurable prompts and web presentation on iOS.
- Silent acquisition and `forceRefresh` through MSAL.
- Account selection and browser sign-out.
- iOS integration through Swift Package Manager or CocoaPods.
- Android integration with current built-in Kotlin; debug compilation verified.

No application state management dependency is required. Web, macOS, Windows and Linux implementations are not provided.

| Component | Requirement |
| --- | --- |
| Dart | 3.12 or newer, below 4.0 |
| Flutter | 3.44 or newer; builds tested with 3.47.6 |
| iOS | Deployment target 15.0 or newer |
| Swift package tools | 5.9 or newer |
| Apple MSAL | Exactly 2.0.0, for both package managers |
| Android | Existing API 26 minimum, Java 17; native MSAL 4.0.2 |

MSAL 2.0.0 is the newest checked release whose manifest, podspec and shipped device/simulator binaries support iOS 15. Its declared and binary minimum is iOS 14.0. Releases 2.1.0 through 2.6.0 still declare iOS 14 in their manifests but ship iOS binaries with a 16.0 minimum. From 2.7.0 the manifests also require iOS 16; 2.15.0 requires iOS 17. The exact pin prevents resolution from silently dropping iOS 15 support.

This is an older SDK: compatibility does not establish that Microsoft still supports this release. Review upstream security fixes before releasing applications that depend on it. See the [2.0.0 manifest](https://github.com/AzureAD/microsoft-authentication-library-for-objc/blob/2.0.0/Package.swift), [podspec](https://github.com/AzureAD/microsoft-authentication-library-for-objc/blob/2.0.0/MSAL.podspec), and [release history](https://github.com/AzureAD/microsoft-authentication-library-for-objc/releases).

## Installation

After this package is published:

```yaml
dependencies:
  flutter_msal_plus: ^1.0.0
```

For local development, use a path dependency pointing to this checkout, as the example does.

```dart
import 'package:flutter_msal_plus/flutter_msal_plus.dart';
```

## Microsoft Entra app registration

1. Register a public client application in Microsoft Entra ID. Select supported account types appropriate for your tenant.
2. Add an iOS/macOS platform with the application's exact bundle identifier. Register `msauth.<bundle-identifier>://auth`, matching the value passed to this package.
3. Configure delegated API permissions, such as Microsoft Graph `User.Read`, and obtain administrator consent where required by your tenant.
4. Initialize with the application's client ID. No `tenantId` or explicit authority is required. Configure the platform redirect URI to match your registration.
5. Never embed a client secret in a mobile application. This plugin delegates authentication to MSAL; it does not implement a custom OAuth flow.

For B2C, use the authority for your actual policy/user flow and explicitly configure `knownAuthorities` when required. The explicit initialization authority remains in `knownAuthorities`, matching the original bridge. Additional entries are appended.

Follow Microsoft's [installation and configuration guide](https://learn.microsoft.com/en-us/entra/msal/objc/install-and-configure-msal) for registration, broker requirements and keychain entitlements.

## iOS configuration

Set the Runner deployment target to **15.0** in every Xcode build configuration, including tests. For CocoaPods, set `platform :ios, '15.0'` in `ios/Podfile`.

Add the redirect scheme and broker query schemes to `Info.plist`. For bundle identifier `com.example.app`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array><string>msauth.com.example.app</string></array>
  </dict>
</array>
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>msauthv2</string>
  <string>msauthv3</string>
</array>
```

If you omit `iosRedirectUri`, native MSAL receives `msauth.<bundle-identifier>://auth`. A custom redirect URI must match both your registration and the URL scheme in `Info.plist`.

Configure Keychain Sharing in Xcode with `com.microsoft.adalcache` as specified by Microsoft. Ensure provisioning profiles include the entitlement. If you pass a custom `MSALCacheConfig(keychainSharingGroup: ...)`, enable that same group for the application; the plugin does not create entitlements. MSAL's default cache settings are left intact when no custom group is supplied.

Forward authentication URLs exactly once. The example forwards them from its scene delegate. For scene-based applications:

```swift
import MSAL

// Reenvía cada URL a MSAL desde el delegado de escena.
func scene(_ scene: UIScene, openURLContexts contexts: Set<UIOpenURLContext>) {
    for context in contexts {
        MSALPublicClientApplication.handleMSALResponse(
            context.url,
            sourceApplication: context.options.sourceApplication
        )
    }
}
```

For applications without scenes, add this override to `AppDelegate`:

```swift
import MSAL

override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
) -> Bool {
    if MSALPublicClientApplication.handleMSALResponse(
        url,
        sourceApplication: options[.sourceApplication] as? String
    ) { return true }
    return super.application(app, open: url, options: options)
}
```

### Swift Package Manager

Enable SPM through Flutter's supported configuration:

```sh
flutter config --enable-swift-package-manager
flutter pub get
flutter build ios --simulator
```

The plugin's manifest is `ios/flutter_msal_plus/Package.swift`, with product `flutter-msal-plus` and target `flutter_msal_plus`. The relative `FlutterFramework` dependency follows Flutter's generated package integration. Building the plugin with standalone `swift build` is not a substitute for a Flutter iOS build: Flutter supplies this framework package.

Do not add MSAL or this plugin as another direct Runner package dependency. Flutter supplies the plugin, and the plugin supplies MSAL. Direct package overrides can cause identity conflicts for local path dependencies.

### CocoaPods

```sh
flutter config --no-enable-swift-package-manager
flutter pub get
flutter build ios --simulator
```

The podspec compiles the same Swift implementation and pins `MSAL` to 2.0.0. It does not compile an additional Objective-C registration wrapper. Use one integration path for this plugin in each build.

## Usage

The native channel maintains one active client per Flutter engine. Multiple Dart application objects do not represent isolated native caches or clients. Initialize once for your configuration and keep that object in your application's own state.

### Initialization and interactive authentication

```dart
final application = await MSALPublicClientApplication.createPublicClientApplication(
  MSALPublicClientApplicationConfig(
    clientId: 'YOUR-CLIENT-ID',
    iosRedirectUri: 'msauth.com.example.app://auth',
    androidRedirectUri: 'msauth://com.example.app/YOUR-SIGNATURE-HASH',
    authority: Uri.parse('https://login.microsoftonline.com/common/'),
  ),
);

await application.initWebViewParams(
  MSALWebviewParameters(prefersEphemeralWebBrowserSession: true),
);

final result = await application.acquireToken(
  MSALInteractiveTokenParameters(
    scopes: ['https://api.example.com/application/user_impersonation'],
    promptType: MSALPromptType.selectAccount,
  ),
);
```

Initialization and interactive authentication require a foreground iOS presentation controller. Webview configuration is an iOS feature; the Dart method is a no-op on Android. Authentication results remain nullable for compatibility with existing applications; check them before use.

The scope above is a placeholder for a custom enterprise API. Use your existing registered redirect URI and enterprise scope exactly; do not substitute Microsoft Graph permissions for an existing resource. Native MSAL still validates custom redirect schemes. MSAL 2.x on iOS imposes broker-capable redirect requirements for AAD authorities, so an older custom scheme may require compatibility investigation; the plugin does not bypass that validation.

### Optional advanced authority configuration

With no explicit authority, iOS MSAL uses `https://login.microsoftonline.com/common`; Android MSAL uses its default AAD audience `AzureADandPersonalMicrosoftAccount`, which resolves to the same endpoint. This supports work/school and personal Microsoft accounts within the account types permitted by your application registration. It does not broaden the registration's permissions or supported audience. Single-tenant registrations can require their tenant-specific authority under Microsoft's service rules.

Both public APIs accept clientId-only initialization:

```dart
final structured = await MSALPublicClientApplication.createPublicClientApplication(
  MSALPublicClientApplicationConfig(clientId: 'YOUR-CLIENT-ID'),
);
final legacy = await PublicClientApplication.createPublicClientApplication(
  'YOUR-CLIENT-ID',
);
```

Redirect schemes, entitlements and Android redirect registration still require platform setup. Silent acquisition uses a cached account and token; no tenant ID is needed, but Microsoft can require interactive authentication when the cache or consent is insufficient.

For an optional tenant-specific iOS configuration, set `authority: Uri.parse('https://login.microsoftonline.com/YOUR-TENANT-ID')` on the structured configuration, or pass the equivalent `authority` string to the legacy factory. Android-specific authorities are configured through `MSALAndroidConfig.authorities`; omitting that configuration preserves the SDK's generic default. The top-level configuration `authority` is serialized for iOS, as in the original implementation. B2C/custom authorities require their own registration and configuration.

See [Microsoft's authority and audience documentation](https://learn.microsoft.com/en-us/entra/identity-platform/msal-client-application-configuration) and [Android configuration documentation](https://learn.microsoft.com/en-us/azure/active-directory/develop/msal-configuration).

### Accounts, silent acquisition and refresh

```dart
final accounts = await application.loadAccounts() ?? <MSALAccount>[];
if (accounts.isNotEmpty) {
  final account = accounts.first;
  final result = await application.acquireTokenSilent(
    MSALSilentTokenParameters(scopes: ['https://api.example.com/application/user_impersonation'], forceRefresh: false),
    account,
  );
  final expiresOn = result?.expiresOn;
}
```

Select an account intentionally in applications with multiple accounts. Passing `null` preserves the historical native fallback to the current or first cached account. Set `forceRefresh: true` to request a refresh through MSAL. Refresh tokens are handled by the native cache and are not exposed by this package.

Both platforms preserve local account enumeration. The optional enumeration-parameter signature remains source-compatible; iOS filters are not applied, matching the original bridge.

### Logout

```dart
if (accounts.isNotEmpty) {
  final removed = await application.logout(
    const MSALSignoutParameters(signoutFromBrowser: true),
    accounts.first,
  );
}
```

Browser sign-out, `wipeAccount`, and `wipeCacheForAllAccounts` are native iOS MSAL options. Broad cache wiping can affect other accounts and shared SSO. Android removes the selected local account and does not implement these browser/cache-wipe options. Local cache removal alone does not revoke server-side sessions or previously issued tokens.

### Error handling

```dart
try {
  await application.acquireToken(MSALInteractiveTokenParameters(scopes: ['User.Read']));
} on MsalUserCancelledException {
  // Permite que el usuario vuelva a intentarlo.
} on MsalInvalidConfigurationException catch (error) {
  // Corrige la configuración antes de reintentar.
} on MsalException catch (error) {
  // Muestra un mensaje adecuado sin registrar material de autenticación.
}
```

Invalid client IDs, authority URL syntax, expiration buffers, scopes, query parameter types and correlation UUIDs are rejected before the native call. iOS cancellation maps to `MsalUserCancelledException`. Authentication failures otherwise map to `MsalException`; a silent failure can require interactive authentication. Missing platform implementations still raise Flutter's `MissingPluginException`.

## Security

MSAL owns token persistence and refresh. The plugin does not add another token store. Existing result fields include access tokens, ID tokens and authorization headers; treat all of them as credentials. Do not print results, persist them in application preferences, include them in crash reports, or display them in a demo interface. Account claims and usernames are personal data.

Native authentication errors expose a controlled message plus numeric code/domain rather than arbitrary MSAL error descriptions or `userInfo`. Logging is not enabled by this plugin. HTTPS authorities are required; leave redirect validation enabled. Explicit `knownAuthorities` should be limited to the authorities you trust.

## Android configuration

Android debug compilation is verified; real authentication must be checked before shipping. Use an Entra Android registration with your application ID and signing certificate hash. Configure `BrowserTabActivity` to match the resulting `msauth://<application-id>/<signature-hash>` redirect. Pass `androidRedirectUri` and, when needed, `MSALAndroidConfig` with the registered authorities. The example manifest contains a signature placeholder to replace with your own hash. `MSALAndroidConfig` defaults to multiple-account mode; single-account mode is not implemented by this bridge.

## Troubleshooting

- **MSAL requires iOS 16:** inspect the resolved version. This release requires exactly 2.0.0. An app's own MSAL dependency can conflict with that pin. MSAL 2.14.1 genuinely requires iOS 16.
- **Package identity mismatch:** remove obsolete direct plugin package references from Runner. Rebuild through Flutter. The example uses only `FlutterGeneratedPluginSwiftPackage`.
- **Stale resolution:** run `flutter clean`, `flutter pub get`, and rebuild. In CocoaPods, use `pod update MSAL flutter_msal_plus` after changing the dependency. Inspect `Package.resolved` or `Podfile.lock` to confirm 2.0.0. Use Xcode's supported package cache reset if needed. Do not manually patch `ephemeral`, `.pub-cache` or DerivedData.
- **Configuration failure:** verify the registered client ID, HTTPS authority, bundle identifier, redirect scheme and keychain provisioning entitlements.
- **No presentation controller:** initialize after the app has a foreground Flutter view. Avoid invoking interactive methods from background isolates.
- **No cached account:** complete an interactive sign-in and reload accounts. Broker accounts may not be locally cached; supply the selected account identifier.
- **Silent authentication fails:** consent, policy changes or an expired session may require an interactive request.

## Migration from msal_flutter

Replace the dependency name and imports with `flutter_msal_plus`. Rebuild native dependencies after the rename. The old filename remains available as `package:flutter_msal_plus/msal_flutter.dart`; the former package namespace cannot be preserved after a package rename.

The structured `MSALPublicClientApplication` API and existing models retain their names and mutable fields. `PublicClientApplication` remains as a compatibility adapter returning token strings. Its `loadAccounts()` now safely converts channel maps, and logout removes each cached account. The channel name `msal_flutter` is intentionally retained for native integrations that already use it.

Behavior changes: malformed inputs fail earlier, HTTPS is required, failed initialization throws, native error details are redacted, interactive authority overrides retain the original behavior; iOS silent authority overrides and enumeration filters remain unused, matching the original bridge. iOS token expiry retains the original date format without an offset. iOS now targets 15.0 and pins MSAL 2.0.0, replacing 2.14.1; applications requiring newer native MSAL features must use a higher iOS minimum and a different package release.

## Example and maintenance

See [example/README.md](example/README.md) for configuration and build instructions. WikiLift maintains this package in the [existing repository](https://github.com/wikilift/msal-flutter). The repository directory/URL retains its historical name; package metadata and native modules use the new identity. No separate publisher email or renamed repository URL has been supplied.

See [CONTRIBUTING.md](CONTRIBUTING.md) for validation and [SECURITY.md](SECURITY.md) for reporting guidance. The package uses the BSD 3-Clause license with the original notices preserved. Microsoft MSAL is separately licensed by Microsoft.

## Release validation

Local `pana` 0.23.19 analysis reports **150/160** points with 75.6% public API documentation coverage. The remaining 10 points require the remote repository to contain the renamed package metadata; these local changes have not been pushed. This is a local measurement, not an awarded pub.dev score.

Simulator and unsigned device compilation are verified separately from authentication. No iOS 15 runtime is installed in the validation environment; deployment target 15.0 and native binary requirements are checked, but sign-in on an iOS 15 device remains a release acceptance check.
