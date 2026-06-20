import 'package:flutter/material.dart';

import '../core/luhn.dart';
import '../domain/errors.dart';
import '_formatters.dart';
import 'pci_field_state.dart';

/// PCI-compliant input for a card number.
///
/// The raw value never leaves the field — it lives only in [controller]
/// (a [PciFieldState]) and is wiped on dispose. Use the [onCardFilled]
/// callback to forward the value directly to the tokenization API when the
/// user completes input.
class CardNumberField extends StatefulWidget {
  const CardNumberField({
    required this.controller,
    this.label = 'Card number',
    this.hintText,
    this.decoration,
    this.onBinChanged,
    this.onLastFourFilled,
    this.onCardFilled,
    this.onError,
    this.autofocus = false,
    this.enabled = true,
    super.key,
  });

  final PciFieldState controller;
  final String label;
  final String? hintText;
  final InputDecoration? decoration;
  final ValueChanged<String>? onBinChanged;
  final ValueChanged<String>? onLastFourFilled;
  final ValueChanged<String>? onCardFilled;
  final ValueChanged<CardNumberFieldError>? onError;
  final bool autofocus;
  final bool enabled;

  @override
  State<CardNumberField> createState() => _CardNumberFieldState();
}

class _CardNumberFieldState extends State<CardNumberField> {
  final TextEditingController _text = TextEditingController();
  String? _lastBin;

  @override
  void initState() {
    super.initState();
    _text.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _text.removeListener(_onTextChanged);
    _text.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final digits = _text.text.replaceAll(RegExp(r'\D'), '');
    widget.controller.update(digits);

    if (digits.length >= 8) {
      final bin = digits.substring(0, 8);
      if (bin != _lastBin) {
        _lastBin = bin;
        widget.onBinChanged?.call(bin);
      }
    } else {
      _lastBin = null;
    }

    if (digits.length >= 4) {
      widget.onLastFourFilled
          ?.call(digits.substring(digits.length - 4, digits.length));
    }

    if (digits.length >= 13 && digits.length <= 19) {
      if (isValidLuhn(digits)) {
        widget.onCardFilled?.call(digits);
      } else if (digits.length == 16 || digits.length == 19) {
        widget.onError?.call(CardNumberFieldError.invalidLuhn);
      }
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
