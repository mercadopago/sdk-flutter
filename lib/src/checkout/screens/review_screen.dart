import 'package:flutter/material.dart';

import '../checkout_controller.dart';

/// Step 3 of CardTransaction flows: confirm before returning to the host app.
class ReviewScreen extends StatelessWidget {
  const ReviewScreen({
    required this.controller,
    required this.onConfirm,
    required this.onBack,
    super.key,
  });

  final CheckoutController controller;
  final VoidCallback onConfirm;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final token = controller.token;
    final cost = controller.selectedPayerCost;
    final method = controller.selectedMethod;

    if (token == null || cost == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review')),
        body: const Center(child: Text('Missing checkout state.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review'),
        leading: BackButton(onPressed: onBack),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: Text('•••• •••• •••• ${token.lastFourDigits}'),
            subtitle: Text(method?.name ?? 'Card'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.payments),
            title: Text('${cost.installments}× ${cost.installmentAmount.toStringAsFixed(2)}'),
            subtitle: Text(
              cost.installmentRate == 0
                  ? 'No interest'
                  : '${cost.installmentRate}% interest',
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Total'),
            trailing: Text(
              cost.totalAmount.toStringAsFixed(2),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: onConfirm,
            child: const Text('Confirm payment'),
          ),
        ),
      ),
    );
  }
}
