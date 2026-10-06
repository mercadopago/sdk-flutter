part of 'pci.dart';

/// SDK-managed PCI input for a card number.
///
/// The full card number remains inside [controller]. Only the six-digit BIN is
/// exposed through [onBinChanged], so the application can resolve card-brand
/// metadata. Pass [controller] directly to `CoreMethods` when the form is
/// submitted; final length and Luhn validation happen there.
class CardNumberField extends StatefulWidget {
  const CardNumberField({
    required this.controller,
    this.label = 'Card number',
    this.hintText,
    this.decoration,
    this.onBinChanged,
    this.autofocus = false,
    this.enabled = true,
    super.key,
  });

  final PciFieldState controller;
  final String label;
  final String? hintText;
  final InputDecoration? decoration;

  /// Called with the six-digit BIN when it becomes available, and with null
  /// when editing makes the BIN incomplete again.
  final ValueChanged<String?>? onBinChanged;
  final bool autofocus;
  final bool enabled;

  @override
  State<CardNumberField> createState() => _CardNumberFieldState();
}

class _CardNumberFieldState extends State<CardNumberField>
    with WidgetsBindingObserver {
  final TextEditingController _text = TextEditingController();
  String? _lastBin;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_onControllerChanged);
    _text.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(CardNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      oldWidget.controller._write('');
      _text.clear();
      widget.controller._write('');
      _lastBin = null;
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _clearSensitiveInput();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_onControllerChanged);
    _text.removeListener(_onTextChanged);
    widget.controller._write('');
    _text.clear();
    _text.dispose();
    super.dispose();
  }

  void _clearSensitiveInput() {
    final hadBin = _lastBin != null;
    _lastBin = null;
    _text.clear();
    widget.controller._write('');
    if (hadBin) widget.onBinChanged?.call(null);
  }

  void _onControllerChanged() {
    if (widget.controller.length == 0 && _text.text.isNotEmpty) {
      _text.clear();
    }
  }

  void _onTextChanged() {
    final digits = _text.text.replaceAll(RegExp(r'\D'), '');
    widget.controller._write(digits);

    if (digits.length >= 8) {
      final bin = digits.substring(0, 8);
      if (bin != _lastBin) {
        _lastBin = bin;
        widget.onBinChanged?.call(bin);
      }
    } else if (_lastBin != null) {
      _lastBin = null;
      widget.onBinChanged?.call(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final decoration = (widget.decoration ?? const InputDecoration()).copyWith(
      labelText: widget.label,
      hintText: widget.hintText ?? '0000 0000 0000 0000',
    );

    return TextField(
      controller: _text,
      decoration: decoration,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      keyboardType: TextInputType.number,
      inputFormatters: const [CardNumberFormatter()],
      autocorrect: false,
      enableSuggestions: false,
      enableInteractiveSelection: false,
      obscuringCharacter: '*',
    );
  }
}
