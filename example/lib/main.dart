import 'package:flutter/material.dart';
import 'package:mercadopago/mercadopago.dart';

import 'screens/card_save_demo.dart';
import 'screens/card_transaction_demo.dart';
import 'screens/core_methods_demo.dart';

/// ⚠️  Replace with your MercadoPago public key.
/// Get it at https://www.mercadopago.com/developers/panel/app
/// Format: APP_USR-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
const String _publicKey = 'APP_USR-REPLACE-WITH-YOUR-KEY';

/// ISO 3-letter country code. Supported: ARG, BRA, CHL, COL, MEX, URY, PER.
const String _countryCode = 'ARG';

void main() {
  String? initError;
  try {
    MercadoPagoSDK.shared.initialize(
      publicKey: _publicKey,
      countryCode: _countryCode,
    );
  } on SDKError catch (e) {
    initError = e.message;
  }
  runApp(ExampleApp(initError: initError));
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({required this.initError, super.key});

  final String? initError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MercadoPago Flutter SDK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF009EE3)),
      ),
      home: _HomeScreen(initError: initError),
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen({required this.initError});

  final String? initError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MercadoPago Flutter SDK')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (initError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '⚠️ SDK not initialized: $initError\n'
                'Replace _publicKey in main.dart with a valid APP_USR-… key.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text('Card Save'),
            subtitle: const Text('Tokenize a card for later use'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CardSaveDemo()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Card Transaction'),
            subtitle: const Text('Tokenize + pick installments'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CardTransactionDemo(),
              ),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Core Methods'),
            subtitle: const Text('Custom UI with PCI widgets'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CoreMethodsDemo()),
            ),
          ),
        ],
      ),
    );
  }
}
