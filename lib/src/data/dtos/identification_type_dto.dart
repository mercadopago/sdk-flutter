import '../../domain/models/identification_type.dart';

class IdentificationTypeDto {
  const IdentificationTypeDto({
    required this.id,
    required this.name,
    required this.type,
    required this.minLength,
    required this.maxLength,
  });

  factory IdentificationTypeDto.fromJson(Map<String, dynamic> json) =>
      IdentificationTypeDto(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? 'number',
        minLength: (json['min_length'] as num?)?.toInt() ?? 1,
        maxLength: (json['max_length'] as num?)?.toInt() ?? 20,
      );

  final String id;
  final String name;
  final String type;
  final int minLength;
  final int maxLength;

  IdentificationType toDomain() => IdentificationType(
        id: id,
        name: name,
        type: type,
        minLength: minLength,
        maxLength: maxLength,
      );
}
