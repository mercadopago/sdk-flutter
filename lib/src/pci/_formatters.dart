import 'package:flutter/services.dart';

/// Inserts a space every 4 digits as the user types a card number.
class CardNumberFormatter extends TextInputFormatter {
  const CardNumberFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 19) {
      return oldValue;
    }
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formats MM/YY input: auto-inserts the `/` after the second digit and
/// rejects any month > 12 as soon as enough digits are typed.
class ExpirationDateFormatter extends TextInputFormatter {
  const ExpirationDateFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 4) return oldValue;

    if (digits.length >= 2) {
      final monthStr = digits.substring(0, 2);
      final month = int.tryParse(monthStr);
      if (month == null || month < 1 || month > 12) {
        return oldValue;
      }
    }

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Strips everything except digits.
class DigitsOnlyFormatter extends TextInputFormatter {
  const DigitsOnlyFormatter({this.maxLength});

  final int? maxLength;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final clipped = maxLength != null && digits.length > maxLength!
        ? oldValue.text
        : digits;
    return TextEditingValue(
      text: clipped,
      selection: TextSelection.collapsed(offset: clipped.length),
    );
  }
}
