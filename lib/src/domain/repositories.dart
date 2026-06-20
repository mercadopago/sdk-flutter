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
