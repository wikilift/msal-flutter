import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_msal_plus/flutter_msal_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('msal_flutter');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];
  final accountMap = <String, dynamic>{
    'identifier': 'account-1',
    'username': 'user@example.invalid',
    'isSSOAccount': false,
  };
  Map<String, dynamic> resultMap() => {
    'accessToken': 'test-token',
    'account': accountMap,
    'authority': 'https://login.microsoftonline.com/common',
    'scopes': ['User.Read'],
    'expiresOn': '2026-10-08T10:00:00Z',
  };
  Future<MSALPublicClientApplication> initialize() =>
      MSALPublicClientApplication.createPublicClientApplication(
        MSALPublicClientApplicationConfig(
          clientId: 'test-client',
          authority: Uri.parse('https://login.microsoftonline.com/common'),
        ),
      );

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'initialize':
        case 'initWebViewParams':
        case 'logout':
          return true;
        case 'loadAccounts':
          return [accountMap];
        case 'acquireToken':
        case 'acquireTokenSilent':
          return resultMap();
      }
      throw MissingPluginException();
    });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  test(
    'interactive acquisition serializes parameters and parses native result',
    () async {
      final app = await initialize();
      final result = await app.acquireToken(
        MSALInteractiveTokenParameters(
          scopes: ['User.Read'],
          promptType: MSALPromptType.selectAccount,
        ),
      );
      expect(calls.last.method, 'acquireToken');
      expect(calls.last.arguments['promptType'], 'selectAccount');
      expect(result!.accessToken, 'test-token');
      expect(result.account.identifier, 'account-1');
      expect(result.expiresOn, DateTime.utc(2026, 10, 8, 10));
    },
  );
  test('silent acquisition uses selected account and forceRefresh', () async {
    final app = await initialize();
    await app.acquireTokenSilent(
      MSALSilentTokenParameters(scopes: ['User.Read'], forceRefresh: true),
      MSALAccount(identifier: 'account-2'),
    );
    expect(calls.last.arguments['accountId'], 'account-2');
    expect(calls.last.arguments['tokenParameters']['forceRefresh'], true);
  });
  test(
    'enumeration forwards username without requiring an identifier',
    () async {
      final app = await initialize();
      final accounts = await app.loadAccounts(
        MSALAccountEnumerationParameters.fromUsername(
          username: 'user@example.invalid',
        ),
      );
      expect(calls.last.arguments, {'username': 'user@example.invalid'});
      expect(accounts!.single.toMap(), accountMap);
    },
  );
  test('logout forwards explicit account and browser settings', () async {
    final app = await initialize();
    expect(
      await app.logout(
        const MSALSignoutParameters(signoutFromBrowser: true),
        MSALAccount(identifier: 'account-1'),
      ),
      true,
    );
    expect(calls.last.arguments['accountId'], 'account-1');
    expect(calls.last.arguments['signoutParameters'], {
      'signoutFromBrowser': true,
    });
  });
  test('cancellation maps to the public cancellation exception', () async {
    final app = await initialize();
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'CANCELLED'),
    );
    expect(
      () => app.acquireToken(
        MSALInteractiveTokenParameters(scopes: ['User.Read']),
      ),
      throwsA(isA<MsalUserCancelledException>()),
    );
  });
  test('uninitialized and missing account errors retain their types', () async {
    final app = await initialize();
    for (final entry in {
      'NO_CLIENT': isA<MsalUninitializedException>(),
      'NO_ACCOUNT': isA<MsalNoAccountException>(),
    }.entries) {
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(code: entry.key),
      );
      expect(() => app.loadAccounts(), throwsA(entry.value));
    }
  });
  test('false and null initialization results fail the factory', () async {
    for (final value in [false, null]) {
      messenger.setMockMethodCallHandler(channel, (_) async => value);
      expect(initialize, throwsA(isA<MsalInitializationException>()));
    }
  });
  test(
    'invalid scopes are rejected before invoking native acquisition',
    () async {
      final app = await initialize();
      for (final scopes in <List<String>>[
        [],
        [''],
        ['  '],
      ]) {
        await expectLater(
          () =>
              app.acquireToken(MSALInteractiveTokenParameters(scopes: scopes)),
          throwsA(isA<MsalInvalidScopeException>()),
        );
      }
      expect(calls.length, 1);
    },
  );
  test(
    'invalid configuration is rejected before calling native code',
    () async {
      for (final uri in ['http://example.invalid', 'relative']) {
        await expectLater(
          () => MSALPublicClientApplication.createPublicClientApplication(
            MSALPublicClientApplicationConfig(
              clientId: 'client',
              authority: Uri.parse(uri),
            ),
          ),
          throwsA(isA<MsalInvalidConfigurationException>()),
        );
      }
      expect(calls, isEmpty);
    },
  );
  test('query parameters and correlation identifiers are validated', () {
    expect(
      () => MSALInteractiveTokenParameters(
        scopes: ['User.Read'],
        extraQueryParameters: {'key': 42},
      ).validate(),
      throwsA(isA<MsalInvalidRequestException>()),
    );
    expect(
      () => MSALSilentTokenParameters(
        scopes: ['User.Read'],
        correlationId: 'bad',
      ).validate(),
      throwsA(isA<MsalInvalidRequestException>()),
    );
  });
  test('authority overrides reject insecure endpoints before native calls', () {
    expect(
      () => MSALInteractiveTokenParameters(
        scopes: ['User.Read'],
        authority: Uri.parse('http://example.invalid'),
      ).validate(),
      throwsA(isA<MsalInvalidRequestException>()),
    );
    expect(
      () => MSALSilentTokenParameters(
        scopes: ['User.Read'],
        overrideAuthority: Authority(authorityUrl: Uri.parse('relative')),
      ).validate(),
      throwsA(isA<MsalInvalidRequestException>()),
    );
  });
  test(
    'nullable results and account lists preserve the existing contract',
    () async {
      final app = await initialize();
      messenger.setMockMethodCallHandler(channel, (_) async => null);
      expect(await app.loadAccounts(), isNull);
      expect(
        await app.acquireToken(
          MSALInteractiveTokenParameters(scopes: ['User.Read']),
        ),
        isNull,
      );
    },
  );
  test('account round trip preserves claims and nullable values', () {
    final account = MSALAccount(
      identifier: 'account',
      accountClaims: {
        'roles': ['reader'],
      },
    );
    expect(MSALAccount.fromMap(account.toMap()).toMap(), account.toMap());
    expect(MSALAccount.fromMap({'identifier': 'account'}).username, isNull);
  });
  test(
    'legacy API adapts structured results to tokens and removes each account',
    () async {
      final app = await PublicClientApplication.createPublicClientApplication(
        'test-client',
      );
      expect(await app.acquireToken(['User.Read'], true), 'test-token');
      expect(calls.last.arguments['promptType'], 'selectAccount');
      expect(await app.acquireTokenSilent(['User.Read']), 'test-token');
      await app.logout(browserLogout: true);
      expect(calls.last.arguments['accountId'], 'account-1');
      expect(
        calls.last.arguments['signoutParameters']['signoutFromBrowser'],
        true,
      );
    },
  );
  test('result parsing tolerates missing optional fields', () {
    final result = MSALResult.fromMap(resultMap());
    expect(result.idToken, isNull);
    expect(result.tenantProfile, isNull);
    expect(MSALResult.fromMap({'expiresOn': 'invalid'}).expiresOn, isNull);
    expect(
      () => MSALResult.fromMap({
        'scopes': [123],
      }),
      throwsA(isA<TypeError>()),
    );
  });
}
