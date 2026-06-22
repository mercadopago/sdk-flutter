import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago_sdk/mercadopago_sdk.dart';

void main() {
  group('PciFieldState', () {
    test('toString does not leak the raw value', () {
      final state = PciFieldState(initialValue: '4111111111111111');
      expect(state.toString(), 'PciFieldState(length: 16)');
    });

    test('masked exposes only the last 4 digits', () {
      final state = PciFieldState(initialValue: '4111111111111111');
      expect(state.masked, '${'*' * 12}1111');
    });

    test('clear() empties the value and notifies listeners', () {
      final state = PciFieldState(initialValue: '1234');
      var notifications = 0;
      state.addListener(() => notifications++);
      state.clear();
      expect(state.rawValue, '');
      expect(notifications, 1);
    });

    test('dispose clears the value', () {
      final state = PciFieldState(initialValue: '4111111111111111');
      state.dispose();
      expect(state.rawValue, '');
    });

    test('update() after dispose is a no-op and does not throw', () {
      final state = PciFieldState(initialValue: '1234');
      state.dispose();
      expect(() => state.update('9999'), returnsNormally);
      expect(state.rawValue, '');
    });

    test('clear() after dispose is a no-op and does not throw', () {
      final state = PciFieldState(initialValue: '1234');
      state.dispose();
      expect(() => state.clear(), returnsNormally);
    });

    test('listeners are not notified after dispose', () {
      final state = PciFieldState(initialValue: '1234');
      var notifications = 0;
      state.addListener(() => notifications++);
      state.dispose();
      // update() after dispose must not notify listeners.
      state.update('5678');
      expect(notifications, 0);
    });

    test('rawValue returns empty string after dispose', () {
      final state = PciFieldState(initialValue: '4111111111111111');
      expect(state.rawValue, '4111111111111111');
      state.dispose();
      expect(state.rawValue, '');
    });
  });
}
