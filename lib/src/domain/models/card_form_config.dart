import 'identification_type.dart';

/// Input spec for a single card-form field, as returned by the hosted-checkout
/// BFF `card_payment_brick/initialization` endpoint.
class CardFieldSpec {
  const CardFieldSpec({
    required this.type,
    required this.minLength,
    required this.maxLength,
    this.mask,
  });

  /// Input type hint (e.g. `"number"`, `"string"`).
  final String type;

  /// Minimum accepted length.
  final int minLength;

  /// Maximum accepted length.
  final int maxLength;

  /// Display mask (e.g. `"MM/YY"`, `"$$$$ $$$$ $$$$ $$$$"`), when provided.
  final String? mask;
}

/// Security-code (CVV) spec.
class SecurityCodeSpec {
  const SecurityCodeSpec({
    required this.type,
    required this.length,
    this.cardLocation,
    this.tooltip,
    this.placeholder,
  });

  final String type;

  /// Expected number of digits (single value, not a min/max range).
  final int length;

  /// Where the code is printed: `"back"` or `"front"`.
  final String? cardLocation;

  final String? tooltip;
  final String? placeholder;
}

/// Localized, server-driven strings for a single field.
class FieldTranslation {
  const FieldTranslation({
    required this.label,
    this.placeholder,
    this.helper,
    this.tooltip,
    this.errorEmptyField,
    this.errorIncompleteField,
    this.errorInvalidField,
  });

  final String label;
  final String? placeholder;
  final String? helper;
  final String? tooltip;
  final String? errorEmptyField;
  final String? errorIncompleteField;
  final String? errorInvalidField;
}

/// All localized strings for the card form.
class CardFormTranslations {
  const CardFormTranslations({
    required this.title,
    required this.footerButtonLabel,
    required this.currencySymbol,
    required this.cardNumber,
    required this.holderName,
    required this.expirationDate,
    required this.securityCode,
    required this.document,
    this.installmentsHeaderTitle,
    this.installmentsTotalLabel,
    this.installmentsPayButtonLabel,
  });

  final String title;
  final String footerButtonLabel;
  final String currencySymbol;
  final FieldTranslation cardNumber;
  final FieldTranslation holderName;
  final FieldTranslation expirationDate;
  final FieldTranslation securityCode;
  final FieldTranslation document;
  final String? installmentsHeaderTitle;
  final String? installmentsTotalLabel;
  final String? installmentsPayButtonLabel;
}

/// Complete server-driven configuration for the card form, returned by
/// `card_payment_brick/initialization`. Drives field lengths/masks, document
/// types, localized labels and (for card transactions) the order amount — so
/// none of these are hardcoded client-side.
class CardFormConfig {
  const CardFormConfig({
    required this.cardNumber,
    required this.securityCode,
    required this.holderName,
    required this.expirationDate,
    required this.identificationTypes,
    required this.translations,
    this.amount,
  });

  final CardFieldSpec cardNumber;
  final SecurityCodeSpec securityCode;
  final CardFieldSpec holderName;
  final CardFieldSpec expirationDate;
  final List<IdentificationType> identificationTypes;
  final CardFormTranslations translations;

  /// Order amount resolved server-side (card transactions); `null` for card
  /// save flows.
  final double? amount;
}
