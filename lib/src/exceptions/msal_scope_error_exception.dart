import 'msal_exception.dart';

/// El servicio no concedió los permisos solicitados.
class MsalScopeErrorException extends MsalException {
  MsalScopeErrorException() : super("Scope error or scope declined");
}
