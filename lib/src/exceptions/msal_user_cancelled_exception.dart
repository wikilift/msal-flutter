import 'msal_exceptions.dart';

/// El usuario canceló la autenticación.
class MsalUserCancelledException extends MsalException {
  MsalUserCancelledException() : super("User cancelled login request");
}
