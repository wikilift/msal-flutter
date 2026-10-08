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
  const account = {'identifier': 'cached-account', 'isSSOAccount': false};

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    for (final legacy in [false, true]) {
      group(
        '${platform.name} ${legacy ? 'legacy' : 'structured'} clientId only',
        () {
          setUp(() {
            debugDefaultTargetPlatformOverride = platform;
            calls.clear();
            messenger.setMockMethodCallHandler(channel, (call) async {
              calls.add(call);
              switch (call.method) {
                case 'initialize':
                case 'initWebViewParams':
                  return true;
                case 'loadAccounts':
                  return [account];
                case 'acquireToken':
                case 'acquireTokenSilent':
                  return {
                    'accessToken': 'mock-token',
                    'account': account,
                    'authority': 'https://login.microsoftonline.com/common',
                    'scopes': ['User.Read'],
                  };
              }
              throw MissingPluginException();
            });
          });
          tearDown(() {
            debugDefaultTargetPlatformOverride = null;
            messenger.setMockMethodCallHandler(channel, null);
          });

          Future<Object> initialize() async => legacy
              ? await PublicClientApplication.createPublicClientApplication(
                  'client',
                )
              : await MSALPublicClientApplication.createPublicClientApplication(
                  MSALPublicClientApplicationConfig(clientId: 'client'),
                );

          test('initialization accepts omitted tenant and authority', () async {
            await initialize();
            final arguments = calls.first.arguments as Map;
            expect(calls.first.method, 'initialize');
            expect(arguments.containsKey('tenantId'), isFalse);
            expect(arguments.containsKey('tenant_id'), isFalse);
            if (platform == TargetPlatform.android) {
              expect(arguments['client_id'], 'client');
              expect(arguments.containsKey('authorities'), isFalse);
            } else {
              expect(arguments['clientId'], 'client');
              if (legacy) {
                expect(
                  arguments['authority'],
                  'https://login.microsoftonline.com/common',
                );
              } else {
                expect(arguments.containsKey('authority'), isFalse);
              }
            }
          });

          test(
            'interactive authentication forwards scopes without tenant',
            () async {
              final app = await initialize();
              final token = app is PublicClientApplication
                  ? await app.acquireToken(['User.Read'])
                  : (await (app as MSALPublicClientApplication).acquireToken(
                      MSALInteractiveTokenParameters(scopes: ['User.Read']),
                    ))?.accessToken;
              expect(token, 'mock-token');
              expect(calls.last.method, 'acquireToken');
              expect(calls.last.arguments['scopes'], ['User.Read']);
              expect(
                (calls.last.arguments as Map).containsKey('authority'),
                isFalse,
              );
            },
          );

          test(
            'silent authentication forwards cached account without tenant',
            () async {
              final app = await initialize();
              final token = app is PublicClientApplication
                  ? await app.acquireTokenSilent(['User.Read'])
                  : (await (app as MSALPublicClientApplication)
                            .acquireTokenSilent(
                              MSALSilentTokenParameters(scopes: ['User.Read']),
                              MSALAccount(identifier: 'cached-account'),
                            ))
                        ?.accessToken;
              expect(token, 'mock-token');
              expect(calls.last.method, 'acquireTokenSilent');
              expect(calls.last.arguments['accountId'], 'cached-account');
              expect(calls.last.arguments['tokenParameters']['scopes'], [
                'User.Read',
              ]);
              expect(
                (calls.last.arguments['tokenParameters'] as Map).containsKey(
                  'overrideAuthority',
                ),
                isFalse,
              );
            },
          );
        },
      );
    }
  }
}
