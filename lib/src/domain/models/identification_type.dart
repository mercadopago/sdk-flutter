/// A document type accepted in a given country (e.g. DNI, CPF, RUT).
class IdentificationType {
  const IdentificationType({
    required this.id,
    required this.name,
    required this.type,
    required this.minLength,
    required this.maxLength,
  });

  /// Identifier used in the tokenization request (e.g. `"DNI"`, `"CPF"`).
  final String id;

  /// Human-readable label displayed to the cardholder.
  final String name;

  /// Input type hint: `"number"` for numeric-only documents, `"string"` for
  /// alphanumeric.
  final String type;

  /// Minimum number of characters a valid document number must have.
  final int minLength;

  /// Maximum number of characters a valid document number may have.
  final int maxLength;
}
