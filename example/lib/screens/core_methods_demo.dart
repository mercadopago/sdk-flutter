import 'package:flutter/material.dart';
import 'package:mercadopago_flutter_sdk/mercadopago_flutter_sdk.dart';

/// Demonstrates CoreMethods with PCI-compliant input widgets.
///
/// In this path the app owns the form UI. The SDK's PCI widgets store the
/// sensitive values in memory and forward them directly to the tokenization
/// endpoint — this code never reads the raw card number or CVV.
///
/// On success send `token.token` to your backend. Never store or log it on
/// device; it expires in ~15 minutes.
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

  @override
  void dispose() {
    _cardNumber.dispose();
    _securityCode.dispose();
    _expirationDate.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _tokenize() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _status = '';
    });

    final result =
        await MercadoPagoSDK.shared.coreMethods.createTokenForNewCard(
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
              'Last 4: ${data.lastFourDigits}  •  '
              'Method: ${data.bin}\n\n'
              'Send token.token to your backend to create a payment.',
        Failure(:final error) => '✗ ${_describe(error)}',
        // CoreMethods never emits Cancelled — case required for exhaustiveness.
        Cancelled() => 'Unexpected state.',
      };
    });
  }

  String _describe(MercadoPagoError error) => switch (error) {
        InvalidCardNumberError() => 'Invalid card number.',
        InvalidCvvError() => 'Invalid security code.',
        InvalidExpirationDateError() || CardExpiredError() =>
          'Invalid or expired date.',
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
          CardNumberField(controller: _cardNumber, autofocus: true),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ExpirationDateField(controller: _expirationDate),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: SecurityCodeField(controller: _securityCode),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
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
