import 'package:mercadopago_flutter_sdk/mercadopago_flutter_sdk.dart';
import 'package:mercadopago_flutter_sdk/src/domain/models/device_data.dart';
import 'package:mercadopago_flutter_sdk/src/domain/repositories.dart' as repos;

class FakeTokenRepository implements repos.TokenRepository {
  FakeTokenRepository({this.response, this.error});

  CardToken? response;
  Object? error;

  @override
  Future<CardToken> createTokenForNewCard(
    repos.NewCardInput input,
    DeviceData device,
  ) async {
    if (error != null) throw error!;
    return response ?? _defaultToken();
  }

  @override
  Future<CardToken> createTokenForSavedCard(
    repos.SavedCardInput input,
    DeviceData device,
  ) async {
    if (error != null) throw error!;
    return response ?? _defaultToken();
  }

  CardToken _defaultToken() => CardToken(
        token: 'tok_test_123',
        bin: '411111',
        firstSixDigits: '411111',
        lastFourDigits: '1111',
        cardholderName: 'TEST',
        expirationMonth: 12,
        expirationYear: 2030,
        status: 'active',
        dateCreated: DateTime.utc(2026, 1, 1),
        dateDue: DateTime.utc(2026, 1, 1, 0, 15),
        luhnValidation: true,
        liveMode: false,
        requireEsc: false,
        cardNumberLength: 16,
        securityCodeLength: 3,
      );
}

class FakePaymentMethodRepository implements repos.PaymentMethodRepository {
  FakePaymentMethodRepository({this.response = const [], this.error});

  List<PaymentMethod> response;
  Object? error;

  @override
  Future<List<PaymentMethod>> getByBin(String bin) async {
    if (error != null) throw error!;
    return response;
  }
}

class FakeInstallmentRepository implements repos.InstallmentRepository {
  FakeInstallmentRepository({this.response = const [], this.error});

  List<Installment> response;
  Object? error;

  @override
  Future<List<Installment>> get({
    required String bin,
    required double amount,
    required repos.ProcessingMode mode,
  }) async {
    if (error != null) throw error!;
    return response;
  }
}

class FakeIssuerRepository implements repos.IssuerRepository {
  FakeIssuerRepository({this.response = const [], this.error});

  List<Issuer> response;
  Object? error;

  @override
  Future<List<Issuer>> get({
    required String paymentMethodId,
    required String bin,
  }) async {
    if (error != null) throw error!;
    return response;
  }
}

class FakeIdentificationRepository implements repos.IdentificationRepository {
  FakeIdentificationRepository({this.response = const [], this.error});

  List<IdentificationType> response;
  Object? error;

  @override
  Future<List<IdentificationType>> getAll() async {
    if (error != null) throw error!;
    return response;
  }
}
