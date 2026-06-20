import 'package:flutter/material.dart';

import '../domain/errors.dart';
import '_formatters.dart';
import 'pci_field_state.dart';

/// PCI-compliant input for a card security code (CVV/CVC).
class SecurityCodeField extends StatefulWidget {
  const SecurityCodeField({
    required this.controller,
    this.expectedLength = 3,
    this.label = 'Security code',
    this.hintText,
    this.decoration,
    this.onFilled,
    this.onError,
    this.autofocus = false,
    this.enabled = true,
    super.key,
  });

  final PciFieldState controller;
  final int expectedLength;
  final String label;
  final String? hintText;
  final InputDecoration? decoration;
  final ValueChanged<String>? onFilled;
  final ValueChanged<SecurityCodeFieldError>? onError;
  final bool autofocus;
  final bool enabled;

  @override
  State<SecurityCodeField> createState() => _SecurityCodeFieldState();
}

class _SecurityCodeFieldState extends State<SecurityCodeField> {
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

    if (digits.length == widget.expectedLength) {
      widget.onFilled?.call(digits);
    } else if (digits.length > widget.expectedLength) {
      widget.onError?.call(SecurityCodeFieldError.invalidLength);
    }
  }

  @override
  Widget build(BuildContext context) {
    final decoration = (widget.decoration ?? const InputDecoration()).copyWith(
      labelText: widget.label,
      hintText: widget.hintText ?? ('•' * widget.expectedLength),
      counterText: '',
    );

    return TextField(
      controller: _text,
      decoration: decoration,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      obscureText: true,
      maxLength: widget.expectedLength,
      keyboardType: TextInputType.number,
      inputFormatters: [DigitsOnlyFormatter(maxLength: widget.expectedLength)],
      autocorrect: false,
      enableSuggestions: false,
      enableInteractiveSelection: false,
    );
  }
}
