# Client-ID-only compatibility audit

For the subsequent exact production redirect/resource audit and the corrected differential diagnosis, see [PRODUCTION_AUTH_AUDIT.md](PRODUCTION_AUTH_AUDIT.md). The default-authority checks here do not establish production redirect compatibility.

Audited on 2026-10-08 against original checkout commit `b44c247cf03b00eecc27a8982710432ab517af23`, the modernized working tree before this follow-up, and the corrected working tree. No commit, push or publication was performed.

## Exact initialization behavior

| Implementation | iOS | Android |
| --- | --- | --- |
| Original legacy Dart `PublicClientApplication` | Required only positional `clientId`; `authority` and redirects were optional. The older **unregistered v1** Swift implementation passed `authority: nil` when absent, using MSAL's generic default. However, the checkout registered its v2 handler, which rejected missing authority with `INVALID_AUTHORITY`. The legacy Dart/native channel formats also differed. The intended old fallback therefore existed in source, but the registered checkout did not reliably implement it. | Older **unregistered v1** native code passed optional authority to MSAL and generated `msauth://<package>/auth` when redirect was omitted. The registered v2 handler expected configuration JSON, whereas legacy Dart supplied legacy keys. Do not infer a working legacy runtime from the optional Dart signature alone. |
| Original structured `MSALPublicClientApplication` | Configuration required `clientId` only and omitted absent authority from the channel payload. Registered v2 Swift rejected that payload with `INVALID_AUTHORITY`. No `tenantId` constructor argument existed. | Configuration emitted `client_id`, optional `redirect_uri`, and optional Android-specific configuration. No absent-authority/tenant validation was imposed by the plugin. Without `androidConfig.authorities`, MSAL supplied its generic default. Top-level `authority` was not serialized on Android. |
| Modernized tree before this correction | Structured factory still reached the missing-authority rejection. The legacy adapter explicitly supplied `https://login.microsoftonline.com/common`, so its missing-tenant path avoided that check. | Both APIs used the v2 JSON shape. Without Android-specific authorities, both delegated to the native generic default. |
| Corrected tree | Structured initialization now passes absent authority as `nil` to **MSAL 2.0.0**, preserving the original v1 fallback. The legacy adapter still explicitly supplies `common`. Optional explicit authority continues to be parsed and validated. Both clientId-only factory signatures compile unchanged. | No native behavior was changed: both APIs leave authorities absent by default, retaining MSAL 4.0.2's default AAD audience. Android-specific authority settings remain optional. |

Client-ID-only here means **no explicit tenant or authority**. It does not remove redirect registration, iOS URL schemes/keychain entitlements, Android manifest/certificate requirements, scopes, consent, or application-registration restrictions. In particular, Android callers must supply the correctly registered redirect URI for their application; the registered v2 path does not reproduce the unregistered v1 `/auth` redirect fallback.

## Generic authority and account types

The actual checked-out MSAL **2.0.0** source (`MSALPublicClientApplicationConfig.m`) uses `MSID_DEFAULT_AAD_AUTHORITY` when authority is nil. Its IdentityCore constant is `https://login.microsoftonline.com/common`. The native simulator regression confirms this through the linked SDK and successfully constructs a real public client application without tenant or authority.

The installed Android **MSAL 4.0.2 AAR** contains `res/raw/msal_default_config.json` with a default `AAD` authority and audience `AzureADandPersonalMicrosoftAccount`. Microsoft documents that audience as the `common` endpoint. The plugin forwards configuration unchanged and obtains its silent-request fallback from `msalApp.configuration.defaultAuthority.authorityURL`.

`common` permits organizational and personal account discovery, subject to the account types configured on the Microsoft application registration. It does not make a single-tenant registration multitenant. Microsoft's service can require a tenant-specific endpoint for a single-tenant application. B2C and custom clouds require their appropriate optional configuration. See [Microsoft authority/audience documentation](https://learn.microsoft.com/en-us/entra/identity-platform/msal-client-application-configuration) and [Android configuration documentation](https://learn.microsoft.com/en-us/azure/active-directory/develop/msal-configuration).

## Interactive and silent paths

Neither API requires a tenant parameter when acquiring tokens. Interactive parameters omit authority unless explicitly supplied; native MSAL uses the application's default. Silent parameters omit authority unless explicitly overridden. iOS constructs `MSALSilentTokenParameters` using scopes and the cached account. Android supplies the application's default authority to its silent builder. The legacy adapter loads the cached account and delegates to the structured silent path. A cache miss, expired consent or Microsoft policy can require interaction; that is independent of whether the caller supplied a tenant.

No incompatibility in generic authority selection or local client initialization was found from the iOS downgrade to MSAL 2.0.0. This is **not** a claim that every live service, broker or tenant policy was tested against that version.

## Focused changes

- Removed the iOS bridge's mandatory-authority guard; kept validation for explicitly supplied URLs.
- Added 12 mocked channel regressions: initialization, interactive acquisition and silent acquisition for each of the two APIs on each platform configuration.
- Replaced the old mocked test that incorrectly treated omitted authority as an error.
- Used Flutter's platform selector for configuration serialization and Android webview no-op so tests can exercise both platform payloads. Existing tests now explicitly select iOS where their assertions require its payload format.
- Added three native iOS regressions for the SDK's generic authority, actual local client construction, and optional explicit tenant authority.
- Changed README and example to use client ID without tenant/authority. Documented tenant-specific configuration as optional advanced usage.

## Verification and limits

- Plugin: `flutter analyze` passed; all **36 Flutter tests passed** (including the 12 new mocked regressions).
- Example: `flutter analyze` passed; its **one widget test passed**.
- iOS: **nine native XCTest tests passed** against linked MSAL 2.0.0 on the iPhone 14 Plus simulator. Three were added in this follow-up. Configuration and local SDK construction are real native tests, without mocked MSAL configuration/client objects. Result bundle: `/tmp/msal-client-id-only-20261008.xcresult`; log: `/tmp/msal-client-id-only-20261008.log`.
- Android: installed native SDK default configuration and plugin initialization/interactive/silent source paths were inspected. Flutter tests exercise Android serialization and routing with mocked channel responses. No Android device/emulator authentication test was performed.
- **No real Microsoft interactive sign-in or silent token acquisition was performed on either platform.** No usable application registration/test account was supplied. Mock tokens prove Dart/channel contracts, not Microsoft service authentication. Native iOS initialization performs no sign-in and does not validate the dummy client ID against Microsoft's service.

The clientId-only source signatures remain compatible. Runtime no-tenant behavior is covered at the Dart/channel boundary on both platforms and at actual SDK configuration/client construction on iOS; live token acquisition remains unverified.
