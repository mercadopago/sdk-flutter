import '../../core/api_client.dart';
import '../../domain/models/identification_type.dart';
import '../../domain/repositories.dart';
import '../dtos/identification_type_dto.dart';

class IdentificationRepositoryImpl implements IdentificationRepository {
  IdentificationRepositoryImpl(this._api);

  static const String _path = '/cho-off/v1/identification_types';

  final ApiClient _api;

  @override
  Future<List<IdentificationType>> getAll() async {
    final list = await _api.getList(_path);
    return list
        .whereType<Map<String, dynamic>>()
        .map(IdentificationTypeDto.fromJson)
        .map((dto) => dto.toDomain())
        .toList(growable: false);
  }
}
