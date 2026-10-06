part of 'pci.dart';

/// Holds the state of a single PCI field in memory only.
///
/// The value is private to the `pci` library: there is **no accessor** that
/// returns it, exported or otherwise. The SDK's own widgets write into it and
/// [PciTokenizer] reads it — both live in this same library, which is what
/// makes the boundary real rather than advisory.
///
/// [toString] intentionally hides the value so accidental logging cannot leak
/// card data. Consumers must still call [dispose] when the form is destroyed.
class PciFieldState extends ChangeNotifier {
  PciFieldState();

  String _value = '';
  int _revision = 0;
  bool _disposed = false;

  /// Length of the stored value. Safe to expose because it leaks no card data.
  int get length => _value.length;

  /// Clears the stored value.
  void clear() => _write('');

  void _write(String value) {
    if (_disposed || _value == value) return;
    _value = value;
    _revision++;
    notifyListeners();
  }

  /// Value captured before an asynchronous operation, so the field can be
  /// cleared afterwards only if the user has not edited it in the meantime.
  _PciSnapshot get _snapshot =>
      (value: _disposed ? '' : _value, revision: _revision);

  /// Clears the field only if it has not been edited or disposed since
  /// [snapshot] was captured — an in-flight edit must survive.
  void _clearIfUnchanged(_PciSnapshot snapshot) {
    if (!_disposed && _revision == snapshot.revision) _write('');
  }

  @override
  String toString() => 'PciFieldState(length: ${_value.length})';

  @override
  void dispose() {
    _value = '';
    _revision++;
    _disposed = true;
    super.dispose();
  }
}

/// A PCI value and the revision it was read at. Private to this library.
typedef _PciSnapshot = ({String value, int revision});

/// Seeds a field without going through a widget. **Debug-only and write-only**:
/// it never returns the value, so it cannot be used to extract one, and it
/// throws outside debug builds.
///
/// This exists because the SDK's own input formatters physically cannot produce
/// the inputs some defence-in-depth tests need (a non-numeric PAN, a 20-digit
/// PAN, month 13). Production code must never call it.
@visibleForTesting
void debugSeedPciField(PciFieldState state, String value) {
  var inDebug = false;
  assert(() {
    inDebug = true;
    return true;
  }());
  if (!inDebug) {
    throw UnsupportedError(
      'debugSeedPciField is unavailable outside debug builds.',
    );
  }
  state._write(value);
}
