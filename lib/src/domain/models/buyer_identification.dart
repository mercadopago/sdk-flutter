/// Cardholder identity supplied when tokenizing a new card.
///
/// Groups the cardholder's name with an optional identification document
/// (type + number), mirroring the native Android `BuyerIdentification`. Using a
/// typed model keeps the tokenization signature stable if new market-specific
/// fields are added later.
class BuyerIdentification {
  const BuyerIdentification({
    required this.name,
    this.number,
    this.type,
  });

  /// Cardholder's full name (required).
  final String name;

  /// Identification document number (e.g. the CPF/DNI digits). Optional.
  final String? number;

  /// Identification document type (e.g. `"CPF"`, `"DNI"`). Optional.
  final String? type;
}
