import 'package:flutter/material.dart';

import '../checkout_controller.dart';

/// Step 2 of CardTransaction flows: pick an installment plan.
///
/// Options come from the aggregated `card_payment_brick/card` call; the primary
/// and secondary lines are server-rendered.
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
    final options = controller.installments;
    final headerTitle = controller.translations?.installmentsHeaderTitle;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          (headerTitle != null && headerTitle.isNotEmpty)
              ? headerTitle
              : 'Installments',
        ),
        leading: BackButton(onPressed: onBack),
      ),
      body: options.isEmpty
          ? const Center(child: Text('No installment options available.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: options.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final option = options[i];
                final selected = controller.selectedInstallment == option;
                return ListTile(
                  key: ValueKey('installment_${option.installments}'),
                  selected: selected,
                  title: Text(
                    option.primaryLabel.isNotEmpty
                        ? option.primaryLabel
                        : '${option.installments}x '
                            '${option.installmentAmount.toStringAsFixed(2)}',
                  ),
                  subtitle: option.secondaryLabel.isNotEmpty
                      ? Text(option.secondaryLabel)
                      : null,
                  trailing: selected
                      ? const Icon(Icons.check_circle)
                      : const Icon(Icons.circle_outlined),
                  onTap: () => controller.selectInstallment(option),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed:
                controller.selectedInstallment == null ? null : onContinue,
            child: const Text('Continue'),
          ),
        ),
      ),
    );
  }
}
