import 'models/identification_type.dart';
import 'models/installment.dart';
import 'models/issuer.dart';
import 'models/payment_method.dart';

/// Processing mode for installment calculations.
enum ProcessingMode {
  aggregator('aggregator'),
  gateway('gateway');

  const ProcessingMode(this.value);
  final String value;
}

abstract interface class PaymentMethodRepository {
  Future<List<PaymentMethod>> getByBin({
    required String bin,
    required ProcessingMode mode,
  });
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
