/// Configuración histórica de tiempos de espera HTTP en milisegundos.
class MsalHttp {
  MsalHttp({this.connectTimeout = 10000, this.readTimeout = 30000});

  /// Tiempo máximo de conexión HTTP en milisegundos.
  int connectTimeout;

  /// Tiempo máximo de lectura HTTP en milisegundos.
  int readTimeout;

  /// Serializa los valores presentes para el canal nativo de MSAL.
  Map<String, dynamic> toMap() => {
    "connect_timeout": connectTimeout,
    "read_timeout": readTimeout,
  };
}
