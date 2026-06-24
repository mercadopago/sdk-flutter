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

  /// Tokenized card. Forward [CardToken.token] to your backend to create a
  /// payment or save the card for future use.
  final CardToken token;

  /// Payment method identifier (e.g. `"visa"`, `"master"`).
  final String paymentMethodId;

  /// Payment type category (e.g. `"credit_card"`, `"debit_card"`).
  final String paymentTypeId;

  /// Identifier of the card's issuing bank.
  final String issuerId;

  /// Populated when the card was already saved on the customer's account.
  final String? cardId;
}
