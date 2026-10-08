import 'package:flutter_msal_plus/src/utility/extensions/map_cleanup_extension.dart';

/// Selección opcional de slice y centro de datos para MSAL.
class MSALSliceConfig {
  /// Nombre del slice de servicio solicitado.
  String? slice;

  /// Centro de datos solicitado.
  String? dc;
  MSALSliceConfig({this.slice, this.dc});

  /// Serializa los valores presentes para el canal nativo de MSAL.
  Map<String, dynamic> toMap() {
    return {'slice': slice, 'dc': dc}.cleanup();
  }
}
