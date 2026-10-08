/// Perfil del directorio asociado a una cuenta de MSAL.
class MSALTenantProfile {
  /// Atributos del perfil; contienen datos personales.
  Map<String, dynamic>? claims;

  /// Identificador del directorio del perfil.
  String? tenantId;

  /// Entorno de identidad asociado a la cuenta o configuración.
  String? environment;

  /// Identificador estable de la cuenta proporcionado por MSAL.
  String? identifier;

  /// Indica si el perfil corresponde al directorio principal de la cuenta.
  bool? isHomeTenantProfile;

  MSALTenantProfile({
    this.tenantId,
    this.claims,
    this.environment,
    this.identifier,
    this.isHomeTenantProfile,
  });

  MSALTenantProfile.fromMap(Map<String, dynamic> map)
    : this(
        tenantId: map['tenantId'] as String?,
        claims: map['claims'] == null
            ? null
            : Map<String, dynamic>.from(map['claims'] as Map),
        environment: map['environment'] as String?,
        identifier: map['identifier'] as String?,
        isHomeTenantProfile: map['isHomeTenantProfile'] as bool?,
      );
}
