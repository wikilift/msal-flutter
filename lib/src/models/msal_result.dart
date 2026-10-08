import 'package:flutter_msal_plus/src/models/msal_account.dart';
import 'msal_tenant_profile.dart';

/// Resultado de autenticación; sus tokens y cabeceras son credenciales.
class MSALResult {
  /// Token de acceso; no debe registrarse ni mostrarse en interfaces de diagnóstico.
  String accessToken;

  /// Cuenta asociada al resultado de autenticación.
  MSALAccount account;

  /// Esquema de autenticación devuelto por MSAL.
  String authenticationScheme;

  /// Autoridad HTTPS utilizada para autenticar la solicitud.
  Uri authority;

  /// Cabecera de autorización; contiene material de autenticación sensible.
  String authorizationHeader;

  /// Identificador UUID utilizado para correlacionar la solicitud.
  String correlationId;

  /// Instante de vencimiento devuelto por MSAL; puede estar ausente.
  DateTime? expiresOn;

  /// Indica si el resultado utiliza un token de vida extendida.
  bool? extendedLifeTimeToken;

  /// Token de identidad opcional; contiene datos personales y credenciales.
  String? idToken;

  /// Permisos solicitados o concedidos por MSAL.
  List<String> scopes;

  /// Perfil opcional del directorio asociado al resultado.
  MSALTenantProfile? tenantProfile;

  MSALResult({
    required this.accessToken,
    required this.account,
    required this.authenticationScheme,
    required this.authority,
    required this.authorizationHeader,
    required this.correlationId,
    required this.scopes,
    this.expiresOn,
    this.extendedLifeTimeToken,
    this.idToken,
    this.tenantProfile,
  });

  MSALResult.fromMap(Map<String, dynamic> map)
    : this(
        accessToken: map['accessToken'] as String? ?? '',
        account: MSALAccount.fromMap(
          Map<String, dynamic>.from(
            (map['account'] as Map?) ?? const <String, dynamic>{},
          ),
        ),
        authenticationScheme: map['authenticationScheme'] as String? ?? '',
        authority: Uri.tryParse(map['authority'] as String? ?? '') ?? Uri(),
        authorizationHeader: map['authorizationHeader'] as String? ?? '',
        correlationId: map['correlationId'] as String? ?? '',
        expiresOn: _parseExpiresOn(map['expiresOn']),
        extendedLifeTimeToken: map['extendedLifeTimeToken'] as bool?,
        idToken: map['idToken'] as String?,
        scopes: List<String>.from(map['scopes'] ?? const []),
        tenantProfile: map['tenantProfile'] == null
            ? null
            : MSALTenantProfile.fromMap(
                Map<String, dynamic>.from(map['tenantProfile'] as Map),
              ),
      );

  static DateTime? _parseExpiresOn(dynamic value) {
    if (value == null) return null;

    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
