/// Tiempos de espera HTTP de Android expresados en milisegundos.
class HttpConfiguration {
  /// Tiempo máximo de lectura HTTP en milisegundos.
  final int readTimeout;

  /// Tiempo máximo de conexión HTTP en milisegundos.
  final int connectTimeout;

  const HttpConfiguration({
    this.readTimeout = 30000,
    this.connectTimeout = 10000,
  });

  /// Serializa los valores presentes para el canal nativo de MSAL.
  Map<String, dynamic> toMap() {
    return {'read_timeout': readTimeout, 'connect_timeout': connectTimeout};
  }
}
