import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mercadopago/src/core/api_client.dart';
import 'package:mercadopago/src/core/session_manager.dart';
import 'package:mercadopago/src/data/repositories/identification_repository_impl.dart';
import 'package:mercadopago/src/data/repositories/installment_repository_impl.dart';
import 'package:mercadopago/src/data/repositories/issuer_repository_impl.dart';
import 'package:mercadopago/src/data/repositories/payment_method_repository_impl.dart';
import 'package:mercadopago/src/domain/repositories.dart';

void main() {
  ApiClient malformedListClient() => ApiClient(
    sessionManager: SessionManager(),
    publicKey: 'APP_USR-1234567890',
    httpClient: MockClient((_) async => http.Response('[42]', 200)),
  );

  test('payment-method repository rejects a malformed list entry', () async {
    final api = malformedListClient();
    addTearDown(api.close);

    await expectLater(
      PaymentMethodRepositoryImpl(
        api,
      ).getByBin(bin: '45099535', mode: ProcessingMode.aggregator),
      throwsFormatException,
    );
  });

  test(
    'payment-method repository sends the selected processing mode',
    () async {
      final modes = <String?>[];
      final api = ApiClient(
        sessionManager: SessionManager(),
        publicKey: 'APP_USR-1234567890',
        httpClient: MockClient((request) async {
          modes.add(request.url.queryParameters['processing_mode']);
          return http.Response('[]', 200);
        }),
      );
      addTearDown(api.close);
      final repository = PaymentMethodRepositoryImpl(api);

      await repository.getByBin(
        bin: '45099535',
        mode: ProcessingMode.aggregator,
      );
      await repository.getByBin(bin: '45099535', mode: ProcessingMode.gateway);

      expect(modes, ['aggregator', 'gateway']);
    },
  );

  test('installment repository rejects a malformed list entry', () async {
    final api = malformedListClient();
    addTearDown(api.close);

    await expectLater(
      InstallmentRepositoryImpl(
        api,
      ).get(bin: '45099535', amount: 100, mode: ProcessingMode.aggregator),
      throwsFormatException,
    );
  });

  test('issuer repository rejects a malformed list entry', () async {
    final api = malformedListClient();
    addTearDown(api.close);

    await expectLater(
      IssuerRepositoryImpl(api).get(paymentMethodId: 'visa', bin: '45099535'),
      throwsFormatException,
    );
  });

  test('identification repository rejects a malformed list entry', () async {
    final api = malformedListClient();
    addTearDown(api.close);

    await expectLater(
      IdentificationRepositoryImpl(api).getAll(),
      throwsFormatException,
    );
  });
}
