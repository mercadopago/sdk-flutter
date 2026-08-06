import 'card_form_config.dart';

/// A single installment option ("cuota") returned by the aggregated
/// `card_payment_brick/card` endpoint.
///
/// This is the checkout/BFF shape (flat, presentation-oriented) and is
/// deliberately distinct from the richer CoreMethods `PayerCost` model — the
/// BFF returns only these fields, so modelling them 1:1 avoids fabricating
/// data the server never sent.
class CheckoutInstallment {
  const CheckoutInstallment({
    required this.installments,
    required this.installmentAmount,
    required this.totalAmount,
    required this.primaryLabel,
    required this.secondaryLabel,
    this.tertiaryLabel,
    this.selected = false,
  });

  /// Number of payments (e.g. 1, 3, 6, 12).
  final int installments;

  /// Amount paid per installment.
  final double installmentAmount;

  /// Total amount after interest.
  final double totalAmount;

  /// Server-rendered primary line (e.g. `"3x $500"`).
  final String primaryLabel;

  /// Server-rendered secondary line (e.g. `"Total $1,500"`).
  final String secondaryLabel;

  /// Optional server-rendered tertiary line.
  final String? tertiaryLabel;

  /// Whether the server marks this option as pre-selected.
  final bool selected;
}

/// Issuing bank as returned inside a `card_payment_brick/card` payment method
/// (the BFF returns only `id` and `name`).
class CheckoutIssuer {
  const CheckoutIssuer({required this.id, required this.name});

  final String id;
  final String name;
}

/// A payment method matched for a BIN by `card_payment_brick/card`.
class CardBinMethod {
  const CardBinMethod({
    required this.id,
    required this.paymentTypeId,
    this.securityCode,
    this.issuers = const [],
  });

  /// Payment method identifier (e.g. `"visa"`).
  final String id;

  /// Payment type category (e.g. `"credit_card"`, `"debit_card"`).
  final String paymentTypeId;

  /// CVV configuration for this method. `null` means no security code is
  /// required (the native SDKs drive "is CVV mandatory" off this being
  /// present).
  final SecurityCodeSpec? securityCode;

  final List<CheckoutIssuer> issuers;
}

/// Aggregated result of `card_payment_brick/card`: the payment methods matched
/// for a BIN (with their issuers and CVV config) plus the installment options,
/// in a single round-trip.
class CardBinData {
  const CardBinData({
    required this.paymentMethods,
    this.installments = const [],
    this.translations,
    this.selectionType,
  });

  final List<CardBinMethod> paymentMethods;
  final List<CheckoutInstallment> installments;

  /// How installments are presented (`"chevron"` / `"radio_button"`); reported
  /// in the installments/initialize analytics track. `null` when absent.
  final String? selectionType;

  /// Refined translations for this BIN (BFF may override the initialization
  /// ones, e.g. the card-number mask); `null` when not present.
  final CardFormTranslations? translations;
}
