/// Motor de presentación web solicitado a MSAL en iOS.
enum MSALWebviewType {
  safariViewController,
  authenticationSession,
  wkWebView,
  defaultView;

  static MSALWebviewType fromString(String value) {
    return MSALWebviewType.values.firstWhere(
      (element) => element.name == value,
      orElse: () => MSALWebviewType.defaultView,
    );
  }
}
