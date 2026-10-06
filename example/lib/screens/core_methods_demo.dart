import 'package:flutter/material.dart';
import 'package:mercadopago/mercadopago.dart';

/// Demonstrates CoreMethods with SDK-managed PCI input widgets.
///
/// In this path the app owns the form UI. The SDK's PCI widgets store the
/// sensitive values in memory and forward them directly to the tokenization
/// endpoint — this code never reads the raw card number or CVV.
///
/// On success send `token.token` to your backend. Never store or log it on
/// device; it expires after first use or within Mercado Pago's documented
/// maximum lifetime (currently 7 days).
class CoreMethodsDemo extends StatefulWidget {
  const CoreMethodsDemo({super.key});

  @override
  State<CoreMethodsDemo> createState() => _CoreMethodsDemoState();
}

class _CoreMethodsDemoState extends State<CoreMethodsDemo> {
  // PCI controllers — raw values are read exclusively inside the SDK.
  final _cardNumber = PciFieldState();
  final _securityCode = PciFieldState();
  final _expirationDate = PciFieldState();
  final _nameCtrl = TextEditingController();

  bool _loading = false;
  String _status = '';
  String? _activeBin;
  int? _securityCodeLength;
  String? _paymentMethodName;

  @override
  void dispose() {
    _cardNumber.dispose();
    _securityCode.dispose();
    _expirationDate.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentMetadata(String? bin) async {
    _activeBin = bin;
    _securityCode.clear();

    if (mounted) {
      setState(() {
        _securityCodeLength = null;
        _paymentMethodName = null;
      });
    }
    if (bin == null) return;

    final result = await MercadoPagoSDK.shared.coreMethods.getPaymentMethods(
      bin: bin,
    );
    if (!mounted || _activeBin != bin) return;

    final methods = switch (result) {
      Success(:final data) => data,
      Failure() => const <PaymentMethod>[],
    };
    final method = methods.isEmpty ? null : methods.first;
    final length = method?.securityCodeLength;
    setState(() {
      _securityCodeLength = length == 3 || length == 4 ? length : null;
      _paymentMethodName = method?.name;
    });
  }

  Future<void> _tokenize() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _status = '';
    });

    final result = await MercadoPagoSDK.shared.coreMethods
        .createTokenForNewCard(
          cardNumber: _cardNumber,
          expirationDate: _expirationDate,
          securityCode: _securityCode,
          identification: BuyerIdentification(name: _nameCtrl.text.trim()),
        );

    if (!mounted) return;
    setState(() {
      _loading = false;
      _status = switch (result) {
        Success(:final data) =>
          '✓ Tokenized.\n'
              'Last 4: ${data.lastFourDigits ?? 'not returned'}  •  '
              'BIN: ${data.bin ?? 'not returned'}\n\n'
              'Send token.token to your backend to create a payment.',
        Failure(:final error) => '✗ ${_describe(error)}',
      };
    });
  }

  String _describe(MercadoPagoError error) => switch (error) {
    InvalidCardNumberError() => 'Invalid card number.',
    InvalidCvvError() => 'Invalid security code.',
    InvalidExpirationDateError() ||
    CardExpiredError() => 'Invalid or expired date.',
    NetworkError(:final message) => 'Network error: $message',
    ValidationError(:final message) => message,
    _ => error.toString(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Core Methods')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // PCI fields — the SDK reads these values; this widget never can.
          CardNumberField(
            controller: _cardNumber,
            autofocus: true,
            onBinChanged: _loadPaymentMetadata,
            enabled: !_loading,
          ),
          if (_paymentMethodName != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Detected card: $_paymentMethodName'),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ExpirationDateField(
                  controller: _expirationDate,
                  enabled: !_loading,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: SecurityCodeField(
                  controller: _securityCode,
                  expectedLength: _securityCodeLength,
                  enabled: !_loading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            enabled: !_loading,
            decoration: const InputDecoration(labelText: 'Cardholder name'),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _tokenize,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Tokenize'),
          ),
          if (_status.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(_status),
          ],
        ],
      ),
    );
  }
}
