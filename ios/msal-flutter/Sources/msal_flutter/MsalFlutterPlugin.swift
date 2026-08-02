import Flutter
import Foundation

public class MsalFlutterPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        SwiftMsalFlutterPluginV2.register(with: registrar)
    }
}
