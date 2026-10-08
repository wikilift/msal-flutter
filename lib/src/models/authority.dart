/// Autoridad y tipo de directorio para la configuración de Android.
class Authority {
  Authority({
    this.type = 'B2C',
    this.authorityDefault = false,
    required this.authorityUrl,
  });

  /// Tipo de autoridad para MSAL en Android.
  String type;

  /// Marca esta autoridad como predeterminada en Android.
  bool authorityDefault;

  /// URL de la autoridad registrada.
  Uri authorityUrl;

  /// Serializa los valores presentes para el canal nativo de MSAL.
  Map<String, dynamic> toMap() => {
    "type": type,
    "default": authorityDefault,
    "authority_url": authorityUrl.toString(),
  };
}
