import '../../core/api_client.dart';
import '../../domain/models/payment_method.dart';
import '../../domain/repositories.dart';
import '../dtos/payment_method_dto.dart';

class PaymentMethodRepositoryImpl implements PaymentMethodRepository {
  PaymentMethodRepositoryImpl(this._api);

  static const String _path = '/cho-off/v1/payment_methods';

  final ApiClient _api;

  @override
  Future<List<PaymentMethod>> getByBin(String bin) async {
    final list = await _api.getList(
      _path,
      queryParameters: {
        'bin': bin,
        'processing_mode': ProcessingMode.aggregator.value,
      },
    );
    return list
        .whereType<Map<String, dynamic>>()
        .map(PaymentMethodDto.fromJson)
        .map((dto) => dto.toDomain())
        .toList(growable: false);
  }
}
