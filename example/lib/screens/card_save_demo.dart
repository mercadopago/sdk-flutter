import 'package:flutter/material.dart';
import 'package:mercadopago_sdk/mercadopago_sdk.dart';

class CardSaveDemo extends StatefulWidget {
  const CardSaveDemo({super.key});

  @override
  State<CardSaveDemo> createState() => _CardSaveDemoState();
}

class _CardSaveDemoState extends State<CardSaveDemo> {
  String _status = 'Not started.';

  Future<void> _start() async {
    final builder = MercadoPagoCheckout.forCardSave(
      onResult: (result) {
        switch (result) {
          case Success(:final data):
            setState(() => _status = 'Saved token: ${data.token.token}');
          case Failure(:final error):
            setState(() => _status = 'Error: $error');
          case Cancelled():
            setState(() => _status = 'Cancelled by user.');
        }
      },
    );
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => builder.build()),
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
              onPressed: _start,
              child: const Text('Open hosted checkout'),
            ),
            const SizedBox(height: 16),
            Text(_status),
          ],
        ),
      ),
    );
  }
}
