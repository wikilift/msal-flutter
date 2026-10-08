import 'package:flutter_msal_plus/src/utility/extensions/map_cleanup_extension.dart';

/// Opciones de la caché de llavero administrada por MSAL en iOS.
class MSALCacheConfig {
  /// Grupo de llavero; requiere una autorización correspondiente en la aplicación.
  String? keychainSharingGroup;
  MSALCacheConfig({this.keychainSharingGroup});

  /// Serializa los valores presentes para el canal nativo de MSAL.
  Map<String, dynamic> toMap() {
    return {'keychainSharingGroup': keychainSharingGroup}.cleanup();
  }
}
