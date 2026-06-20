import Foundation
import UIKit

/// Collects device fingerprint data for fraud detection.
///
/// TODO: integrate the proprietary `DeviceFingerPrint.xcframework` from the
/// MercadoPago iOS team when the binary is available. The handler should
/// then dynamically load its `DeviceFingerPrint` class and forward the
/// collected payload. Until then, a minimal fallback payload is emitted so
/// tokenization succeeds without the enriched anti-fraud signals.
enum FingerprintHandler {
    static func collect() -> [String: Any] {
        if let native = tryNativeFingerprint() {
            return native
        }
        return fallback()
    }

    private static func tryNativeFingerprint() -> [String: Any]? {
        // Reflective lookup. The class is provided by an external binary
        // that is not part of this pod; the call is a no-op when missing.
        guard let cls = NSClassFromString("DeviceFingerPrint") as? NSObject.Type else {
            return nil
        }
        let instance = cls.init()
        let selector = NSSelectorFromString("deviceInformation")
        guard instance.responds(to: selector) else {
            return nil
        }
        let unmanaged = instance.perform(selector)
        guard let dict = unmanaged?.takeUnretainedValue() as? [String: Any] else {
            return nil
        }
        return dict
    }

    private static func fallback() -> [String: Any] {
        let device = UIDevice.current
        return [
            "platform": "ios",
            "model": device.model,
            "system_name": device.systemName,
            "system_version": device.systemVersion,
            "name": device.name,
            "identifier_for_vendor": device.identifierForVendor?.uuidString ?? "",
            "bundle_id": Bundle.main.bundleIdentifier ?? "",
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
        ]
    }
}
