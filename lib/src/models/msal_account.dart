import 'package:flutter_msal_plus/src/utility/extensions/map_cleanup_extension.dart';

/// Cuenta identificada por MSAL y sus datos opcionales.
class MSALAccount {
  /// Nombre de usuario opcional; contiene datos personales.
  String? username;

  /// Identificador estable de la cuenta proporcionado por MSAL.
  String identifier;

  /// Entorno de identidad asociado a la cuenta o configuración.
  String? environment;

  /// Atributos de cuenta devueltos por MSAL; contienen datos personales.
  Map<String, dynamic>? accountClaims;

  /// Indica si la cuenta participa en el inicio de sesión único nativo.
  bool isSSOAccount;

  MSALAccount({
    required this.identifier,
    this.isSSOAccount = false,
    this.username,
    this.environment,
    this.accountClaims,
  });

  /// Serializa los valores presentes para el canal nativo de MSAL.
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'identifier': identifier,
      'environment': environment,
      'accountClaims': accountClaims,
      'isSSOAccount': isSSOAccount,
    }.cleanup();
  }

  MSALAccount.fromMap(Map<String, dynamic> map)
    : this(
        username: map['username'] as String?,
        identifier: map['identifier'] as String? ?? '',
        environment: map['environment'] as String?,
        accountClaims: map['accountClaims'] == null
            ? null
            : Map<String, dynamic>.from(map['accountClaims'] as Map),
        isSSOAccount: map['isSSOAccount'] as bool? ?? false,
      );
}
