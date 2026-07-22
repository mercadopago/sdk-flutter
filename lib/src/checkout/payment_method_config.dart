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
