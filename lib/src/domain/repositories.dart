import 'models/card_bin_data.dart';
import 'models/card_form_config.dart';
import 'models/card_token.dart';
import 'models/device_data.dart';
import 'models/identification_type.dart';
import 'models/installment.dart';
import 'models/issuer.dart';
import 'models/order_process_result.dart';
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
    this.minInstallments,
    this.maxInstallments,
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

  /// Minimum installments to offer (`min_installments` query); `null` omits it.
  final int? minInstallments;

  /// Maximum installments to offer (`max_installments` query); `null` omits it.
  final int? maxInstallments;
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

/// Parameters for processing an order (`POST /orders/{orderId}/process`).
class OrderProcessParams {
  const OrderProcessParams({
    required this.orderId,
    required this.clientToken,
    required this.paymentMethodId,
    required this.paymentTypeId,
    required this.token,
    required this.installments,
    required this.amount,
  });

  final String orderId;

  /// Short-lived client token; sent as `Authorization: Bearer`.
  final String clientToken;
  final String paymentMethodId;

  /// Encoded on the wire under `payment_method_type` (native quirk).
  final String paymentTypeId;

  /// The card token from tokenization.
  final String token;
  final int installments;

  /// Sent as a 2-decimal string.
  final double amount;
}

/// Processes a hosted-checkout order after tokenization + installment
/// selection, backed by `POST /cho-off/v1/orders/{orderId}/process`
/// (`X-Public-Key` header + `Authorization: Bearer <clientToken>`).
abstract interface class OrderRepository {
  Future<OrderProcessResult> process(OrderProcessParams params);
}
