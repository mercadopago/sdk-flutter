import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago_flutter_sdk/src/core/luhn.dart';

void main() {
  group('isValidLuhn', () {
    test('returns false for empty input', () {
      expect(isValidLuhn(''), isFalse);
    });

    test('returns false for non-digit characters', () {
      expect(isValidLuhn('4111-1111-1111-1111'), isFalse);
    });

    test('returns true for a known-valid Visa test number', () {
      expect(isValidLuhn('4111111111111111'), isTrue);
    });

    test('returns true for a known-valid Mastercard test number', () {
      expect(isValidLuhn('5500000000000004'), isTrue);
    });

    test('returns false when one digit is wrong', () {
      expect(isValidLuhn('4111111111111112'), isFalse);
    });
  });
}
