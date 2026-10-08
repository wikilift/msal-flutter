import 'android_log_level.dart';

/// Opciones de registro de Android; los datos personales están deshabilitados por defecto.
class AndroidLoggerConfiguration {
  /// Permite registros de datos personales; false por defecto.
  final bool piiEnabled;

  /// Nivel de detalle solicitado para los registros nativos.
  final AndroidLogLevel logLevel;

  /// Permite la salida de registros de Android a Logcat.
  final bool logcatEnabled;

  const AndroidLoggerConfiguration({
    this.piiEnabled = false,
    this.logLevel = AndroidLogLevel.WARNING,
    this.logcatEnabled = true,
  });

  /// Serializa los valores presentes para el canal nativo de MSAL.
  Map<String, dynamic> toMap() {
    return {
      'pii_enabled': piiEnabled,
      'log_level': logLevel.name,
      'logcat_enabled': logcatEnabled,
    };
  }
}
