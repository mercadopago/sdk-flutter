part of 'pci.dart';

/// SDK-managed PCI input for a card security code (CVV/CVC).
class SecurityCodeField extends StatefulWidget {
  const SecurityCodeField({
    required this.controller,
    this.expectedLength,
    this.label = 'Security code',
    this.hintText,
    this.decoration,
    this.onFilled,
    this.autofocus = false,
    this.enabled = true,
    super.key,
  }) : assert(
         expectedLength == null || expectedLength == 3 || expectedLength == 4,
         'expectedLength must be 3, 4, or null when the card brand is not '
         'known yet.',
       );

  final PciFieldState controller;

  /// Card-brand-specific CVV/CVC length.
  ///
  /// Use the value returned by `CoreMethods.getPaymentMethods`. When the
  /// brand is not known yet, leave this null: the field accepts up to four
  /// digits and final validation happens during tokenization.
  final int? expectedLength;
  final String label;
  final String? hintText;
  final InputDecoration? decoration;

  /// Completion signal when [expectedLength] is known and reached. It does not
  /// fire while the card brand is unknown, and the CVV is never provided.
  final VoidCallback? onFilled;
  final bool autofocus;
  final bool enabled;

  @override
  State<SecurityCodeField> createState() => _SecurityCodeFieldState();
}

class _SecurityCodeFieldState extends State<SecurityCodeField>
    with WidgetsBindingObserver {
  final TextEditingController _text = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_onControllerChanged);
    _text.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(SecurityCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controllerChanged = oldWidget.controller != widget.controller;

    if (controllerChanged) {
      oldWidget.controller.removeListener(_onControllerChanged);
      oldWidget.controller._write('');
      widget.controller.addListener(_onControllerChanged);
    }

    // A controller replacement or transition away from a known card rule is
    // a new card context. Do not carry its CVV across that boundary. The
    // initial null -> known metadata resolution keeps in-progress input.
    final knownRuleChanged =
        oldWidget.expectedLength != null &&
        oldWidget.expectedLength != widget.expectedLength;
    if (controllerChanged || knownRuleChanged) {
      _clearSensitiveInput();
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
    _text.removeListener(_onChanged);
    widget.controller._write('');
    _text.clear();
    _text.dispose();
    super.dispose();
  }

  void _clearSensitiveInput() {
    _text.clear();
    widget.controller._write('');
  }

  void _onControllerChanged() {
    if (widget.controller.length == 0 && _text.text.isNotEmpty) {
      _text.clear();
    }
  }

  void _onChanged() {
    final digits = _text.text.replaceAll(RegExp(r'\D'), '');
    widget.controller._write(digits);

    final expectedLength = widget.expectedLength;
    if (expectedLength != null && digits.length == expectedLength) {
      widget.onFilled?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final decoration = (widget.decoration ?? const InputDecoration()).copyWith(
      labelText: widget.label,
      hintText: widget.hintText ?? ('•' * (widget.expectedLength ?? 3)),
      counterText: '',
    );

    return TextField(
      controller: _text,
      decoration: decoration,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      obscureText: true,
      maxLength: widget.expectedLength ?? 4,
      keyboardType: TextInputType.number,
      inputFormatters: [
        DigitsOnlyFormatter(maxLength: widget.expectedLength ?? 4),
      ],
      autocorrect: false,
      enableSuggestions: false,
      enableInteractiveSelection: false,
    );
  }
}
