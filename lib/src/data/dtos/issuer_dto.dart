import '../../domain/models/issuer.dart';
import 'json_value.dart';

class IssuerDto {
  const IssuerDto({
    required this.id,
    required this.name,
    required this.thumbnail,
    required this.secureThumbnail,
    required this.processingMode,
    required this.status,
    required this.merchantAccountId,
  });

  /// Parses a `/cho-off/v1/card_issuers` entry.
  ///
  /// Contract (Android `CardIssuerResponse.kt` — every field nullable, no
  /// `name`; iOS `IssuersResponse.swift` — no `secure_thumbnail`): only `id`
  /// is dependable, so it is the one field kept fail-closed. `secure_thumbnail`
  /// does not exist in either native contract and must never be required.
  factory IssuerDto.fromJson(Map<String, dynamic> json) => IssuerDto(
    id: requiredString(json, 'id'),
    name: optionalString(json, 'name') ?? '',
    thumbnail: optionalStringOrNullWhenBlank(json, 'thumbnail') ?? '',
    secureThumbnail:
        optionalStringOrNullWhenBlank(json, 'secure_thumbnail') ?? '',
    processingMode: optionalString(json, 'processing_mode') ?? '',
    status: optionalString(json, 'status') ?? '',
    merchantAccountId: optionalStringOrNullWhenBlank(
      json,
      'merchant_account_id',
    ),
  );

  final String id;
  final String name;
  final String thumbnail;
  final String secureThumbnail;
  final String processingMode;
  final String status;
  final String? merchantAccountId;

  Issuer toDomain() => Issuer(
    id: id,
    name: name,
    thumbnail: thumbnail,
    secureThumbnail: secureThumbnail,
    processingMode: processingMode,
    status: status,
    merchantAccountId: merchantAccountId,
  );
}
