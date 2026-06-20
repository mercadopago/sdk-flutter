/// A document type accepted in a given country (e.g. DNI, CPF, RUT).
class IdentificationType {
  const IdentificationType({
    required this.id,
    required this.name,
    required this.type,
    required this.minLength,
    required this.maxLength,
  });

  final String id;
  final String name;

  /// `"number"` or `"string"`.
  final String type;

  final int minLength;
  final int maxLength;
}
