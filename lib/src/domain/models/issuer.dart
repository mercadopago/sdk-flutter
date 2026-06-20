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

  final String id;
  final String name;
  final String thumbnail;
  final String secureThumbnail;
  final String processingMode;
  final String status;
}
