import 'package:flutter/material.dart';
import 'package:mercadopago/mercadopago.dart';

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

  void _open() {
    if (_loading) return; // prevent double-tap
    setState(() {
      _loading = true;
      _status = '';
    });

    MercadoPagoCheckout(
      // Create the order from YOUR backend via the Orders API, then pass its
      // id and client token here. The amount is resolved server-side from the
      // order — you do not pass it. These are placeholders.
      MPCheckoutType.cardTransaction(
        const MPOrder(
          orderId: '<ORDER_ID_FROM_ORDERS_API>',
          clientToken: '<CLIENT_TOKEN_FROM_ORDERS_API>',
        ),
      ),
    ).setPaymentMethodConfiguration([
      // Optional: restrict card types/brands and the installment range.
      const MPPaymentMethodConfig.card(
        installment: MPInstallment(maxInstallments: 6),
      ),
    ]).show(
      context,
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _status = switch (result) {
            // The SDK processed the order; you receive its status.
            CheckoutSuccess(:final data) => '✓ Order ${data.orderStatus}.\n'
                '${data.installments}x  •  '
                'Total: ${data.transactionAmount?.toStringAsFixed(2)}\n\n'
                'Order id: ${data.orderId}',
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
