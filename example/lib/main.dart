import 'package:flutter/material.dart';
import 'package:mercadopago_sdk/mercadopago_sdk.dart';

import 'screens/card_save_demo.dart';
import 'screens/card_transaction_demo.dart';
import 'screens/core_methods_demo.dart';

void main() {
  // Replace with a real public key from https://www.mercadopago.com/developers
  MercadoPagoSDK.shared.initialize(
    publicKey: 'APP_USR-REPLACE-WITH-YOUR-KEY',
    countryCode: 'ARG',
  );
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MercadoPago SDK demo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF009EE3)),
      ),
      home: const _Home(),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MercadoPago SDK')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Choose an integration path to explore:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.credit_card),
              label: const Text('Card Save (hosted checkout)'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const CardSaveDemo()),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.shopping_bag),
              label: const Text('Card Transaction (hosted checkout)'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CardTransactionDemo(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.build),
              label: const Text('Core Methods (custom UI)'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CoreMethodsDemo(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
