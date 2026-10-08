import 'package:flutter/foundation.dart';
import '../exceptions/msal_invalid_configuration_exception.dart';

import 'package:flutter_msal_plus/src/models/authority.dart';
import 'package:flutter_msal_plus/src/models/msal_android_config.dart';
import 'package:flutter_msal_plus/src/utility/extensions/map_cleanup_extension.dart';

import 'msal_cache_config.dart';
import 'msal_slice_config.dart';

/// Configuración del cliente público; MSAL administra la caché nativa.
class MSALPublicClientApplicationConfig {
  /// Identificador de la aplicación pública registrada en Entra.
  String clientId;

  /// URI de retorno seleccionada para la plataforma actual.
  String? redirectUri;

  /// Autoridad HTTPS opcional para iOS; sin ella, MSAL utiliza la autoridad genérica.
  Uri? authority;

  /// Desactiva la validación nativa de retorno; manténgalo en false salvo necesidad explícita.
  bool bypassRedirectURIValidation;

  /// Capacidades declaradas por la aplicación al servicio de identidad.
  List<String>? clientApplicationCapabilities;

  /// Permite a MSAL utilizar tokens de vida extendida cuando corresponda.
  bool extendedLifetimeEnabled;

  /// Autoridades explícitamente confiables para la configuración nativa.
  List<Uri>? knownAuthorities;

  /// Opciones de la caché nativa; no crea un almacén adicional.
  MSALCacheConfig? cacheConfig;

  /// Activa la configuración multicloud de MSAL.
  bool multipleCloudsSupported;

  /// Selección opcional de slice y centro de datos.
  MSALSliceConfig? sliceConfig;

  /// Margen de vencimiento del token en segundos; debe ser finito y no negativo.
  double? tokenExpirationBuffer;

  /// Autoridades registradas para la configuración de Android.
  List<Authority>? authorities;

  /// Opciones específicas del cliente nativo de Android.
  MSALAndroidConfig? androidConfig;

  MSALPublicClientApplicationConfig({
    required this.clientId,
    String? androidRedirectUri,
    String? iosRedirectUri,
    this.authority,
    this.bypassRedirectURIValidation = false,
    this.clientApplicationCapabilities,
    this.extendedLifetimeEnabled = false,
    this.knownAuthorities,
    this.cacheConfig,
    this.multipleCloudsSupported = false,
    this.sliceConfig,
    this.tokenExpirationBuffer,
    this.androidConfig,
  }) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      /// URI de retorno seleccionada para la plataforma actual.
      redirectUri = androidRedirectUri;
    } else {
      /// URI de retorno seleccionada para la plataforma actual.
      redirectUri = iosRedirectUri;
    }
  }

  Map<String, dynamic> _toMapAndroid() {
    return {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'client_capabilities': clientApplicationCapabilities,
      ...androidConfig?.toMap() ?? {},
    }.cleanup();
  }

  Map<String, dynamic> _toMapIos() {
    return {
      'clientId': clientId,
      'redirectUri': redirectUri,
      'authority': authority?.toString(),
      'bypassRedirectURIValidation': bypassRedirectURIValidation,
      'clientApplicationCapabilities': clientApplicationCapabilities,
      'extendedLifetimeEnabled': extendedLifetimeEnabled,
      'knownAuthorities': knownAuthorities?.map((x) => x.toString()).toList(),
      'cacheConfig': cacheConfig?.toMap(),
      'multipleCloudsSupported': multipleCloudsSupported,
      'sliceConfig': sliceConfig?.toMap(),
      'tokenExpirationBuffer': tokenExpirationBuffer,
    }.cleanup();
  }

  void validate() {
    if (clientId.trim().isEmpty) {
      throw MsalInvalidConfigurationException(
        'Call must include a non-empty clientId',
      );
    }
    for (final uri in [authority, ...?knownAuthorities]) {
      if (uri != null && (uri.scheme != 'https' || uri.host.isEmpty)) {
        throw MsalInvalidConfigurationException('Invalid authority URL: $uri');
      }
    }
    if (redirectUri != null &&
        (!Uri.parse(redirectUri!).hasScheme || redirectUri!.trim().isEmpty)) {
      throw MsalInvalidConfigurationException(
        'redirectUri must have a URL scheme',
      );
    }
    if (tokenExpirationBuffer != null &&
        (!tokenExpirationBuffer!.isFinite || tokenExpirationBuffer! < 0)) {
      throw MsalInvalidConfigurationException(
        'tokenExpirationBuffer must be finite and non-negative',
      );
    }
  }

  /// Serializa los valores presentes para el canal nativo de MSAL.
  Map<String, dynamic> toMap() {
    validate();
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _toMapAndroid();
    } else {
      return _toMapIos();
    }
  }
}
