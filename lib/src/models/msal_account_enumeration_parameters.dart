import '../utility/extensions/map_cleanup_extension.dart';

/// Filtros de enumeración de cuentas aplicados por MSAL en iOS.
class MSALAccountEnumerationParameters {
  String? _identifier;
  String? _username;
  String? _tenantProfileIdentifier;

  MSALAccountEnumerationParameters.fromIdentifier(String identifier) {
    _identifier = identifier;
  }
  MSALAccountEnumerationParameters.fromUsername({
    required String username,
    String? identifier,
  }) {
    _identifier = identifier;
    _username = username;
  }
  MSALAccountEnumerationParameters.fromTenantIdentifier(
    String tenantIdentifier,
  ) {
    _tenantProfileIdentifier = tenantIdentifier;
  }

  /// Serializa los valores presentes para el canal nativo de MSAL.
  Map<String, dynamic> toMap() {
    return {
      'identifier': _identifier,
      'username': _username,
      'tenantProfileIdentifier': _tenantProfileIdentifier,
    }.cleanup();
  }
}
