import Flutter
import Foundation

public class MercadopagoSdkPlugin: NSObject, FlutterPlugin {
  private static let channelName = "mercadopago/fingerprint"

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )
    let instance = MercadopagoSdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.publish(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getDeviceData":
      // iOS intentionally provides no fingerprint signals. Keep the
      // channel contract stable so Dart can continue tokenization with
      // DeviceData.empty without collecting fallback identifiers.
      result([String: Any]())
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
