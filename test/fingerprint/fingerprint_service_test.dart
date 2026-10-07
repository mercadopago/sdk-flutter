import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago/src/fingerprint/fingerprint_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('mercadopago/fingerprint-test');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('returns native fingerprint data', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getDeviceData');
      return <String, Object?>{'platform': 'android', 'sdk_int': 34};
    });

    final result = await FingerprintService(channel: channel).collect();

    expect(result.toJson(), {'platform': 'android', 'sdk_int': 34});
  });

  test('falls back when native data is empty', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => <String, Object?>{},
    );

    final result = await FingerprintService(channel: channel).collect();

    expect(result.isEmpty, isTrue);
  });

  test('falls back when the plugin is missing', () async {
    final result = await FingerprintService(channel: channel).collect();

    expect(result.isEmpty, isTrue);
  });

  test('falls back on a platform error', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(
        code: 'FINGERPRINT_FAILED',
        message: 'unavailable',
      ),
    );

    final result = await FingerprintService(channel: channel).collect();

    expect(result.isEmpty, isTrue);
  });

  test(
    'times out and falls back when native collection never completes',
    () async {
      final pending = Completer<Object?>();
      messenger.setMockMethodCallHandler(channel, (_) => pending.future);

      final result = await FingerprintService(
        channel: channel,
        timeout: const Duration(milliseconds: 10),
      ).collect().timeout(const Duration(seconds: 1));

      expect(result.isEmpty, isTrue);
    },
  );
}
