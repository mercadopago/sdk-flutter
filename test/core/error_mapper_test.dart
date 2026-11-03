import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago_sdk_flutter/mercadopago_sdk_flutter.dart';
import 'package:mercadopago_sdk_flutter/src/core/api_error.dart';
import 'package:mercadopago_sdk_flutter/src/core/error_mapper.dart';

void main() {
  test(
    'unknown exceptions do not reflect their potentially sensitive text',
    () {
      final error = mapApiError(
        StateError('PAN 4111111111111111 must not escape'),
        ErrorLocation.tokenization,
      );

      expect(error, isA<UnknownError>());
      expect((error as UnknownError).message, contains('StateError'));
      expect(error.message, isNot(contains('4111111111111111')));
    },
  );

  test('API exceptions preserve the sanitized transport message', () {
    final error = mapApiError(
      const ApiException(message: 'Request timed out.', isTimeout: true),
      ErrorLocation.paymentMethods,
    );

    expect(error, isA<NetworkError>());
    final network = error as NetworkError;
    expect(network.message, 'Request timed out.');
    expect(network.isRetriable, isTrue);
    expect(network.location, ErrorLocation.paymentMethods);
  });
}
