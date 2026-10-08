import Flutter
import Foundation

public class FlutterMsalPlusPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        MsalMethodHandler.register(with: registrar)
    }
}
