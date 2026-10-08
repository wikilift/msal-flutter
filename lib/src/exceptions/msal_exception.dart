/// Error base de autenticación con un mensaje apto para su manejo por la aplicación.
class MsalException implements Exception {
  /// Mensaje controlado del error de autenticación.
  String errorMessage;
  MsalException(this.errorMessage);
  @override
  String toString() => errorMessage;
}
