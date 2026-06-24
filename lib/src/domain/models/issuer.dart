/// Card issuing bank (e.g. "Banco Santander").
class Issuer {
  const Issuer({
    required this.id,
    required this.name,
    required this.thumbnail,
    required this.secureThumbnail,
    required this.processingMode,
    required this.status,
  });

  /// Unique identifier for this issuer as expected by the payments API.
  final String id;

  /// Human-readable bank name.
  final String name;

  /// URL of the bank logo (standard resolution).
  final String thumbnail;

  /// URL of the bank logo (served over HTTPS).
  final String secureThumbnail;

  /// Processing model used by this issuer: `"aggregator"` or `"gateway"`.
  final String processingMode;

  /// Whether this issuer is currently available (`"active"` or `"inactive"`).
  final String status;
}
