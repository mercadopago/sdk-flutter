import 'package:flutter/material.dart';
import 'package:mercadopago_flutter_sdk/mercadopago_flutter_sdk.dart';

import 'screens/card_save_demo.dart';
import 'screens/card_transaction_demo.dart';
import 'screens/core_methods_demo.dart';

/// ⚠️  Replace this with your MercadoPago public key.
///
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
      appBar: AppBar(
        title: const Text('MercadoPago Flutter SDK'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (initError != null) ...[
            _ErrorBanner(
              message: 'SDK not initialized: $initError\n\n'
                  'Replace _publicKey in main.dart with a valid '
                  'APP_USR-… key from '
                  'https://www.mercadopago.com/developers/panel/app',
            ),
            const SizedBox(height: 20),
          ],
          const Text(
            'Three integration paths',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose the one that fits your use case.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          _PathCard(
            icon: Icons.credit_card_outlined,
            title: 'Card Save',
            subtitle: 'Tokenize a card for later — no payment charged now.',
            onTap: () => _push(context, const CardSaveDemo()),
          ),
          const SizedBox(height: 12),
          _PathCard(
            icon: Icons.shopping_cart_outlined,
            title: 'Card Transaction',
            subtitle: 'Tokenize + pick installments for an immediate payment.',
            onTap: () => _push(context, const CardTransactionDemo()),
          ),
          const SizedBox(height: 12),
          _PathCard(
            icon: Icons.tune_outlined,
            title: 'Core Methods',
            subtitle: 'Build your own UI using PCI-compliant input fields.',
            onTap: () => _push(context, const CoreMethodsDemo()),
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

class _PathCard extends StatelessWidget {
  const _PathCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading:
            Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
