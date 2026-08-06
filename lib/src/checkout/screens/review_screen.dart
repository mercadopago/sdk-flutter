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
    final installment = controller.selectedInstallment;
    final method = controller.selectedMethod;

    if (token == null || installment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review')),
        body: const Center(child: Text('Missing checkout state.')),
      );
    }

    final brandLabel =
        (method != null && method.id.isNotEmpty) ? method.id.toUpperCase() : 'Card';

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
            subtitle: Text(brandLabel),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.payments),
            title: Text(
              installment.primaryLabel.isNotEmpty
                  ? installment.primaryLabel
                  : '${installment.installments}× '
                      '${installment.installmentAmount.toStringAsFixed(2)}',
            ),
            subtitle: installment.secondaryLabel.isNotEmpty
                ? Text(installment.secondaryLabel)
                : null,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Total'),
            trailing: Text(
              installment.totalAmount.toStringAsFixed(2),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            // Disabled while the order is being processed.
            onPressed: controller.isBusy ? null : onConfirm,
            child: controller.isBusy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Confirm payment'),
          ),
        ),
      ),
    );
  }
}
