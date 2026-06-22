import DeviceFingerPrint
import Foundation
import UIKit

/// Collects device fingerprint data via the proprietary DeviceFingerPrint
/// framework for fraud detection signals.
///
/// Returns a [String: Any] dictionary that is forwarded verbatim to the
/// tokenization endpoint under the `device` key. Falls back to a minimal
/// UIDevice payload if the framework returns nil.
enum FingerprintHandler {
    static func collect() -> [String: Any] {
        if let data = Device.getInfoAsJsonData(),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return json
        }
        return fallback()
    }

    private static func fallback() -> [String: Any] {
        let device = UIDevice.current
        return [
            "platform": "ios",
            "model": device.model,
            "system_name": device.systemName,
            "system_version": device.systemVersion,
            "identifier_for_vendor": device.identifierForVendor?.uuidString ?? "",
            "bundle_id": Bundle.main.bundleIdentifier ?? "",
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
        ]
    }
}
