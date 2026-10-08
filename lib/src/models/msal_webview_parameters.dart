import 'package:flutter_msal_plus/src/models/ios_modal_presentation_style.dart';
import 'package:flutter_msal_plus/src/models/msal_webview_type.dart';
import 'package:flutter_msal_plus/src/utility/extensions/map_cleanup_extension.dart';

/// Opciones de presentación web para la autenticación en iOS.
class MSALWebviewParameters {
  /// Tipo de presentación web utilizado por MSAL en iOS.
  final MSALWebviewType? webviewType;

  /// Solicita una sesión privada del navegador en iOS.
  final bool prefersEphemeralWebBrowserSession;

  /// Estilo modal de presentación de la interfaz web en iOS.
  final IOSModalPresentationStyle? presentationStyle;
  MSALWebviewParameters({
    this.prefersEphemeralWebBrowserSession = false,
    this.webviewType,
    this.presentationStyle,
  });

  /// Serializa los valores presentes para el canal nativo de MSAL.
  Map<String, dynamic> toMap() {
    return {
      'webviewType': webviewType?.name,
      'prefersEphemeralWebBrowserSession': prefersEphemeralWebBrowserSession,
      'presentationStyle': presentationStyle?.name,
    }.cleanup();
  }
}
