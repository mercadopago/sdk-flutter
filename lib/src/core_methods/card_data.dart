/// Plain-data inputs for [CoreMethods.createToken].
///
/// These exist so callers do not depend on internal domain types from
/// `lib/src/domain/repositories.dart`. They are intentionally simple — all
/// validation happens inside [CoreMethods] before the request is sent.
class NewCardData {
  const NewCardData({
    required this.cardNumber,
    required this.cardholderName,
    required this.expirationMonth,
    required this.expirationYear,
    required this.securityCode,
    this.documentType,
    this.documentNumber,
  });

  final String cardNumber;
  final String cardholderName;
  final int expirationMonth;
  final int expirationYear;
  final String securityCode;
  final String? documentType;
  final String? documentNumber;
}

class SavedCardData {
  const SavedCardData({
    required this.cardId,
    required this.securityCode,
    this.expirationMonth,
    this.expirationYear,
  });

  final String cardId;
  final String securityCode;
  final int? expirationMonth;
  final int? expirationYear;
}
