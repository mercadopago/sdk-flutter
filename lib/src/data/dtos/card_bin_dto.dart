import '../../domain/models/card_bin_data.dart';
import 'card_form_parsers.dart';

/// Parses the aggregated `card_payment_brick/card` response into a
/// [CardBinData].
abstract final class CardBinDto {
  static CardBinData parse(Map<String, dynamic> json) {
    final methods = (json['payment_methods'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_parseMethod)
        .toList(growable: false);

    final installment = json['installment'] as Map<String, dynamic>?;
    final quotas = (installment?['quotas'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_parseQuota)
        .toList(growable: false);

    return CardBinData(
      paymentMethods: methods,
      installments: quotas,
      translations: parseTranslations(json['translations'] as Map<String, dynamic>?),
      selectionType: installment?['selection_type'] as String?,
    );
  }

  static CardBinMethod _parseMethod(Map<String, dynamic> json) {
    final securityCode = json['security_code'];
    return CardBinMethod(
      id: json['id'] as String? ?? '',
      paymentTypeId: json['payment_type_id'] as String? ?? '',
      securityCode: securityCode is Map<String, dynamic>
          ? parseSecurityCode(securityCode)
          : null,
      issuers: (json['issuers'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (i) => CheckoutIssuer(
              id: (i['id'] ?? '').toString(),
              name: i['name'] as String? ?? '',
            ),
          )
          .toList(growable: false),
    );
  }

  static CheckoutInstallment _parseQuota(Map<String, dynamic> json) {
    final state = json['state'] as String?;
    return CheckoutInstallment(
      installments: (json['installments'] as num?)?.toInt() ?? 1,
      installmentAmount: (json['installment_amount'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      primaryLabel: json['primary_label'] as String? ?? '',
      secondaryLabel: json['secondary_label'] as String? ?? '',
      tertiaryLabel: json['tertiary_label'] as String?,
      selected: state == 'success' || state == 'selected',
    );
  }
}
