import 'package:flutter/material.dart';
import 'package:mercadopago_flutter_sdk/mercadopago_flutter_sdk.dart';

/// Demonstrates how to bypass the hosted UI and use [CoreMethods] directly
/// with the SDK's PCI widgets.
class CoreMethodsDemo extends StatefulWidget {
  const CoreMethodsDemo({super.key});

  @override
  State<CoreMethodsDemo> createState() => _CoreMethodsDemoState();
}

class _CoreMethodsDemoState extends State<CoreMethodsDemo> {
  final _number = PciFieldState();
  final _cvv = PciFieldState();
  final _exp = PciFieldState();
  final _name = TextEditingController();
  String _status = 'Idle.';
  bool _busy = false;

  @override
  void dispose() {
    _number.dispose();
    _cvv.dispose();
    _exp.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _tokenize() async {
    final exp = _exp.rawValue;
    if (exp.length != 4) return;
    final month = int.parse(exp.substring(0, 2));
    final year = 2000 + int.parse(exp.substring(2, 4));

    setState(() {
      _busy = true;
      _status = 'Tokenizing…';
    });

    final result = await MercadoPagoSDK.shared.coreMethods.createTokenForNewCard(
      NewCardData(
        cardNumber: _number.rawValue,
        cardholderName: _name.text.trim(),
        expirationMonth: month,
        expirationYear: year,
        securityCode: _cvv.rawValue,
      ),
    );

    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = switch (result) {
        Success(:final data) => 'Token: ${data.token}',
        Failure(:final error) => 'Error: $error',
        Cancelled() => 'Cancelled.',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Core Methods')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CardNumberField(controller: _number),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: ExpirationDateField(controller: _exp)),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: SecurityCodeField(controller: _cvv),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Cardholder'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _tokenize,
            child: const Text('Tokenize'),
          ),
          const SizedBox(height: 16),
          Text(_status),
        ],
      ),
    );
  }
}
