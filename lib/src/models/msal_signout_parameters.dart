import 'package:flutter_msal_plus/src/utility/extensions/map_cleanup_extension.dart';

/// Opciones nativas de cierre de sesión; las opciones de navegador y borrado son de iOS.
class MSALSignoutParameters {
  /// Solicita cierre de sesión del navegador en iOS.
  final bool? signoutFromBrowser;

  /// Solicita borrar los datos de la cuenta mediante MSAL en iOS.
  final bool? wipeAccount;

  /// Solicita borrar la caché para todas las cuentas en iOS; puede afectar al SSO compartido.
  final bool? wipeCacheForAllAccounts;
  const MSALSignoutParameters({
    this.signoutFromBrowser,
    this.wipeAccount,
    this.wipeCacheForAllAccounts,
  });

  /// Serializa los valores presentes para el canal nativo de MSAL.
  Map<String, dynamic> toMap() {
    return {
      'signoutFromBrowser': signoutFromBrowser,
      'wipeAccount': wipeAccount,
      'wipeCacheForAllAccounts': wipeCacheForAllAccounts,
    }.cleanup();
  }
}
