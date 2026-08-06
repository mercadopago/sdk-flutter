import 'package:flutter/material.dart';
import 'package:mercadopago_flutter_sdk/mercadopago_flutter_sdk.dart';

/// Demonstrates the CardSave hosted checkout.
///
/// The SDK owns the card-entry UI. The app only receives the opaque
/// [CardToken] — send `result.token.token` to your backend immediately.
/// Never store or log the token on device; it expires in ~15 minutes.
class CardSaveDemo extends StatefulWidget {
  const CardSaveDemo({super.key});

  @override
  State<CardSaveDemo> createState() => _CardSaveDemoState();
}

class _CardSaveDemoState extends State<CardSaveDemo> {
  bool _loading = false;
  String _status = '';

  void _open() {
    if (_loading) return; // prevent double-tap
    setState(() {
      _loading = true;
      _status = '';
    });

    MercadoPagoCheckout(MPCheckoutType.cardSave()).show(
      context,
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _status = switch (result) {
            CheckoutSuccess(:final data) => '✓ Card saved.\n'
                'Method: ${data.paymentMethodId}  •  '
                'Last 4: ${data.token.lastFourDigits}\n\n'
                'Send data.token.token to your backend.',
            CheckoutError(:final error) => '✗ $error',
            CheckoutUserCancelled() => 'Cancelled.',
          };
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Card Save')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: _loading ? null : _open,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Open Card Save checkout'),
            ),
            if (_status.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(_status),
            ],
          ],
        ),
      ),
    );
  }
}
