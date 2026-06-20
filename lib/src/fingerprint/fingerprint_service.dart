import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/models/device_data.dart';

/// Bridge to the native device-fingerprinting SDKs through a Platform Channel.
///
/// The native side may not be available in every environment (e.g. iOS
/// simulator without the proprietary xcframework, unit tests). When the
/// channel is missing or throws, the service returns [DeviceData.empty] and
/// logs a single warning. Tokenization continues without device data — the
/// API accepts requests without it, just without the additional fraud
/// signals.
class FingerprintService {
  FingerprintService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('mercadopago/fingerprint');

  final MethodChannel _channel;
  bool _warned = false;

  Future<DeviceData> collect() async {
    try {
      final result =
          await _channel.invokeMapMethod<String, dynamic>('getDeviceData');
      if (result == null || result.isEmpty) {
        _warnOnce('Fingerprint channel returned empty data.');
        return const DeviceData.empty();
      }
      return DeviceData(Map<String, dynamic>.from(result));
    } on MissingPluginException {
      _warnOnce(
        'Native fingerprint plugin missing — continuing without device data.',
      );
      return const DeviceData.empty();
    } on PlatformException catch (e) {
      _warnOnce('Fingerprint channel error: ${e.message}');
      return const DeviceData.empty();
    } catch (e) {
      _warnOnce('Unexpected fingerprint failure: $e');
      return const DeviceData.empty();
    }
  }

  void _warnOnce(String message) {
    if (_warned) return;
    _warned = true;
    if (kDebugMode) {
      // ignore: avoid_print
      debugPrint('[MercadoPagoSDK] $message');
    }
  }
}
