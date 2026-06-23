import 'package:flutter/material.dart';

import '../checkout_controller.dart';

/// Step 2 of CardTransaction flows: pick an installment plan.
class InstallmentScreen extends StatelessWidget {
  const InstallmentScreen({
    required this.controller,
    required this.onContinue,
    required this.onBack,
    super.key,
  });

  final CheckoutController controller;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final installment = controller.installments.isEmpty
        ? null
        : controller.installments.first;
    final payerCosts = installment?.payerCosts ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Installments'),
        leading: BackButton(onPressed: onBack),
      ),
      body: payerCosts.isEmpty
          ? const Center(child: Text('No installment options available.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: payerCosts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final cost = payerCosts[i];
                final selected = controller.selectedPayerCost == cost;
                return ListTile(
                  key: ValueKey(cost.paymentMethodOptionId),
                  selected: selected,
                  title: Text(
                    '${cost.installments}x ${cost.installmentAmount.toStringAsFixed(2)}',
                  ),
                  subtitle: Text(
                    cost.installmentRate == 0
                        ? 'No interest · Total ${cost.totalAmount.toStringAsFixed(2)}'
                        : '${cost.installmentRate}% · Total ${cost.totalAmount.toStringAsFixed(2)}',
                  ),
                  trailing: selected
                      ? const Icon(Icons.check_circle)
                      : const Icon(Icons.circle_outlined),
                  onTap: () => controller.selectPayerCost(cost),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed:
                controller.selectedPayerCost == null ? null : onContinue,
            child: const Text('Continue'),
          ),
        ),
      ),
    );
  }
}
