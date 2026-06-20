import '../../core/api_client.dart';
import '../../domain/models/issuer.dart';
import '../../domain/repositories.dart';
import '../dtos/issuer_dto.dart';

class IssuerRepositoryImpl implements IssuerRepository {
  IssuerRepositoryImpl(this._api);

  static const String _path = '/cho-off/v1/issuers';

  final ApiClient _api;

  @override
  Future<List<Issuer>> get({
    required String paymentMethodId,
    required String bin,
  }) async {
    final list = await _api.getList(
      _path,
      queryParameters: {
        'payment_method_id': paymentMethodId,
        'bin': bin,
      },
    );
    return list
        .whereType<Map<String, dynamic>>()
        .map(IssuerDto.fromJson)
        .map((dto) => dto.toDomain())
        .toList(growable: false);
  }
}
