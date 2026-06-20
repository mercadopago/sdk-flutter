/// Token returned by the MercadoPago tokenization endpoint.
///
/// The [token] field is the only value the integrator's backend needs to
/// create a payment. The token expires approximately 15 minutes after
/// creation and must not be persisted by the SDK consumer.
class CardToken {
  const CardToken({
    required this.token,
    required this.bin,
    required this.lastFourDigits,
    required this.cardholderName,
    required this.firstSixDigits,
    required this.expirationMonth,
    required this.expirationYear,
    required this.status,
    required this.dateCreated,
    required this.dateDue,
    required this.luhnValidation,
    required this.liveMode,
    required this.requireEsc,
    required this.cardNumberLength,
    required this.securityCodeLength,
  });

  /// Opaque identifier representing the tokenized card. Send to your backend
  /// to create a payment.
  final String token;

  /// First 6 digits of the card number (the issuer identification number).
  final String bin;

  /// First 6 digits — alias kept for compatibility with the documented API
  /// shape.
  final String firstSixDigits;

  /// Last 4 digits of the card number, safe to display.
  final String lastFourDigits;

  final String cardholderName;
  final int expirationMonth;
  final int expirationYear;
  final String status;
  final DateTime dateCreated;
  final DateTime dateDue;
  final bool luhnValidation;
  final bool liveMode;
  final bool requireEsc;
  final int cardNumberLength;
  final int securityCodeLength;
}
