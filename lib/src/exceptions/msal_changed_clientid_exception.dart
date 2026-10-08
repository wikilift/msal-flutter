import 'msal_exception.dart';

/// Se intentó cambiar el identificador de un cliente ya inicializado.
class MsalChangedClientIdException extends MsalException {
  MsalChangedClientIdException()
    : super(
        "Cannot create a client with a new client ID. Only 1 client id supported",
      );
}
