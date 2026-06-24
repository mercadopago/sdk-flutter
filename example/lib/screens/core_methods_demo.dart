import 'package:flutter/material.dart';
import 'package:mercadopago_flutter_sdk/mercadopago_flutter_sdk.dart';

/// Demonstrates CoreMethods with PCI-compliant input widgets.
///
/// In this path the app owns the entire form UI. The SDK's PCI widgets
/// ([CardNumberField], [SecurityCodeField], [ExpirationDateField]) hold the
/// sensitive values in memory and forward them directly to the tokenization
/// endpoint — the app code never reads the raw card number or CVV.
///
/// On success the app receives an opaque [CardToken]. Send it to your backend
/// to create a payment — never store or display the raw token string.
class CoreMethodsDemo extends StatefulWidget {
  const CoreMethodsDemo({super.key});

  @override
  State<CoreMethodsDemo> createState() => _CoreMethodsDemoState();
}

class _CoreMethodsDemoState extends State<CoreMethodsDemo> {
  // PCI field controllers — raw values are never accessible to this screen.
  final _number = PciFieldState();
  final _cvv = PciFieldState();
  final _exp = PciFieldState();

  // Non-sensitive fields use regular controllers.
  final _nameCtrl = TextEditingController();

  bool _busy = false;
  CardToken? _token;
  String? _error;

  @override
  void dispose() {
    _number.dispose();
    _cvv.dispose();
    _exp.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _formReady =>
      _number.length >= 13 &&
      _cvv.length >= 3 &&
      _exp.length == 4 &&
      _nameCtrl.text.trim().isNotEmpty;

  Future<void> _tokenize() async {
    if (_busy) return;

    // Show inline errors for empty fields before hitting the API.
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter the cardholder name.');
      return;
    }
    if (!_formReady) {
      setState(() => _error = 'Please fill in all card fields.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _token = null;
    });

    final result =
        await MercadoPagoSDK.shared.coreMethods.createTokenForNewCard(
      cardNumber: _number,
      securityCode: _cvv,
      expirationDate: _exp,
      cardholderName: _nameCtrl.text.trim(),
    );

    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        setState(() {
          _busy = false;
          _token = data;
        });
      case Failure(:final error):
        setState(() {
          _busy = false;
          _error = _humanize(error);
        });
      case Cancelled():
        // CoreMethods never emits Cancelled — required for exhaustive switch.
        setState(() => _busy = false);
    }
  }

  String _humanize(MercadoPagoError error) => switch (error) {
        InvalidCardNumberError() => 'Invalid card number.',
        InvalidCvvError() => 'Invalid security code.',
        InvalidExpirationDateError() => 'Invalid expiration date.',
        CardExpiredError() => 'This card has expired.',
        NetworkError(:final message, :final isRetriable) =>
          '${isRetriable ? 'Network error (retryable)' : 'Network error'}: $message',
        ValidationError(:final message) => message,
        _ => 'Unexpected error. Please try again.',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Core Methods')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Use the SDK\'s PCI widgets to build your own form. '
            'The SDK reads the card data internally — your code never '
            'touches the raw number or CVV.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // ── PCI fields ──────────────────────────────────────────────────
          CardNumberField(controller: _number, autofocus: true),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: ExpirationDateField(controller: _exp)),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: SecurityCodeField(controller: _cvv),
              ),
            ],
          ),

          // ── Non-sensitive fields ─────────────────────────────────────────
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Cardholder name',
              hintText: 'As shown on the card',
            ),
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
          ),

          // ── Action ──────────────────────────────────────────────────────
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _tokenize,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Tokenize card'),
          ),

          // ── Result ──────────────────────────────────────────────────────
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
          if (_token != null) ...[
            const SizedBox(height: 16),
            Container(
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
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tokenized successfully',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Field('Payment method', _token!.bin),
                  _Field('Last 4 digits', _token!.lastFourDigits),
                  _Field(
                    'Expires',
                    '${_token!.expirationMonth}/${_token!.expirationYear}',
                  ),
                  const Divider(height: 24),
                  Text(
                    '→ Send token.token to your backend to create a payment.\n'
                    'Do NOT log or store the token on device — it expires '
                    'in ~15 minutes.',
                    style:
                        TextStyle(fontSize: 12, color: Colors.green.shade700),
                  ),
                ],
              ),
            ),
          ],
        ],
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
