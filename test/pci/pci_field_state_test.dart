import 'package:flutter_test/flutter_test.dart';
// The PCI library is imported directly (not through `package:mercadopago`)
// because `debugSeedPciField` is the only write-only way to put a value into a
// controller without pumping a widget, and it is deliberately not re-exported
// from the public entry point.
import 'package:mercadopago/src/pci/pci.dart';

void main() {
  group('PciFieldState', () {
    test('toString does not leak the raw value', () {
      final state = PciFieldState();
      debugSeedPciField(state, '4111111111111111');
      expect(state.toString(), 'PciFieldState(length: 16)');
    });

    test('notifications never expose digits through public metadata', () {
      final state = PciFieldState();
      final publicSnapshots = <String>[];
      state.addListener(() => publicSnapshots.add(state.toString()));

      for (final value in const ['4', '41', '411', '4111', '41111']) {
        debugSeedPciField(state, value);
      }

      expect(publicSnapshots, hasLength(5));
      expect(publicSnapshots.join(), isNot(contains('4111')));
      expect(publicSnapshots.last, 'PciFieldState(length: 5)');
    });

    test('clear() empties the value and notifies listeners', () {
      final state = PciFieldState();
      debugSeedPciField(state, '1234');
      var notifications = 0;
      state.addListener(() => notifications++);
      state.clear();
      expect(state.length, 0);
      expect(notifications, 1);
    });

    test('dispose clears the value', () {
      final state = PciFieldState();
      debugSeedPciField(state, '4111111111111111');
      state.dispose();
      expect(state.length, 0);
    });

    test('internal write after dispose is a no-op and does not throw', () {
      final state = PciFieldState();
      debugSeedPciField(state, '1234');
      state.dispose();
      expect(() => debugSeedPciField(state, '9999'), returnsNormally);
      expect(state.length, 0);
    });

    test('clear() after dispose is a no-op and does not throw', () {
      final state = PciFieldState();
      debugSeedPciField(state, '1234');
      state.dispose();
      expect(() => state.clear(), returnsNormally);
    });

    test('listeners are not notified after dispose', () {
      final state = PciFieldState();
      debugSeedPciField(state, '1234');
      var notifications = 0;
      state.addListener(() => notifications++);
      state.dispose();
      // Internal writes after dispose must not notify listeners.
      debugSeedPciField(state, '5678');
      expect(notifications, 0);
    });

    test('the stored value is gone after dispose', () {
      final state = PciFieldState();
      debugSeedPciField(state, '4111111111111111');
      expect(state.length, 16);
      state.dispose();
      expect(state.length, 0);
    });

    // The clear-if-unchanged behaviour (an edit made while a tokenization
    // request is in flight must survive; an untouched field must be wiped) is
    // now private to the `pci` library and only observable through
    // `PciTokenizer`. Those two cases live in `pci_tokenizer_test.dart`.
  });
}
