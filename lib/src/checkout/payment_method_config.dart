import 'mp_installment.dart';

/// Per-payment-method configuration for the hosted checkout.
///
/// A sealed hierarchy mirroring the native Android sealed class / iOS enum
/// `MPPaymentMethodConfig`. Only the card configuration exists today; the
/// sealed shape lets new payment-method configs be added later without
/// breaking the [MercadoPagoCheckout] builder signatures.
///
/// Pass a list to `setPaymentMethodConfiguration` on a checkout builder:
/// ```dart
/// MercadoPagoCheckout.forCardSave(onResult: ...)
///     .setPaymentMethodConfiguration([
///       MPPaymentMethodConfig.card(
///         excludedTypes: [MPCardType.debit],
///         installment: MPInstallment(maxInstallments: 3),
///       ),
///     ])
///     .build();
/// ```
sealed class MPPaymentMethodConfig {
  const MPPaymentMethodConfig();

  /// Card configuration: excluded types/brands and the installment range.
  const factory MPPaymentMethodConfig.card({
    List<MPCardType> excludedTypes,
    List<MPCardBrand> excludedBrands,
    MPInstallment? installment,
  }) = MPCardConfig;
}

/// Card-specific checkout configuration.
final class MPCardConfig extends MPPaymentMethodConfig {
  const MPCardConfig({
    this.excludedTypes = const [],
    this.excludedBrands = const [],
    this.installment = const MPInstallment(),
  });

  /// Card types (credit/debit/prepaid) to hide from the checkout.
  final List<MPCardType> excludedTypes;

  /// Card brands (visa/master/…) to hide from the checkout.
  final List<MPCardBrand> excludedBrands;

  /// Installment range to offer; `null` leaves it fully server-driven.
  final MPInstallment? installment;

  /// Returns the (single) card configuration from [configs], or a default
  /// [MPCardConfig] when none is present — mirroring the native SDKs, where the
  /// card form reads the `.card` config from the payment-method-config list.
  static MPCardConfig from(List<MPPaymentMethodConfig> configs) {
    for (final config in configs) {
      if (config is MPCardConfig) return config;
    }
    return const MPCardConfig();
  }
}

/// Card payment types a seller can exclude from the hosted checkout.
///
/// Serialized (comma-joined) to the `excluded_payment_types` query param of
/// the `card_payment_brick/card` BFF call. Values match the native Android/iOS
/// SDKs.
enum MPCardType {
  credit('credit_card'),
  debit('debit_card'),
  prepaid('prepaid_card');

  const MPCardType(this.value);

  /// Wire value sent to the BFF.
  final String value;
}

/// Card brands a seller can exclude from the hosted checkout.
///
/// The well-known brands mirror the native SDKs; use [MPCardBrand.custom] for
/// any brand id not listed here. Serialized (comma-joined) to the
/// `excluded_payment_methods` query param of the `card_payment_brick/card`
/// BFF call.
class MPCardBrand {
  const MPCardBrand._(this.value);

  /// Arbitrary brand id not covered by the built-in constants.
  const MPCardBrand.custom(this.value);

  /// Wire value sent to the BFF (e.g. `"visa"`).
  final String value;

  static const MPCardBrand visa = MPCardBrand._('visa');
  static const MPCardBrand master = MPCardBrand._('master');
  static const MPCardBrand amex = MPCardBrand._('amex');
  static const MPCardBrand elo = MPCardBrand._('elo');
  static const MPCardBrand hipercard = MPCardBrand._('hipercard');
  static const MPCardBrand diners = MPCardBrand._('diners');
  static const MPCardBrand discover = MPCardBrand._('discover');
  static const MPCardBrand jcb = MPCardBrand._('jcb');
  static const MPCardBrand maestro = MPCardBrand._('maestro');
  static const MPCardBrand unionpay = MPCardBrand._('unionpay');
  static const MPCardBrand cabal = MPCardBrand._('cabal');
  static const MPCardBrand naranja = MPCardBrand._('naranja');

  @override
  bool operator ==(Object other) =>
      other is MPCardBrand && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
