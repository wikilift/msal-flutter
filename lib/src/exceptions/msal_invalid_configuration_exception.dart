import 'msal_exception.dart';

/// La configuración impide inicializar el cliente nativo.
class MsalInvalidConfigurationException extends MsalException {
  MsalInvalidConfigurationException(super.errorMessage);

  @override
  String toString() => errorMessage;
}
