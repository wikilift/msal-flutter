import '../../flutter_msal_plus.dart';

/// MSAL rechazó la concesión de autenticación.
class MsalInvalidGrantException extends MsalException {
  MsalInvalidGrantException() : super("Invalid grant.");
}
