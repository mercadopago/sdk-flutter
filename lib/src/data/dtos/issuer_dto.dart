import '../../domain/models/issuer.dart';

class IssuerDto {
  const IssuerDto({
    required this.id,
    required this.name,
    required this.thumbnail,
    required this.secureThumbnail,
    required this.processingMode,
    required this.status,
  });

  factory IssuerDto.fromJson(Map<String, dynamic> json) => IssuerDto(
        id: (json['id'] ?? '').toString(),
        name: json['name'] as String? ?? '',
        thumbnail: json['thumbnail'] as String? ?? '',
        secureThumbnail: json['secure_thumbnail'] as String? ?? '',
        processingMode: json['processing_mode'] as String? ?? 'aggregator',
        status: json['status'] as String? ?? 'active',
      );

  final String id;
  final String name;
  final String thumbnail;
  final String secureThumbnail;
  final String processingMode;
  final String status;

  Issuer toDomain() => Issuer(
        id: id,
        name: name,
        thumbnail: thumbnail,
        secureThumbnail: secureThumbnail,
        processingMode: processingMode,
        status: status,
      );
}
