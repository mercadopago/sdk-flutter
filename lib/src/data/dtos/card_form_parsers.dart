/// Shared JSON parsers for the hosted-checkout BFF card-form responses
/// (`card_payment_brick/initialization` and `.../card`), which share the field
/// spec, security-code and translations shapes.
library;

import '../../domain/models/card_form_config.dart';

/// Parses a `{ type, length: {min, max}, mask? }` field spec.
CardFieldSpec parseCardFieldSpec(Map<String, dynamic> json) {
  final length = json['length'];
  var min = 0;
  var max = 0;
  if (length is Map) {
    min = (length['min'] as num?)?.toInt() ?? 0;
    max = (length['max'] as num?)?.toInt() ?? 0;
  }
  return CardFieldSpec(
    type: json['type'] as String? ?? '',
    minLength: min,
    maxLength: max,
    mask: json['mask'] as String?,
  );
}

/// Parses a security-code spec. `length` is a single int here (not min/max),
/// but tolerates a `{min,max}` object just in case.
SecurityCodeSpec parseSecurityCode(Map<String, dynamic> json) {
  final len = json['length'];
  final length = switch (len) {
    final num n => n.toInt(),
    final Map<String, dynamic> m => (m['max'] as num?)?.toInt() ?? 0,
    _ => 0,
  };
  return SecurityCodeSpec(
    type: json['type'] as String? ?? '',
    length: length,
    cardLocation: json['card_location'] as String?,
    tooltip: json['tooltip'] as String?,
    placeholder: json['placeholder'] as String?,
  );
}

/// Parses a per-field translation block.
FieldTranslation parseFieldTranslation(Map<String, dynamic> json) =>
    FieldTranslation(
      label: json['label'] as String? ?? '',
      placeholder: json['placeholder'] as String?,
      helper: json['helper'] as String?,
      tooltip: json['tooltip'] as String?,
      errorEmptyField: json['error_empty_field'] as String?,
      errorIncompleteField: json['error_incomplete_field'] as String?,
      errorInvalidField: json['error_invalid_field'] as String?,
    );

/// Parses the full `translations` object; returns `null` when absent (the
/// `card` response may omit it).
CardFormTranslations? parseTranslations(Map<String, dynamic>? json) {
  if (json == null) return null;
  Map<String, dynamic> obj(String key) =>
      (json[key] as Map<String, dynamic>?) ?? const {};
  final installments = obj('installments');
  final header = (installments['header'] as Map<String, dynamic>?) ?? const {};
  return CardFormTranslations(
    title: json['card_form_title'] as String? ?? '',
    footerButtonLabel: json['card_form_footer_button_label'] as String? ?? '',
    currencySymbol: json['currency_symbol'] as String? ?? '',
    cardNumber: parseFieldTranslation(obj('card_number')),
    holderName: parseFieldTranslation(obj('holder_name')),
    expirationDate: parseFieldTranslation(obj('expiration_date')),
    securityCode: parseFieldTranslation(obj('security_code')),
    document: parseFieldTranslation(obj('document')),
    installmentsHeaderTitle: header['title'] as String?,
    installmentsTotalLabel: installments['total_label'] as String?,
    installmentsPayButtonLabel: installments['pay_button_label'] as String?,
  );
}

/// Neutral translations used when the server omits the block entirely, so the
/// form still renders (with empty labels) rather than crashing.
const CardFormTranslations emptyCardFormTranslations = CardFormTranslations(
  title: '',
  footerButtonLabel: '',
  currencySymbol: '',
  cardNumber: FieldTranslation(label: ''),
  holderName: FieldTranslation(label: ''),
  expirationDate: FieldTranslation(label: ''),
  securityCode: FieldTranslation(label: ''),
  document: FieldTranslation(label: ''),
);
