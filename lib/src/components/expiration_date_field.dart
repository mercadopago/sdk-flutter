import 'package:flutter/material.dart';

import '../domain/errors.dart';
import '_formatters.dart';
import 'pci_field_state.dart';

/// Card expiration date input formatted as MM/YY.
class ExpirationDateField extends StatefulWidget {
  const ExpirationDateField({
    required this.controller,
    this.label = 'Expiration',
    this.hintText = 'MM/YY',
    this.decoration,
    this.onFilled,
    this.onError,
    this.autofocus = false,
    this.enabled = true,
    super.key,
  });

  final PciFieldState controller;
  final String label;
  final String hintText;
  final InputDecoration? decoration;

  /// Fires with the raw MMYY (no slash) when both month and year are entered.
  final ValueChanged<String>? onFilled;
  final ValueChanged<ExpirationDateFieldError>? onError;
  final bool autofocus;
  final bool enabled;

  @override
  State<ExpirationDateField> createState() => _ExpirationDateFieldState();
}

class _ExpirationDateFieldState extends State<ExpirationDateField> {
  final TextEditingController _text = TextEditingController();

  @override
  void initState() {
    super.initState();
    _text.addListener(_onChanged);
  }

  @override
  void dispose() {
    _text.removeListener(_onChanged);
    _text.dispose();
    super.dispose();
  }

  void _onChanged() {
    final digits = _text.text.replaceAll(RegExp(r'\D'), '');
    widget.controller.update(digits);

    if (digits.length == 4) {
      final month = int.tryParse(digits.substring(0, 2)) ?? 0;
      final year = int.tryParse(digits.substring(2, 4)) ?? 0;
      if (month < 1 || month > 12) {
        widget.onError?.call(ExpirationDateFieldError.invalidMonth);
        return;
      }
      final fullYear = 2000 + year;
      final now = DateTime.now();
      final lastDayOfMonth = DateTime(fullYear, month + 1, 0);
      if (lastDayOfMonth.isBefore(DateTime(now.year, now.month, 1))) {
        widget.onError?.call(ExpirationDateFieldError.expired);
        return;
      }
      widget.onFilled?.call(digits);
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
