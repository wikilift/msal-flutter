import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msal_flutter/msal_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('msal_flutter');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  MSALPublicClientApplicationConfig validConfig({
    String clientId = '00000000-0000-0000-0000-000000000000',
    Uri? authority,
    MSALCacheConfig? cacheConfig,
  }) {
    return MSALPublicClientApplicationConfig(
      clientId: clientId,
      iosRedirectUri: 'msal00000000-0000-0000-0000-000000000000://auth',
      authority:
          authority ?? Uri.parse('https://login.microsoftonline.com/common'),
      cacheConfig: cacheConfig,
    );
  }

  test('CONFIG_ERROR preserves PlatformException message', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(
        code: 'CONFIG_ERROR',
        message: 'Native MSAL configuration failure',
        details: {
          'domain': 'MSALErrorDomain',
          'code': -50000,
        },
      );
    });

    expect(
      () => MSALPublicClientApplication.createPublicClientApplication(
          validConfig()),
      throwsA(
        isA<MsalInvalidConfigurationException>().having(
          (e) => e.toString(),
          'message',
          contains('Native MSAL configuration failure'),
        ),
      ),
    );
  });

  test('CONFIG_ERROR falls back to details when message is absent', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(
        code: 'CONFIG_ERROR',
        details: {
          'domain': 'MSALErrorDomain',
          'code': -50001,
          'localizedDescription': 'Detailed native failure',
        },
      );
    });

    expect(
      () => MSALPublicClientApplication.createPublicClientApplication(
          validConfig()),
      throwsA(
        isA<MsalInvalidConfigurationException>().having(
          (e) => e.toString(),
          'details',
          allOf(
            contains('MSALErrorDomain'),
            contains('Detailed native failure'),
          ),
        ),
      ),
    );
  });

  test('MsalInvalidConfigurationException.toString includes real message', () {
    final exception = MsalInvalidConfigurationException('Real native message');

    expect(exception.toString(), 'Real native message');
  });

  test('missing client id is converted to a controlled configuration error',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      final arguments = Map<String, dynamic>.from(call.arguments as Map);
      if ((arguments['clientId'] as String).isEmpty) {
        throw PlatformException(
          code: 'NO_CLIENTID',
          message: 'Call must include a non-empty clientId',
        );
      }
      return true;
    });

    expect(
      () => MSALPublicClientApplication.createPublicClientApplication(
        validConfig(clientId: ''),
      ),
      throwsA(
        isA<MsalInvalidConfigurationException>().having(
          (e) => e.toString(),
          'message',
          contains('non-empty clientId'),
        ),
      ),
    );
  });

  test('missing authority is converted to a controlled configuration error',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      final arguments = Map<String, dynamic>.from(call.arguments as Map);
      if (!arguments.containsKey('authority')) {
        throw PlatformException(
          code: 'INVALID_AUTHORITY',
          message: 'Call must include a non-empty authority URL',
        );
      }
      return true;
    });

    expect(
      () => MSALPublicClientApplication.createPublicClientApplication(
        MSALPublicClientApplicationConfig(
          clientId: '00000000-0000-0000-0000-000000000000',
          iosRedirectUri: 'msal00000000-0000-0000-0000-000000000000://auth',
        ),
      ),
      throwsA(
        isA<MsalInvalidConfigurationException>().having(
          (e) => e.toString(),
          'message',
          contains('authority URL'),
        ),
      ),
    );
  });

  test('invalid authority is converted to a controlled configuration error',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(
        code: 'INVALID_AUTHORITY',
        message: 'Invalid authority URL: not-a-url',
      );
    });

    expect(
      () => MSALPublicClientApplication.createPublicClientApplication(
        validConfig(authority: Uri.parse('not-a-url')),
      ),
      throwsA(
        isA<MsalInvalidConfigurationException>().having(
          (e) => e.toString(),
          'message',
          contains('not-a-url'),
        ),
      ),
    );
  });

  test('keychain sharing group is not sent when cacheConfig is absent',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      final arguments = Map<String, dynamic>.from(call.arguments as Map);
      expect(arguments.containsKey('cacheConfig'), isFalse);
      expect(arguments.toString(), isNot(contains('com.microsoft.adalcache')));
      return true;
    });

    await MSALPublicClientApplication.createPublicClientApplication(
      validConfig(),
    );
  });

  test('provided keychain sharing group is sent unchanged', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      final arguments = Map<String, dynamic>.from(call.arguments as Map);
      final cacheConfig = Map<String, dynamic>.from(
        arguments['cacheConfig'] as Map,
      );
      expect(cacheConfig['keychainSharingGroup'], 'com.example.sharedcache');
      return true;
    });

    await MSALPublicClientApplication.createPublicClientApplication(
      validConfig(
        cacheConfig: MSALCacheConfig(
          keychainSharingGroup: 'com.example.sharedcache',
        ),
      ),
    );
  });

  test('valid configuration initializes successfully', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'initialize');
      return true;
    });

    final application =
        await MSALPublicClientApplication.createPublicClientApplication(
      validConfig(),
    );

    expect(application, isA<MSALPublicClientApplication>());
  });
}
