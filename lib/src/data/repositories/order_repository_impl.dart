import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../domain/models/order_process_result.dart';
import '../../domain/repositories.dart';
import '../dtos/order_process_dto.dart';

/// Processes a hosted-checkout order via
/// `POST /cho-off/v1/orders/{orderId}/process`.
///
/// Authenticates with the `X-Public-Key` header ([AuthMode.publicKeyHeader])
/// plus an `Authorization: Bearer <clientToken>` header — the contract
/// confirmed against the native Android/iOS `OrderService`/`OrderTransactionEndpoint`.
class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this._api);

  static const String _base = '/cho-off/v1/orders';

  final ApiClient _api;

  @override
  Future<OrderProcessResult> process(OrderProcessParams params) async {
    final json = await _api.post(
      '$_base/${params.orderId}/process',
      body: OrderProcessDto.toRequestBody(params),
      authMode: AuthMode.publicKeyHeader,
      extraHeaders: {kHeaderAuthorization: 'Bearer ${params.clientToken}'},
    );
    return OrderProcessDto.parse(json);
  }
}
