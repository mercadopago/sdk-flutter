import 'package:mercadopago/mercadopago.dart';
import 'package:mercadopago/src/data/dtos/card_form_parsers.dart'
    show emptyCardFormTranslations;
import 'package:mercadopago/src/domain/models/card_bin_data.dart';
import 'package:mercadopago/src/domain/models/card_form_config.dart';
import 'package:mercadopago/src/domain/models/device_data.dart';
import 'package:mercadopago/src/domain/models/order_process_result.dart';
import 'package:mercadopago/src/domain/repositories.dart' as repos;

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

class FakeCardFormRepository implements repos.CardFormRepository {
  FakeCardFormRepository({
    this.config,
    this.binData,
    this.initError,
    this.binError,
    this.configAmount,
  });

  CardFormConfig? config;
  CardBinData? binData;
  Object? initError;
  Object? binError;

  /// Amount the server resolves from the order (returned in the default config
  /// when [config] is not supplied). Mirrors the order-driven amount flow.
  double? configAmount;

  repos.CardFormInitParams? lastInitParams;
  repos.CardBinParams? lastBinParams;

  @override
  Future<CardFormConfig> initialize(repos.CardFormInitParams params) async {
    lastInitParams = params;
    if (initError != null) throw initError!;
    return config ?? _defaultConfig(configAmount);
  }

  @override
  Future<CardBinData> getCardBin(repos.CardBinParams params) async {
    lastBinParams = params;
    if (binError != null) throw binError!;
    return binData ?? const CardBinData(paymentMethods: []);
  }

  static CardFormConfig _defaultConfig(double? amount) => CardFormConfig(
        cardNumber: const CardFieldSpec(
          type: 'number',
          minLength: 16,
          maxLength: 16,
          mask: '#### #### #### ####',
        ),
        securityCode: const SecurityCodeSpec(type: 'number', length: 3),
        holderName:
            const CardFieldSpec(type: 'string', minLength: 1, maxLength: 30),
        expirationDate: const CardFieldSpec(
          type: 'number',
          minLength: 4,
          maxLength: 4,
          mask: 'MM/YY',
        ),
        identificationTypes: const [],
        translations: emptyCardFormTranslations,
        amount: amount,
      );
}

class FakeOrderRepository implements repos.OrderRepository {
  FakeOrderRepository({
    this.result = const OrderProcessResult(id: 'order_1', status: 'processed'),
    this.error,
  });

  OrderProcessResult result;
  Object? error;
  repos.OrderProcessParams? lastParams;

  @override
  Future<OrderProcessResult> process(repos.OrderProcessParams params) async {
    lastParams = params;
    if (error != null) throw error!;
    return result;
  }
}
