import Flutter
import UIKit

public class MercadopagoSdkPlugin: NSObject, FlutterPlugin {
    private static let channelName = "mercadopago/fingerprint"

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        let instance = MercadopagoSdkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getDeviceData":
            result(FingerprintHandler.collect())
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
