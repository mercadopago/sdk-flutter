import '../../core/api_client.dart';
import '../../domain/models/payment_method.dart';
import '../../domain/repositories.dart';
import '../dtos/json_value.dart';
import '../dtos/payment_method_dto.dart';

class PaymentMethodRepositoryImpl implements PaymentMethodRepository {
  PaymentMethodRepositoryImpl(this._api);

  static const String _path = '/cho-off/v1/payment_methods';

  final ApiClient _api;

  @override
  Future<List<PaymentMethod>> getByBin({
    required String bin,
    required ProcessingMode mode,
  }) async {
    final list = await _api.getList(
      _path,
      queryParameters: {'bin': bin, 'processing_mode': mode.value},
    );
    return mapJsonObjectList(
      list,
      'payment_methods',
      PaymentMethodDto.fromJson,
    ).map((dto) => dto.toDomain()).toList(growable: false);
  }
}
