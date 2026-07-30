import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../domain/models/card_bin_data.dart';
import '../../domain/models/card_form_config.dart';
import '../../domain/repositories.dart';
import '../dtos/card_bin_dto.dart';
import '../dtos/card_form_init_dto.dart';

/// Talks to the hosted-checkout BFF (`/cho-off/v1/card_payment_brick/*`).
///
/// Both endpoints authenticate with the `X-Public-Key` header
/// ([AuthMode.publicKeyHeader]) and carry `product_id` as a query param — the
/// contract confirmed against the native Android/iOS checkout modules. The
/// aggregated `card` call sends `processing_mode=aggregator` (a constant on
/// both native platforms).
class CardFormRepositoryImpl implements CardFormRepository {
  CardFormRepositoryImpl(this._api);

  static const String _initPath =
      '/cho-off/v1/card_payment_brick/initialization';
  static const String _cardPath = '/cho-off/v1/card_payment_brick/card';

  final ApiClient _api;

  @override
  Future<CardFormConfig> initialize(CardFormInitParams params) async {
    final token = params.clientToken;
    final json = await _api.get(
      _initPath,
      authMode: AuthMode.publicKeyHeader,
      cache: false,
      queryParameters: {
        'checkout_type': params.checkoutType.value,
        if (params.orderId != null) 'order_id': params.orderId!,
      },
      extraHeaders:
          token == null ? null : {kHeaderAuthorization: 'Bearer $token'},
    );
    return CardFormInitDto.parse(json);
  }

  @override
  Future<CardBinData> getCardBin(CardBinParams params) async {
    final json = await _api.get(
      _cardPath,
      authMode: AuthMode.publicKeyHeader,
      cache: false,
      queryParameters: {
        'bin': params.bin,
        'checkout_type': params.checkoutType.value,
        'processing_mode': ProcessingMode.aggregator.value,
        'amount': params.amount.toString(),
        if (params.excludedPaymentTypes.isNotEmpty)
          'excluded_payment_types': params.excludedPaymentTypes.join(','),
        if (params.excludedPaymentMethods.isNotEmpty)
          'excluded_payment_methods': params.excludedPaymentMethods.join(','),
        if (params.minInstallments != null)
          'min_installments': params.minInstallments!.toString(),
        if (params.maxInstallments != null)
          'max_installments': params.maxInstallments!.toString(),
      },
    );
    return CardBinDto.parse(json);
  }
}
