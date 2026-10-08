import '../exceptions/msal_invalid_scope_exception.dart';
import '../exceptions/msal_invalid_request_exception.dart';
import 'package:flutter_msal_plus/src/models/authority.dart';

/// Parámetros comunes de una solicitud de tokens.
abstract class MSALTokenParameters {
  /// Permisos solicitados o concedidos por MSAL.
  List<String> scopes;

  /// Parámetros adicionales de consulta; sus valores deben ser cadenas.
  Map<String, dynamic>? extraQueryParameters;

  /// Identificador UUID utilizado para correlacionar la solicitud.
  String? correlationId;

  /// Autoridad alternativa para la solicitud silenciosa.
  Authority? overrideAuthority;

  /// Rechaza permisos, autoridades y parámetros que no sean válidos para MSAL.
  void validate() {
    if (scopes.isEmpty || scopes.any((scope) => scope.trim().isEmpty)) {
      throw MsalInvalidScopeException();
    }
    if (extraQueryParameters?.values.any((value) => value is! String) ??
        false) {
      throw MsalInvalidRequestException(
        'extraQueryParameters values must be strings',
      );
    }
    final authority = overrideAuthority?.authorityUrl;
    if (authority != null &&
        (authority.scheme != 'https' || authority.host.isEmpty)) {
      throw MsalInvalidRequestException(
        'Authority must be an absolute HTTPS URL',
      );
    }
    if (correlationId != null &&
        !RegExp(
          r'^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$',
        ).hasMatch(correlationId!)) {
      throw MsalInvalidRequestException('correlationId must be a UUID');
    }
  }

  MSALTokenParameters({
    required this.scopes,
    this.extraQueryParameters,
    this.correlationId,
    this.overrideAuthority,
  });
}
