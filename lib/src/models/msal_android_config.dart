import 'package:flutter_msal_plus/src/models/android_account_mode.dart';
import 'package:flutter_msal_plus/src/models/android_logger_config.dart';
import 'package:flutter_msal_plus/src/models/authorization_agent.dart';
import 'package:flutter_msal_plus/src/models/http_configuration.dart';
import 'package:flutter_msal_plus/src/models/msal_environment.dart';
import 'package:flutter_msal_plus/src/models/safe_browser.dart';

import 'authority.dart';

/// Configuración serializable para el cliente MSAL de Android.
class MSALAndroidConfig {
  /// Autoridades registradas para la configuración de Android.
  List<Authority> authorities;

  /// Configura el manejo de tareas de Android sin afinidad.
  bool handleNullTaskAffinity;

  /// Agente de autorización solicitado para Android.
  AuthorizationAgent authorizationUserAgent;

  /// Versión mínima del protocolo del broker configurada en Android.
  String minimumRequiredBrowsersVersion;

  /// Activa la configuración multicloud de MSAL.
  bool multipleCloudsSupported;

  /// Indica si se registró una URI de retorno compatible con el broker.
  bool brokerRedirectUriRegistered;

  /// Permite controles de zoom en la vista web de Android.
  bool webViewZoomControlsEnabled;

  /// Permite zoom en la vista web de Android.
  bool webViewZoomEnabled;

  /// Solicita presentar la autorización en la tarea actual de Android.
  bool authorizationInCurrentTask;

  /// Entorno de identidad asociado a la cuenta o configuración.
  MsalEnvironment environment;

  /// Activa comprobaciones de optimización de energía antes de solicitudes de red.
  bool powerOptCheckEnabled;

  /// Configuración de tiempos de espera HTTP de Android.
  HttpConfiguration http;

  /// Configuración de registros nativos de Android.
  AndroidLoggerConfiguration logger;

  /// Modo de cuentas; el puente actual utiliza MULTIPLE.
  AndroidAccountMode accountMode;

  /// Navegadores y firmas permitidos para autorización en Android.
  List<SafeBrowser> browserSafeList;
  MSALAndroidConfig({
    required this.authorities,
    this.handleNullTaskAffinity = false,
    this.authorizationUserAgent = AuthorizationAgent.DEFAULT,
    this.minimumRequiredBrowsersVersion = "3.0",
    this.multipleCloudsSupported = false,
    this.brokerRedirectUriRegistered = true,
    this.webViewZoomControlsEnabled = true,
    this.webViewZoomEnabled = true,
    this.authorizationInCurrentTask = false,
    this.environment = MsalEnvironment.Production,
    this.powerOptCheckEnabled = true,
    this.http = const HttpConfiguration(),
    this.logger = const AndroidLoggerConfiguration(),
    this.accountMode = AndroidAccountMode.MULTIPLE,
    this.browserSafeList = SafeBrowser.defaultSafeBrowsers,
  });

  /// Serializa los valores presentes para el canal nativo de MSAL.
  Map<String, dynamic> toMap() {
    return {
      "authorities": authorities.map((x) => x.toMap()).toList(),
      "handle_null_taskaffinity": handleNullTaskAffinity,
      "authorization_user_agent": authorizationUserAgent
          .toString()
          .split('.')
          .last,
      "minimum_required_broker_protocol_version":
          minimumRequiredBrowsersVersion,
      "multiple_clouds_supported": multipleCloudsSupported,
      "broker_redirect_uri_registered": brokerRedirectUriRegistered,
      "web_view_zoom_controls_enabled": webViewZoomControlsEnabled,
      "web_view_zoom_enabled": webViewZoomEnabled,
      "authorization_in_current_task": authorizationInCurrentTask,
      "environment": environment.toString().split('.').last,
      "power_opt_check_for_network_req_enabled": powerOptCheckEnabled,
      "http": http.toMap(),
      "logger": logger.toMap(),
      "account_mode": accountMode.toString().split('.').last,
      "browser_safelist": browserSafeList.map((x) => x.toMap()).toList(),
    };
  }
}
