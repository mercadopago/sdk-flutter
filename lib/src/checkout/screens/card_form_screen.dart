import 'package:flutter/material.dart';

import '../../components/card_number_field.dart';
import '../../components/expiration_date_field.dart';
import '../../components/pci_field_state.dart';
import '../../components/security_code_field.dart';
import '../../domain/errors.dart';
import '../../domain/models/card_form_config.dart';
import '../../domain/models/identification_type.dart';
import '../../domain/result.dart';
import '../checkout_controller.dart';

/// First step of every checkout flow: collect card data.
///
/// Labels, placeholders, document types and the CVV length are server-driven
/// (from `card_payment_brick/initialization`); nothing is hardcoded per market.
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

  String? _docType;
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

  List<IdentificationType> get _docTypes =>
      widget.controller.config?.identificationTypes ?? const [];

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
    final controller = widget.controller;
    final t = controller.translations;
    final docTypes = _docTypes;
    // Default the document type to the first server-provided option.
    if (_docType == null && docTypes.isNotEmpty) {
      _docType = docTypes.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_nonEmpty(t?.title) ?? 'Card details'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onCancel,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CardNumberField(
            controller: _numberCtrl,
            autofocus: true,
            label: _nonEmpty(t?.cardNumber.label) ?? 'Card number',
            hintText: t?.cardNumber.placeholder,
            onBinChanged: controller.onBinChanged,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ExpirationDateField(
                  controller: _expCtrl,
                  label: _nonEmpty(t?.expirationDate.label) ?? 'Expiration',
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: SecurityCodeField(
                  controller: _cvvCtrl,
                  expectedLength: controller.securityCodeLength,
                  label: _nonEmpty(t?.securityCode.label) ?? 'Security code',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: _nonEmpty(t?.holderName.label) ?? 'Cardholder name',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          _buildDocumentRow(t, docTypes),
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
                : Text(_nonEmpty(t?.footerButtonLabel) ?? 'Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(
    CardFormTranslations? t,
    List<IdentificationType> docTypes,
  ) {
    final docLabel = _nonEmpty(t?.document.label) ?? 'Document number';
    if (docTypes.isEmpty) {
      // No server document types (e.g. markets that don't require it): show a
      // plain number field only.
      return TextField(
        controller: _docCtrl,
        decoration: InputDecoration(labelText: docLabel),
        keyboardType: TextInputType.number,
      );
    }
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: DropdownButtonFormField<String>(
            initialValue: _docType,
            decoration: const InputDecoration(labelText: 'Type'),
            items: [
              for (final type in docTypes)
                DropdownMenuItem(value: type.id, child: Text(type.name)),
            ],
            onChanged: (value) => setState(() => _docType = value),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _docCtrl,
            decoration: InputDecoration(labelText: docLabel),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  String? _nonEmpty(String? value) =>
      (value == null || value.isEmpty) ? null : value;
}
