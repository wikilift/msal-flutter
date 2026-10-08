import 'msal_exceptions.dart';

/// No hay una cuenta disponible para la operación.
class MsalNoAccountException extends MsalException {
  MsalNoAccountException()
    : super("Cannot login silently. No account available");
}
