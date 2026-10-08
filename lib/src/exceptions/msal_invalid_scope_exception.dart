import 'msal_exception.dart';

/// Los permisos solicitados están vacíos o no son válidos.
class MsalInvalidScopeException extends MsalException {
  MsalInvalidScopeException() : super("Invalid or no scope");
}
