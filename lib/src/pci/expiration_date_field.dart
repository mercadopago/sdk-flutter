part of 'pci.dart';

/// Card expiration date input formatted as MM/YY.
class ExpirationDateField extends StatefulWidget {
  const ExpirationDateField({
    required this.controller,
    this.label = 'Expiration',
    this.hintText = 'MM/YY',
    this.decoration,
    this.onFilled,
    this.autofocus = false,
    this.enabled = true,
    super.key,
  });

  final PciFieldState controller;
  final String label;
  final String hintText;
  final InputDecoration? decoration;

  /// Fires when a valid month and year are entered. No raw value is exposed.
  final VoidCallback? onFilled;
  final bool autofocus;
  final bool enabled;

  @override
  State<ExpirationDateField> createState() => _ExpirationDateFieldState();
}

class _ExpirationDateFieldState extends State<ExpirationDateField>
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
  void didUpdateWidget(ExpirationDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      oldWidget.controller._write('');
      _text.clear();
      widget.controller._write('');
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

    if (digits.length == 4) {
      final month = int.tryParse(digits.substring(0, 2)) ?? 0;
      final year = int.tryParse(digits.substring(2, 4)) ?? 0;
      if (month < 1 || month > 12) {
        return;
      }
      final fullYear = 2000 + year;
      final now = DateTime.now();
      final lastDayOfMonth = DateTime(fullYear, month + 1, 0);
      if (lastDayOfMonth.isBefore(DateTime(now.year, now.month, 1))) {
        return;
      }
      widget.onFilled?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final decoration = (widget.decoration ?? const InputDecoration()).copyWith(
      labelText: widget.label,
      hintText: widget.hintText,
    );

    return TextField(
      controller: _text,
      decoration: decoration,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      keyboardType: TextInputType.number,
      inputFormatters: const [ExpirationDateFormatter()],
      autocorrect: false,
      enableSuggestions: false,
      enableInteractiveSelection: false,
    );
  }
}
