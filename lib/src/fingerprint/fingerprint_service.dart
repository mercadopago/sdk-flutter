import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/models/device_data.dart';

/// Bridge to the native device-fingerprinting SDKs through a Platform Channel.
///
/// The native side may return no data (intentionally on iOS) or be unavailable
/// in an environment such as unit tests. When the channel is empty, missing,
/// or throws, the service returns [DeviceData.empty] and logs a single warning.
/// Tokenization continues without the additional fraud signals.
class FingerprintService {
  FingerprintService({
    MethodChannel? channel,
    Duration timeout = defaultTimeout,
  }) : _channel = channel ?? const MethodChannel('mercadopago/fingerprint'),
       _collectionTimeout = timeout;

  /// Native fingerprinting is best-effort and must not hold up a payment.
  static const Duration defaultTimeout = Duration(seconds: 2);

  final MethodChannel _channel;
  final Duration _collectionTimeout;
  bool _warned = false;

  Future<DeviceData> collect() async {
    try {
      final result = await _channel
          .invokeMapMethod<String, dynamic>('getDeviceData')
          .timeout(_collectionTimeout);
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
    } on TimeoutException {
      _warnOnce(
        'Native fingerprint collection timed out after '
        '${_collectionTimeout.inMilliseconds} ms — continuing without device data.',
      );
      return const DeviceData.empty();
    } on PlatformException {
      _warnOnce('Fingerprint channel returned a platform error.');
      return const DeviceData.empty();
    } catch (_) {
      _warnOnce('Unexpected fingerprint collection failure.');
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
