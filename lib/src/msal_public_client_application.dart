import 'package:flutter/foundation.dart';

import 'package:flutter/services.dart';

import '../flutter_msal_plus.dart';

/// Cliente MSAL asociado al canal nativo del motor Flutter.
class MSALPublicClientApplication {
  static const MethodChannel _channel = MethodChannel('msal_flutter');

  /// Inicializa el cliente y rechaza configuraciones o resultados nativos fallidos.
  static Future<MSALPublicClientApplication> createPublicClientApplication(
    MSALPublicClientApplicationConfig config,
  ) async {
    final clientApplication = MSALPublicClientApplication();
    if (!await clientApplication._initialize(config)) {
      throw MsalInitializationException();
    }
    return clientApplication;
  }

  Future<bool> _initialize(MSALPublicClientApplicationConfig config) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'initialize',
        config.toMap(),
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw _convertException(e);
    }
  }

  /// Configura la presentación web en iOS; en Android devuelve true sin cambios.
  Future<bool> initWebViewParams(
    MSALWebviewParameters webviewParameters,
  ) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return true;
      }
      final result = await _channel.invokeMethod<bool>(
        'initWebViewParams',
        webviewParameters.toMap(),
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw _convertException(e);
    }
  }

  /// Enumera cuentas; los filtros opcionales se aplican en iOS.
  Future<List<MSALAccount>?> loadAccounts([
    MSALAccountEnumerationParameters? enumerationParameters,
  ]) async {
    try {
      final result = await _channel.invokeMethod<List>(
        'loadAccounts',
        enumerationParameters?.toMap(),
      );

      return result
          ?.map((e) => MSALAccount.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } on PlatformException catch (e) {
      throw _convertException(e);
    }
  }

  /// Solicita autenticación interactiva para los permisos indicados.
  Future<MSALResult?> acquireToken(
    MSALInteractiveTokenParameters interactiveTokenParameters,
  ) async {
    interactiveTokenParameters.validate();
    try {
      final result = await _channel.invokeMethod(
        'acquireToken',
        interactiveTokenParameters.toMap(),
      );
      return result != null
          ? MSALResult.fromMap(Map<String, dynamic>.from(result))
          : null;
    } on PlatformException catch (e) {
      throw _convertException(e);
    }
  }

  /// Obtiene un token mediante la caché y renovación nativas para la cuenta indicada.
  Future<MSALResult?> acquireTokenSilent(
    MSALSilentTokenParameters silentTokenParameters,
    MSALAccount? account,
  ) async {
    silentTokenParameters.validate();
    try {
      final result = await _channel.invokeMethod('acquireTokenSilent', {
        'accountId': account?.identifier,
        'tokenParameters': silentTokenParameters.toMap(),
      });
      return result != null
          ? MSALResult.fromMap(Map<String, dynamic>.from(result))
          : null;
    } on PlatformException catch (e) {
      throw _convertException(e);
    }
  }

  /// Cierra la sesión de una cuenta; el resultado indica si MSAL completó la operación.
  Future<bool> logout(
    MSALSignoutParameters signoutParameters,
    MSALAccount account,
  ) async {
    try {
      final result = await _channel.invokeMethod<bool>('logout', {
        'accountId': account.identifier,
        'signoutParameters': signoutParameters.toMap(),
      });
      return result ?? false;
    } on PlatformException catch (e) {
      throw _convertException(e);
    }
  }

  MsalException _convertException(PlatformException e) {
    switch (e.code) {
      case "CANCELLED":
        return MsalUserCancelledException();
      case "NO_SCOPE":
        return MsalInvalidScopeException();
      case "NO_ACCOUNT":
        return MsalNoAccountException();
      case "NO_CLIENTID":
        return MsalInvalidConfigurationException(
          _platformExceptionMessage(e, "Client Id not set"),
        );
      case "INVALID_AUTHORITY":
        return MsalInvalidConfigurationException(
          _platformExceptionMessage(e, "Invalid authority set."),
        );
      case "INVALID_GRANT":
        return MsalInvalidGrantException();
      case "INVALID_REQUEST":
        return MsalInvalidRequestException("Invalid request");
      case "CONFIG_ERROR":
        return MsalInvalidConfigurationException(
          _platformExceptionMessage(e, "Invalid configuration"),
        );
      case "NO_CLIENT":
        return MsalUninitializedException();
      case "CHANGED_CLIENTID":
        return MsalChangedClientIdException();
      case "INIT_ERROR":
        return MsalInitializationException();
      case "SCOPE_ERROR":
        return MsalScopeErrorException();
      case "AUTH_ERROR":
      case "UNKNOWN":
      default:
        return MsalException("Authentication error");
    }
  }

  String _platformExceptionMessage(PlatformException e, String fallback) {
    final message = e.message?.trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }

    final details = e.details is Map
        ? (e.details as Map)["code"]?.toString()
        : null;
    if (details != null && details.isNotEmpty) {
      return details;
    }

    return fallback;
  }
}
