import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago_sdk_flutter/src/core/session_manager.dart';

void main() {
  group('SessionManager', () {
    test('produces a non-empty UUID on construction', () {
      final s = SessionManager();
      expect(s.sessionId, isNotEmpty);
    });

    test('regenerate() returns a different UUID', () {
      final s = SessionManager();
      final original = s.sessionId;
      s.regenerate();
      expect(s.sessionId, isNot(equals(original)));
    });

    test('UUID v4 format', () {
      final s = SessionManager();
      final pattern = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      expect(pattern.hasMatch(s.sessionId), isTrue);
    });
  });
}
