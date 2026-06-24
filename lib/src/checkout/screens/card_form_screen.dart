import 'package:flutter/material.dart';

import '../../components/card_number_field.dart';
import '../../components/expiration_date_field.dart';
import '../../components/pci_field_state.dart';
import '../../components/security_code_field.dart';
import '../../domain/errors.dart';
import '../../domain/result.dart';
import '../checkout_controller.dart';

/// First step of every checkout flow: collect card data.
class CardFormScreen extends StatefulWidget {
  const CardFormScreen({
    required this.controller,
    required this.onCancel,
    required this.onTokenized,
    super.key,
  });

  final CheckoutController controller;
  final VoidCallback onCancel;
  final VoidCallback onTokenized;

  @override
  State<CardFormScreen> createState() => _CardFormScreenState();
}

class _CardFormScreenState extends State<CardFormScreen> {
  final _numberCtrl = PciFieldState();
  final _cvvCtrl = PciFieldState();
  final _expCtrl = PciFieldState();
  final _nameCtrl = TextEditingController();
  final _docCtrl = TextEditingController();

  String _docType = 'DNI';
  bool _submitting = false;
  String? _localError;

  @override
  void dispose() {
    _numberCtrl.dispose();
    _cvvCtrl.dispose();
    _expCtrl.dispose();
    _nameCtrl.dispose();
    _docCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_submitting) return;
    if (_numberCtrl.rawValue.isEmpty ||
        _cvvCtrl.rawValue.length < 3 ||
        _expCtrl.rawValue.length != 4 ||
        _nameCtrl.text.trim().isEmpty) {
      setState(() => _localError = 'Please complete all required fields.');
      return;
    }

    setState(() {
      _submitting = true;
      _localError = null;
    });

    final result = await widget.controller.submitCardForm(
      cardNumber: _numberCtrl,
      securityCode: _cvvCtrl,
      expirationDate: _expCtrl,
      cardholderName: _nameCtrl.text.trim(),
      documentType: _docCtrl.text.isNotEmpty ? _docType : null,
      documentNumber: _docCtrl.text.isNotEmpty ? _docCtrl.text : null,
    );

    if (!mounted) return;
    setState(() {
      _submitting = false;
    });

    switch (result) {
      case Success():
        widget.onTokenized();
      case Failure(:final error):
        setState(() => _localError = _humanize(error));
      case Cancelled():
        break;
    }
  }

  String _humanize(MercadoPagoError error) => switch (error) {
        InvalidCardNumberError() => 'The card number is invalid.',
        InvalidCvvError() => 'The security code is invalid.',
        InvalidExpirationDateError() => 'The expiration date is invalid.',
        CardExpiredError() => 'This card has expired.',
        NetworkError(:final message) => 'Network error: $message',
        ValidationError(:final message) => message,
        _ => 'Unexpected error. Please try again.',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card details'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onCancel,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CardNumberField(controller: _numberCtrl, autofocus: true),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: ExpirationDateField(controller: _expCtrl)),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: SecurityCodeField(controller: _cvvCtrl),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Cardholder name',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 90,
                child: DropdownButtonFormField<String>(
                  initialValue: _docType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'DNI', child: Text('DNI')),
                    DropdownMenuItem(value: 'CPF', child: Text('CPF')),
                    DropdownMenuItem(value: 'RUT', child: Text('RUT')),
                    DropdownMenuItem(value: 'CC', child: Text('CC')),
                    DropdownMenuItem(value: 'CE', child: Text('CE')),
                  ],
                  onChanged: (v) => setState(() => _docType = v ?? 'DNI'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _docCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Document number',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          if (_localError != null) ...[
            const SizedBox(height: 12),
            Text(
              _localError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _onSubmit,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
