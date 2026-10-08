import 'msal_exception.dart';

/// La inicialización nativa no se completó correctamente.
class MsalInitializationException extends MsalException {
  MsalInitializationException()
    : super(
        "Error initializing client. Please ensure correctly configuration supplied",
      );
}
