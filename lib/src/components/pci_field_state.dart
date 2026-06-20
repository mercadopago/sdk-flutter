import 'package:flutter/foundation.dart';

/// Holds a single PCI value (card number, CVV, or expiration date) in
/// memory only.
///
/// Card data NEVER leaves this object. [toString] intentionally hides the
/// value so accidental `print()` calls cannot leak it. The widget owning the
/// controller calls [dispose] when removed from the tree, which clears the
/// underlying string.
class PciFieldState extends ChangeNotifier {
  PciFieldState({String initialValue = ''}) : _value = initialValue;

  String _value;
  bool _disposed = false;

  /// Length of the stored value. Safe to expose because it leaks no card data.
  int get length => _value.length;

  /// Returns the raw value. Only call this when sending it to the API client
  /// or running validation — never log or store it elsewhere.
  String get rawValue {
    if (_disposed) return '';
    return _value;
  }

  /// Returns a masked version safe for telemetry / debugging.
  String get masked {
    if (_value.length <= 4) return '*' * _value.length;
    return '*' * (_value.length - 4) + _value.substring(_value.length - 4);
  }

  /// Replaces the stored value. Notifies listeners.
  void update(String value) {
    if (_disposed) return;
    _value = value;
    notifyListeners();
  }

  /// Clears the stored value.
  void clear() => update('');

  @override
  String toString() => 'PciFieldState(length: ${_value.length})';

  @override
  void dispose() {
    _value = '';
    _disposed = true;
    super.dispose();
  }
}
