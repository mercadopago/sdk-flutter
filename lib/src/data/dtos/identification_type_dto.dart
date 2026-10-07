import '../../domain/models/identification_type.dart';
import 'json_value.dart';

class IdentificationTypeDto {
  const IdentificationTypeDto({
    required this.id,
    required this.name,
    required this.type,
    required this.minLength,
    required this.maxLength,
  });

  factory IdentificationTypeDto.fromJson(Map<String, dynamic> json) {
    final minLength = requiredInt(json, 'min_length');
    final maxLength = requiredInt(json, 'max_length');
    if (minLength <= 0 || maxLength < minLength) {
      throw const FormatException(
        'Response identification lengths must define a positive range.',
      );
    }
    return IdentificationTypeDto(
      id: requiredString(json, 'id'),
      name: requiredString(json, 'name'),
      type: requiredString(json, 'type'),
      minLength: minLength,
      maxLength: maxLength,
    );
  }

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
