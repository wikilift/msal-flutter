import 'msal_exception.dart';

/// La solicitud contiene parámetros no válidos.
class MsalInvalidRequestException extends MsalException {
  MsalInvalidRequestException(super.errorMessage);
}
