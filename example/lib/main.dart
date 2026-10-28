import 'package:flutter/material.dart';
import 'package:mercadopago_sdk_flutter/mercadopago_sdk_flutter.dart';

import 'screens/core_methods_demo.dart';

/// Supply this at runtime instead of committing credentials:
/// `flutter run --dart-define=MERCADOPAGO_PUBLIC_KEY=TEST-...`
const String _publicKey = String.fromEnvironment('MERCADOPAGO_PUBLIC_KEY');

/// ISO 3-letter country code. Supported: ARG, BRA, CHL, COL, MEX, URY, PER.
const String _countryCode = String.fromEnvironment(
  'MERCADOPAGO_COUNTRY_CODE',
  defaultValue: 'ARG',
);

void main() {
  String? initError;
  if (_publicKey.isEmpty) {
    initError = 'MERCADOPAGO_PUBLIC_KEY was not provided.';
  } else {
    try {
      MercadoPagoSDK.shared.initialize(
        publicKey: _publicKey,
        countryCode: _countryCode,
      );
    } on SDKError catch (e) {
      initError = e.message;
    }
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
                'Run with --dart-define=MERCADOPAGO_PUBLIC_KEY=TEST-… '
                '(or APP_USR-… in production).',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text('Card tokenization'),
            subtitle: const Text('CoreMethods with PCI widgets'),
            trailing: const Icon(Icons.chevron_right),
            onTap: initError != null
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CoreMethodsDemo(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
