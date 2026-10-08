import '../exceptions/msal_invalid_request_exception.dart';
import 'package:flutter_msal_plus/src/models/msal_token_parameters.dart';
import 'package:flutter_msal_plus/src/utility/extensions/map_cleanup_extension.dart';

import 'msal_prompt_type.dart';

/// Parámetros para solicitar consentimiento o iniciar sesión de forma interactiva.
class MSALInteractiveTokenParameters extends MSALTokenParameters {
  /// Comportamiento solicitado al diálogo interactivo.
  MSALPromptType? promptType;

  /// Autoridad HTTPS utilizada para autenticar la solicitud.
  Uri? authority;

  /// Permisos adicionales para los que se solicita consentimiento.
  List<String>? extraScopesToConsent;

  /// Nombre de usuario sugerido para el diálogo interactivo.
  String? loginHint;
  MSALInteractiveTokenParameters({
    required super.scopes,
    super.extraQueryParameters,
    super.correlationId,
    this.authority,
    this.extraScopesToConsent,
    this.loginHint,
    this.promptType,
  });

  /// Valida también la autoridad específica de la solicitud interactiva.
  @override
  void validate() {
    super.validate();
    if (authority != null &&
        (authority!.scheme != 'https' || authority!.host.isEmpty)) {
      throw MsalInvalidRequestException(
        'Authority must be an absolute HTTPS URL',
      );
    }
  }

  /// Serializa los valores presentes para el canal nativo de MSAL.
  Map<String, dynamic> toMap() {
    return {
      'scopes': scopes,
      'correlationId': correlationId,
      'extraQueryParameters': extraQueryParameters,
      'promptType': promptType?.name,
      'authority': authority?.toString(),
      'extraScopesToConsent': extraScopesToConsent,
      'loginHint': loginHint,
    }.cleanup();
  }

  MSALInteractiveTokenParameters copyWith({
    List<String>? scopes,
    Map<String, dynamic>? extraQueryParameters,
    String? correlationId,
    Uri? authority,
    List<String>? extraScopesToConsent,
    String? loginHint,
    MSALPromptType? promptType,
  }) {
    return MSALInteractiveTokenParameters(
      scopes: scopes ?? this.scopes,
      extraQueryParameters: extraQueryParameters ?? this.extraQueryParameters,
      correlationId: correlationId ?? this.correlationId,
      promptType: promptType ?? this.promptType,
      authority: authority ?? this.authority,
      extraScopesToConsent: extraScopesToConsent ?? this.extraScopesToConsent,
      loginHint: loginHint ?? this.loginHint,
    );
  }
}
