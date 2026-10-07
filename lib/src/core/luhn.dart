/// Validates a numeric string using the Luhn algorithm.
///
/// Returns `false` for empty strings or strings containing non-digit
/// characters. The function never throws — it is safe to call on any input.
bool isValidLuhn(String digits) {
  if (digits.isEmpty) return false;

  var sum = 0;
  var alternate = false;

  for (var i = digits.length - 1; i >= 0; i--) {
    final codeUnit = digits.codeUnitAt(i);
    if (codeUnit < 0x30 || codeUnit > 0x39) {
      return false;
    }
    var n = codeUnit - 0x30;
    if (alternate) {
      n *= 2;
      if (n > 9) n -= 9;
    }
    sum += n;
    alternate = !alternate;
  }

  return sum % 10 == 0;
}
