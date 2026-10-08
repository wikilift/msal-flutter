import 'package:flutter_msal_plus/src/models/msal_token_parameters.dart';
import 'package:flutter_msal_plus/src/utility/extensions/map_cleanup_extension.dart';

/// Parámetros para obtener o renovar tokens sin interfaz de usuario.
class MSALSilentTokenParameters extends MSALTokenParameters {
  /// Solicita a MSAL renovar el token en lugar de usar uno almacenado.
  bool? forceRefresh;

  MSALSilentTokenParameters({
    required super.scopes,
    super.correlationId,
    super.extraQueryParameters,
    super.overrideAuthority,
    this.forceRefresh,
  });

  /// Serializa los valores presentes para el canal nativo de MSAL.
  Map<String, dynamic> toMap() {
    return {
      'scopes': scopes,
      'correlationId': correlationId,
      'extraQueryParameters': extraQueryParameters,
      'forceRefresh': forceRefresh,
      'authority': overrideAuthority?.authorityUrl.toString(),
    }.cleanup();
  }
}
