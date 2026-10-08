import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_msal_plus/flutter_msal_plus.dart';

// Valores exactos del contrato de producción; este archivo no se publica.
const productionClientId = '701e9fb7-feb3-4832-a4d7-a706dbe54c40';
const productionRedirectUri = 'msal701e9fb7-feb3-4832-a4d7-a706dbe54c40://auth';
const productionAuthority = 'https://login.microsoftonline.com/common/';
const productionScope =
    'https://otiselevator.com/NonOtisSVTAPI-prod-ES/user_impersonation';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('msal_flutter');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];
  const accounts = [
    {'identifier': 'first-cache-id', 'isSSOAccount': false},
    {'identifier': 'selected-cache-id', 'isSSOAccount': false},
  ];
  Map<String, dynamic> response() => {
    'accessToken': 'synthetic-sensitive-token',
    'account': accounts.last,
    'authority': productionAuthority,
    'scopes': [productionScope],
    'expiresOn': '2026-10-08T12:30:00+02:00',
    'idToken': null,
    'tenantProfile': null,
    'extendedLifeTimeToken': null,
  };

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    for (final legacy in [false, true]) {
      group(
        '${platform.name} ${legacy ? 'legacy' : 'structured'} production',
        () {
          setUp(() {
            debugDefaultTargetPlatformOverride = platform;
            calls.clear();
            messenger.setMockMethodCallHandler(channel, (call) async {
              calls.add(call);
              switch (call.method) {
                case 'initialize':
                case 'initWebViewParams':
                case 'logout':
                  return true;
                case 'loadAccounts':
                  return accounts;
                case 'acquireToken':
                case 'acquireTokenSilent':
                  return response();
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
                  productionClientId,
                  authority: productionAuthority,
                  iosRedirectUri: productionRedirectUri,
                  androidRedirectUri: productionRedirectUri,
                )
              : await MSALPublicClientApplication.createPublicClientApplication(
                  MSALPublicClientApplicationConfig(
                    clientId: productionClientId,
                    authority: Uri.parse(productionAuthority),
                    iosRedirectUri: productionRedirectUri,
                    androidRedirectUri: productionRedirectUri,
                    // Opción existente de OmniTool; no se activa por defecto.
                    bypassRedirectURIValidation: true,
                  ),
                );

          Future<Object?> interactive(Object app) async =>
              app is PublicClientApplication
              ? await app.acquireToken([productionScope])
              : await (app as MSALPublicClientApplication).acquireToken(
                  MSALInteractiveTokenParameters(scopes: [productionScope]),
                );

          Future<Object?> silent(Object app) async =>
              app is PublicClientApplication
              ? await app.acquireTokenSilent([productionScope])
              : await (app as MSALPublicClientApplication).acquireTokenSilent(
                  MSALSilentTokenParameters(scopes: [productionScope]),
                  MSALAccount(identifier: 'selected-cache-id'),
                );

          test(
            'accepts exact client, custom redirect and common without tenant',
            () async {
              await initialize();
              final args = calls.first.arguments as Map;
              expect(
                args[platform == TargetPlatform.android
                    ? 'client_id'
                    : 'clientId'],
                productionClientId,
              );
              expect(
                args[platform == TargetPlatform.android
                    ? 'redirect_uri'
                    : 'redirectUri'],
                productionRedirectUri,
              );
              expect(args.containsKey('tenantId'), isFalse);
              expect(args.containsKey('tenant_id'), isFalse);
              if (platform == TargetPlatform.iOS) {
                expect(args['authority'], productionAuthority);
                expect(args['bypassRedirectURIValidation'], !legacy);
              } else {
                // La ruta original de Android usa la autoridad genérica del SDK.
                expect(args.containsKey('authorities'), isFalse);
              }
            },
          );

          test(
            'interactive arguments preserve enterprise scope and return type',
            () async {
              final result = await interactive(await initialize());
              expect(calls.last.method, 'acquireToken');
              expect(calls.last.arguments, {
                'scopes': [productionScope],
              });
              if (legacy) {
                expect(result, isA<String>());
                expect(result, 'synthetic-sensitive-token');
              } else {
                expect(result, isA<MSALResult>());
                final parsed = result as MSALResult;
                expect(parsed.accessToken, 'synthetic-sensitive-token');
                expect(parsed.authority.toString(), productionAuthority);
                expect(parsed.scopes, [productionScope]);
                expect(parsed.expiresOn, DateTime.utc(2026, 10, 8, 10, 30));
                expect(parsed.idToken, isNull);
                expect(parsed.tenantProfile, isNull);
                expect(parsed.extendedLifeTimeToken, isNull);
                expect(parsed.account.username, isNull);
              }
            },
          );

          test(
            'account enumeration preserves identifiers and nullable fields',
            () async {
              final app = await initialize();
              if (app is PublicClientApplication) {
                final listed = await app.loadAccounts();
                expect(listed.map((account) => account['identifier']), [
                  'first-cache-id',
                  'selected-cache-id',
                ]);
              } else {
                final listed = await (app as MSALPublicClientApplication)
                    .loadAccounts();
                expect(listed!.map((account) => account.identifier), [
                  'first-cache-id',
                  'selected-cache-id',
                ]);
                expect(listed.first.username, isNull);
                expect(listed.first.accountClaims, isNull);
              }
              expect(calls.last.method, 'loadAccounts');
            },
          );

          test(
            'silent lookup preserves account identifier and scope',
            () async {
              final result = await silent(await initialize());
              expect(calls.last.method, 'acquireTokenSilent');
              expect(calls.last.arguments, {
                'accountId': legacy ? 'first-cache-id' : 'selected-cache-id',
                'tokenParameters': {
                  'scopes': [productionScope],
                },
              });
              if (legacy) {
                expect(calls[calls.length - 2].method, 'loadAccounts');
                expect(result, isA<String>());
              } else {
                expect(result, isA<MSALResult>());
              }
            },
          );

          test(
            'cancellation and native failures retain exception types',
            () async {
              final app = await initialize();
              for (final entry in {
                'CANCELLED': isA<MsalUserCancelledException>(),
                'NO_ACCOUNT': isA<MsalNoAccountException>(),
                'CONFIG_ERROR': isA<MsalInvalidConfigurationException>(),
                'INVALID_GRANT': isA<MsalInvalidGrantException>(),
                'AUTH_ERROR': isA<MsalException>(),
              }.entries) {
                messenger.setMockMethodCallHandler(channel, (_) async {
                  throw PlatformException(
                    code: entry.key,
                    message: 'Safe failure',
                    details: {'accessToken': 'synthetic-sensitive-token'},
                  );
                });
                await expectLater(() => interactive(app), throwsA(entry.value));
              }
            },
          );

          test(
            'null channel results preserve structured nullable contract',
            () async {
              final app = await initialize();
              messenger.setMockMethodCallHandler(channel, (_) async => null);
              if (legacy) {
                await expectLater(
                  () => interactive(app),
                  throwsA(isA<MsalException>()),
                );
                await expectLater(
                  () => silent(app),
                  throwsA(isA<MsalNoAccountException>()),
                );
              } else {
                expect(await interactive(app), isNull);
                expect(await silent(app), isNull);
              }
            },
          );

          test('token and native credential details are not printed', () async {
            final app = await initialize();
            final printed = <String>[];
            await runZoned(
              () async {
                await interactive(app);
                await silent(app);
                messenger.setMockMethodCallHandler(channel, (_) async {
                  throw PlatformException(
                    code: 'AUTH_ERROR',
                    details: {'accessToken': 'synthetic-sensitive-token'},
                  );
                });
                try {
                  await interactive(app);
                } on MsalException catch (error) {
                  expect(
                    error.toString(),
                    isNot(contains('synthetic-sensitive-token')),
                  );
                }
              },
              zoneSpecification: ZoneSpecification(
                print: (_, _, _, line) => printed.add(line),
              ),
            );
            expect(
              printed.join(),
              isNot(contains('synthetic-sensitive-token')),
            );
          });

          test(
            'logout targets selected account or every legacy account',
            () async {
              final app = await initialize();
              if (app is PublicClientApplication) {
                await app.logout();
                expect(
                  calls
                      .where((call) => call.method == 'logout')
                      .map((call) => call.arguments['accountId']),
                  ['first-cache-id', 'selected-cache-id'],
                );
              } else {
                await (app as MSALPublicClientApplication).logout(
                  const MSALSignoutParameters(),
                  MSALAccount(identifier: 'selected-cache-id'),
                );
                expect(calls.last.arguments['accountId'], 'selected-cache-id');
              }
            },
          );
        },
      );
    }
  }
}
