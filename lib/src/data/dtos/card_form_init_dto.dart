import '../../domain/models/card_form_config.dart';
import 'card_form_parsers.dart';
import 'identification_type_dto.dart';

/// Parses the `card_payment_brick/initialization` response into a
/// [CardFormConfig].
abstract final class CardFormInitDto {
  static CardFormConfig parse(Map<String, dynamic> json) {
    final idTypes = (json['identification_types'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(IdentificationTypeDto.fromJson)
        .map((dto) => dto.toDomain())
        .toList(growable: false);

    Map<String, dynamic> obj(String key) =>
        (json[key] as Map<String, dynamic>?) ?? const {};

    return CardFormConfig(
      cardNumber: parseCardFieldSpec(obj('card_number')),
      securityCode: parseSecurityCode(obj('security_code')),
      holderName: parseCardFieldSpec(obj('holder_name')),
      expirationDate: parseCardFieldSpec(obj('expiration_date')),
      identificationTypes: idTypes,
      translations: parseTranslations(json['translations'] as Map<String, dynamic>?) ??
          emptyCardFormTranslations,
      amount: (json['amount'] as num?)?.toDouble(),
    );
  }
}
