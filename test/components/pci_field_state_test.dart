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
  });
}
