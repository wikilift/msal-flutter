import '../flutter_msal_plus.dart';

class PublicClientApplication {
  final MSALPublicClientApplication _application;
  PublicClientApplication._(this._application);

  static Future<PublicClientApplication> createPublicClientApplication(
    String clientId, {
    String? authority,
    String? redirectUri,
    String? androidRedirectUri,
    String? iosRedirectUri,
    String? keychain,
    bool? privateSession,
  }) async {
    final application =
        await MSALPublicClientApplication.createPublicClientApplication(
          MSALPublicClientApplicationConfig(
            clientId: clientId,
            authority: Uri.parse(
              authority ?? 'https://login.microsoftonline.com/common',
            ),
            androidRedirectUri: androidRedirectUri ?? redirectUri,
            iosRedirectUri: iosRedirectUri ?? redirectUri,
            cacheConfig: keychain == null
                ? null
                : MSALCacheConfig(keychainSharingGroup: keychain),
          ),
        );
    await application.initWebViewParams(
      MSALWebviewParameters(
        prefersEphemeralWebBrowserSession: privateSession ?? false,
      ),
    );
    return PublicClientApplication._(application);
  }

  Future<String> acquireToken(List<String> scopes, [bool? clearSession]) async {
    final result = await _application.acquireToken(
      MSALInteractiveTokenParameters(
        scopes: scopes,
        promptType: clearSession == true ? MSALPromptType.selectAccount : null,
      ),
    );
    if (result == null) {
      throw MsalException('No authentication result returned');
    }
    return result.accessToken;
  }

  Future<List<Map<String, dynamic>>> loadAccounts() async =>
      (await _application.loadAccounts() ?? [])
          .map((account) => account.toMap())
          .toList();

  Future<String> acquireTokenSilent(List<String> scopes) async {
    final accounts = await _application.loadAccounts();
    if (accounts == null || accounts.isEmpty) throw MsalNoAccountException();
    final result = await _application.acquireTokenSilent(
      MSALSilentTokenParameters(scopes: scopes),
      accounts.first,
    );
    if (result == null) {
      throw MsalException('No authentication result returned');
    }
    return result.accessToken;
  }

  Future<void> logout({bool browserLogout = false}) async {
    for (final account
        in await _application.loadAccounts() ?? <MSALAccount>[]) {
      await _application.logout(
        MSALSignoutParameters(signoutFromBrowser: browserLogout),
        account,
      );
    }
  }
}
