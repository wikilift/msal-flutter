/// Estilo de presentación modal utilizado por la vista web de iOS.
enum IOSModalPresentationStyle {
  fullScreen,
  pageSheet,
  formSheet,
  currentContext,
  custom,
  overFullScreen,
  overCurrentContext,
  popover,
  none,
  automatic;

  static IOSModalPresentationStyle fromString(String value) {
    return IOSModalPresentationStyle.values.firstWhere(
      (element) => element.name == value,
      orElse: () => IOSModalPresentationStyle.fullScreen,
    );
  }
}
