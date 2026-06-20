import 'card_token.dart';

/// Result returned by the CardSave checkout flow.
class CardSaveResult {
  const CardSaveResult({
    required this.token,
    required this.paymentMethodId,
    required this.paymentTypeId,
    required this.issuerId,
    this.cardId,
  });

  final CardToken token;
  final String paymentMethodId;
  final String paymentTypeId;
  final String issuerId;

  /// Populated when the card was already saved on the customer's account.
  final String? cardId;
}
