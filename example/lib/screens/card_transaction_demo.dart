import 'package:flutter/material.dart';
import 'package:mercadopago_flutter_sdk/mercadopago_flutter_sdk.dart';

class CardTransactionDemo extends StatefulWidget {
  const CardTransactionDemo({super.key});

  @override
  State<CardTransactionDemo> createState() => _CardTransactionDemoState();
}

class _CardTransactionDemoState extends State<CardTransactionDemo> {
  String _status = 'Not started.';

  Future<void> _start() async {
    final builder = MercadoPagoCheckout.forCardTransaction(
      amount: 1000,
      payerEmail: 'buyer@example.com',
      onResult: (result) {
        switch (result) {
          case Success(:final data):
            setState(
              () => _status = 'Token ${data.token.token} '
                  '· ${data.installments}x ${data.transactionAmount}',
            );
          case Failure(:final error):
            setState(() => _status = 'Error: $error');
          case Cancelled():
            setState(() => _status = 'Cancelled by user.');
        }
      },
    );
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => builder.build()),
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
              onPressed: _start,
              child: const Text('Pay 1000 with card'),
            ),
            const SizedBox(height: 16),
            Text(_status),
          ],
        ),
      ),
    );
  }
}
