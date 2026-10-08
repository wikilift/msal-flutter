import 'msal_exception.dart';

/// El cliente nativo todavía no está inicializado.
class MsalUninitializedException extends MsalException {
  MsalUninitializedException()
    : super(
        "Client not initialized. Client must be initialized before attempting to use",
      );
}
