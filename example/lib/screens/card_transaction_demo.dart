import 'package:flutter/material.dart';
import 'package:mercadopago_flutter_sdk/mercadopago_flutter_sdk.dart';

/// Demonstrates the CardTransaction hosted checkout flow.
///
/// The SDK presents a full UI: card entry → installment selection → review.
/// On completion the app receives a [CardTransactionResult] containing the
/// token and the chosen [PayerCost]. Send both to your backend to create the
/// payment — never store the token on device.
class CardTransactionDemo extends StatefulWidget {
  const CardTransactionDemo({super.key});

  @override
  State<CardTransactionDemo> createState() => _CardTransactionDemoState();
}

class _CardTransactionDemoState extends State<CardTransactionDemo> {
  static const double _amount = 1000.0;
  static const String _payerEmail = 'buyer@example.com';

  _DemoState _state = const _Idle();

  Future<void> _openCheckout() async {
    if (_state is _Loading) return; // guard against double-tap

    setState(() => _state = const _Loading());

    final builder = MercadoPagoCheckout.forCardTransaction(
      amount: _amount,
      payerEmail: _payerEmail,
      onResult: (result) {
        if (!mounted) return;
        switch (result) {
          case Success(:final data):
            setState(() => _state = _Success(data));
          case Failure(:final error):
            setState(() => _state = _Failure(error.toString()));
          case Cancelled():
            setState(() => _state = const _Idle());
        }
      },
    );

    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => builder.build()),
    );

    if (mounted && _state is _Loading) {
      setState(() => _state = const _Idle());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Card Transaction')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Checkout for \$$_amount. The SDK handles card entry, '
              'installment selection and review. You receive the token '
              'and the selected installment plan.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: _state is _Loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.open_in_new),
              label: Text('Pay \$$_amount'),
              onPressed: _state is _Loading ? null : _openCheckout,
            ),
            const SizedBox(height: 24),
            _ResultView(state: _state),
          ],
        ),
      ),
    );
  }
}

sealed class _DemoState {
  const _DemoState();
}

class _Idle extends _DemoState {
  const _Idle();
}

class _Loading extends _DemoState {
  const _Loading();
}

class _Success extends _DemoState {
  const _Success(this.result);
  final CardTransactionResult result;
}

class _Failure extends _DemoState {
  const _Failure(this.message);
  final String message;
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.state});

  final _DemoState state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      _Idle() || _Loading() => const SizedBox.shrink(),
      _Success(:final result) => _SuccessCard(result: result),
      _Failure(:final message) => _ErrorCard(message: message),
    };
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.result});

  final CardTransactionResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ready to pay',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Field('Payment method', result.paymentMethodId),
          _Field('Card (last 4)', result.token.lastFourDigits),
          _Field(
            'Installments',
            '${result.installments}x '
                '${result.payerCost.installmentAmount.toStringAsFixed(2)}',
          ),
          _Field('Total', result.transactionAmount.toStringAsFixed(2)),
          const Divider(height: 24),
          Text(
            '→ Send result.token.token + result.installments + '
            'result.transactionAmount to your backend to create the payment.',
            style: TextStyle(fontSize: 12, color: Colors.green.shade700),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
