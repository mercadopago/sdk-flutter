import '../../core/api_client.dart';
import '../../domain/models/installment.dart';
import '../../domain/repositories.dart';
import '../dtos/installment_dto.dart';

class InstallmentRepositoryImpl implements InstallmentRepository {
  InstallmentRepositoryImpl(this._api);

  static const String _path = '/cho-off/v1/installments';

  final ApiClient _api;

  @override
  Future<List<Installment>> get({
    required String bin,
    required double amount,
    required ProcessingMode mode,
  }) async {
    final list = await _api.getList(_path, queryParameters: {
      'bin': bin,
      'amount': amount.toString(),
      'processing_mode': mode.value,
    });
    return list
        .whereType<Map<String, dynamic>>()
        .map(InstallmentDto.fromJson)
        .map((dto) => dto.toDomain())
        .toList(growable: false);
  }
}
