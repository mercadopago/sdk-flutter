/// Token returned by the MercadoPago tokenization endpoint.
///
/// The [token] field is the only value the integrator's backend needs to
/// create a payment. Mercado Pago currently documents a maximum lifetime of
/// 7 days; the token also becomes unusable after its first use. Consumers
/// should send it to their backend immediately and must not persist it.
class CardToken {
  const CardToken({
    required this.token,
    this.bin,
    this.lastFourDigits,
    this.cardholderName,
    this.firstSixDigits,
    this.expirationMonth,
    this.expirationYear,
    this.status,
    this.dateCreated,
    this.dateDue,
    this.luhnValidation,
    this.liveMode,
    this.requireEsc,
    this.cardNumberLength,
    this.securityCodeLength,
  });

  /// Opaque identifier representing the tokenized card. Send to your backend
  /// to create a payment.
  final String token;

  /// First 6 digits of the card number (the issuer identification number).
  final String? bin;

  /// First 6 digits — alias kept for compatibility with the documented API
  /// shape.
  final String? firstSixDigits;

  /// Last 4 digits of the card number, safe to display.
  final String? lastFourDigits;

  final String? cardholderName;
  final int? expirationMonth;
  final int? expirationYear;
  final String? status;
  final DateTime? dateCreated;
  final DateTime? dateDue;
  final bool? luhnValidation;
  final bool? liveMode;
  final bool? requireEsc;
  final int? cardNumberLength;
  final int? securityCodeLength;
}
