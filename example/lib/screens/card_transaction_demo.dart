import 'package:flutter/material.dart';
import 'package:mercadopago_flutter_sdk/mercadopago_flutter_sdk.dart';

/// Demonstrates the CardTransaction hosted checkout.
///
/// The SDK handles card entry, installment selection and review. The app
/// receives the [CardTransactionResult] with the token and the chosen
/// installment plan — send both to your backend to create the payment.
class CardTransactionDemo extends StatefulWidget {
  const CardTransactionDemo({super.key});

  @override
  State<CardTransactionDemo> createState() => _CardTransactionDemoState();
}

class _CardTransactionDemoState extends State<CardTransactionDemo> {
  bool _loading = false;
  String _status = '';

  Future<void> _open() async {
    if (_loading) return; // prevent double-tap
    setState(() {
      _loading = true;
      _status = '';
    });

    final builder = MercadoPagoCheckout.forCardTransaction(
      // Create the order from YOUR backend via the Orders API, then pass its
      // id and client token here. The amount is resolved server-side from the
      // order — you do not pass it. These are placeholders.
      order: const MPOrder(
        orderId: '<ORDER_ID_FROM_ORDERS_API>',
        clientToken: '<CLIENT_TOKEN_FROM_ORDERS_API>',
      ),
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _status = switch (result) {
            Success(:final data) =>
              '✓ Ready to pay.\n'
                  '${data.installments}x ${data.installment.installmentAmount.toStringAsFixed(2)}'
                  '  •  Total: ${data.transactionAmount.toStringAsFixed(2)}\n\n'
                  'Send data.token.token + data.installments to your backend.',
            Failure(:final error) => '✗ $error',
            Cancelled() => 'Cancelled.',
          };
        });
      },
    ).setPaymentMethodConfiguration([
      // Optional: restrict card types/brands and the installment range.
      const MPPaymentMethodConfig.card(
        installment: MPInstallment(maxInstallments: 6),
      ),
    ]);

    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => builder.build()),
    );

    if (mounted && _loading) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Card Transaction')),
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
                  : const Text('Pay \$1000'),
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
