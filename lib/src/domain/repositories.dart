import 'models/card_bin_data.dart';
import 'models/card_form_config.dart';
import 'models/card_token.dart';
import 'models/device_data.dart';
import 'models/identification_type.dart';
import 'models/installment.dart';
import 'models/issuer.dart';
import 'models/payment_method.dart';

/// Input describing a brand-new card to tokenize.
class NewCardInput {
  const NewCardInput({
    required this.cardNumber,
    required this.cardholderName,
    required this.expirationMonth,
    required this.expirationYear,
    required this.securityCode,
    this.documentType,
    this.documentNumber,
  });

  final String cardNumber;
  final String cardholderName;
  final int expirationMonth;
  final int expirationYear;
  final String securityCode;
  final String? documentType;
  final String? documentNumber;
}

/// Input describing a previously-saved card to be re-tokenized.
class SavedCardInput {
  const SavedCardInput({
    required this.cardId,
    required this.securityCode,
    this.expirationMonth,
    this.expirationYear,
  });

  final String cardId;
  final String securityCode;
  final int? expirationMonth;
  final int? expirationYear;
}

/// Processing mode for installment calculations.
enum ProcessingMode {
  aggregator('aggregator'),
  gateway('gateway');

  const ProcessingMode(this.value);
  final String value;
}

abstract interface class TokenRepository {
  Future<CardToken> createTokenForNewCard(
    NewCardInput input,
    DeviceData device,
  );

  Future<CardToken> createTokenForSavedCard(
    SavedCardInput input,
    DeviceData device,
  );
}

abstract interface class PaymentMethodRepository {
  Future<List<PaymentMethod>> getByBin(String bin);
}

abstract interface class InstallmentRepository {
  Future<List<Installment>> get({
    required String bin,
    required double amount,
    required ProcessingMode mode,
  });
}

abstract interface class IssuerRepository {
  Future<List<Issuer>> get({
    required String paymentMethodId,
    required String bin,
  });
}

abstract interface class IdentificationRepository {
  Future<List<IdentificationType>> getAll();
}

/// Checkout type sent to the hosted-checkout BFF. String values match the
/// native Android SDK (`card_save` / `card_transaction`).
enum CheckoutType {
  cardSave('card_save'),
  cardTransaction('card_transaction');

  const CheckoutType(this.value);
  final String value;
}

/// Parameters for the `card_payment_brick/initialization` call.
class CardFormInitParams {
  const CardFormInitParams({
    required this.checkoutType,
    this.orderId,
    this.clientToken,
  });

  final CheckoutType checkoutType;

  /// Order identifier (card transactions bound to an order); `null` otherwise.
  final String? orderId;

  /// Short-lived client token sent as `Authorization: Bearer`; `null` when the
  /// caller only has a public key.
  final String? clientToken;
}

/// Parameters for the aggregated `card_payment_brick/card` BIN lookup.
class CardBinParams {
  const CardBinParams({
    required this.bin,
    required this.checkoutType,
    required this.amount,
    this.excludedPaymentTypes = const [],
    this.excludedPaymentMethods = const [],
  });

  final String bin;
  final CheckoutType checkoutType;
  final double amount;

  /// Payment type ids to exclude (e.g. `credit_card`), comma-joined on the
  /// wire as `excluded_payment_types`.
  final List<String> excludedPaymentTypes;

  /// Payment method/brand ids to exclude (e.g. `visa`), comma-joined on the
  /// wire as `excluded_payment_methods`.
  final List<String> excludedPaymentMethods;
}

/// Hosted-checkout server-driven card form. Backed by the two
/// `card_payment_brick` BFF endpoints (`initialization` + `card`), which
/// authenticate with the `X-Public-Key` header and `product_id` query param.
abstract interface class CardFormRepository {
  /// Loads field configs, translations, document types and (for card
  /// transactions) the order amount.
  Future<CardFormConfig> initialize(CardFormInitParams params);

  /// Aggregated BIN lookup: payment methods (+ issuers, CVV config) and
  /// installment options in a single call.
  Future<CardBinData> getCardBin(CardBinParams params);
}
