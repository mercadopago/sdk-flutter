import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mercadopago_sdk_flutter/mercadopago_sdk_flutter.dart';
import 'package:mercadopago_sdk_flutter/src/core/api_client.dart';
import 'package:mercadopago_sdk_flutter/src/core/constants.dart';
import 'package:mercadopago_sdk_flutter/src/core/session_manager.dart';
import 'package:mercadopago_sdk_flutter/src/domain/models/device_data.dart';
import 'package:mercadopago_sdk_flutter/src/pci/pci.dart';

/// Builds a tokenizer over an injected [MockClient].
///
/// This is the one legitimate place raw digits are observable in a test: the
/// test owns the HTTP client, so it can assert on the request body the SDK
/// actually sent. Nothing here reads a value back out of a [PciFieldState].
PciTokenizer buildTokenizer(
  Future<http.Response> Function(http.Request request) handler,
) {
  final api = ApiClient(
    sessionManager: SessionManager(),
    publicKey: 'APP_USR-1234567890',
    httpClient: MockClient(handler),
  );
  addTearDown(api.close);
  return PciTokenizer(api: api);
}

/// A controller pre-filled with [value] (write-only seed, debug builds only).
PciFieldState pci(String value) {
  final state = PciFieldState();
  debugSeedPciField(state, value);
  return state;
}

void main() {
  group('PciTokenizer', () {
    test('new-card flow accepts the lean canonical token response', () async {
      late http.Request captured;
      final tokenizer = buildTokenizer((request) async {
        captured = request;
        return http.Response('{"id":"tok_new"}', 201);
      });

      final token = await tokenizer.createNewCardToken(
        cardNumber: pci('4111111111111111'),
        expirationDate: pci('1230'),
        securityCode: pci('123'),
        identification: const BuyerIdentification(name: 'JOHN DOE'),
        device: const DeviceData.empty(),
      );

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(token.token, 'tok_new');
      expect(token.firstSixDigits, isNull);
      expect(captured.url.path, '/v1/card_tokens');
      expect(captured.headers[kHeaderProductId], kProductId);
      expect(body['device'], isNull);
      expect(body['card_number'], '4111111111111111');
      expect(body['security_code'], '123');
      expect(body['expiration_month'], 12);
      expect(body['expiration_year'], 2030);
      expect(body['cardholder'], {'name': 'JOHN DOE'});
    });

    test('new-card flow forwards the identification document', () async {
      late http.Request captured;
      final tokenizer = buildTokenizer((request) async {
        captured = request;
        return http.Response('{"id":"tok_new"}', 201);
      });

      await tokenizer.createNewCardToken(
        cardNumber: pci('4111 1111 1111 1111'),
        expirationDate: pci('1230'),
        securityCode: pci('123'),
        identification: const BuyerIdentification(
          name: 'JOHN DOE',
          type: 'DNI',
          number: '12345678',
        ),
        device: const DeviceData.empty(),
      );

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      // Spaces added by CardNumberField's formatter are stripped before the
      // PAN is sent.
      expect(body['card_number'], '4111111111111111');
      expect(body['cardholder'], {
        'name': 'JOHN DOE',
        'identification': {'type': 'DNI', 'number': '12345678'},
      });
    });

    test('saved-card flow forwards optional expiry and fingerprint', () async {
      late http.Request captured;
      final tokenizer = buildTokenizer((request) async {
        captured = request;
        return http.Response('{"id":"tok_saved"}', 201);
      });

      final token = await tokenizer.createSavedCardToken(
        cardId: 'card_123',
        securityCode: pci('123'),
        expirationDate: pci('1230'),
        device: const DeviceData({'fingerprint': 'opaque'}),
      );

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(token.token, 'tok_saved');
      expect(body['card_id'], 'card_123');
      expect(body['security_code'], '123');
      expect(body['expiration_month'], 12);
      expect(body['expiration_year'], 2030);
      expect(body['device'], {'fingerprint': 'opaque'});
      expect(captured.headers[kHeaderProductId], kProductId);
      expect(body['card_number'], isNull);
    });

    test('saved-card flow omits an absent expiration date', () async {
      late http.Request captured;
      final tokenizer = buildTokenizer((request) async {
        captured = request;
        return http.Response('{"id":"tok_saved"}', 201);
      });

      await tokenizer.createSavedCardToken(
        cardId: 'card_123',
        securityCode: pci('123'),
        device: const DeviceData.empty(),
      );

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['expiration_month'], isNull);
      expect(body['expiration_year'], isNull);
      expect(body['device'], isNull);
    });

    // These two cases used to live in `pci_field_state_test.dart` as direct
    // calls to `snapshotPciValue` / `clearPciValueIfUnchanged`. Those helpers
    // are now private to the `pci` library, so the behaviour is exercised
    // through the only flow that uses it: a tokenization request that is still
    // in flight while the user keeps typing.
    test('an edit made while the request is in flight is preserved', () async {
      final requestStarted = Completer<void>();
      final response = Completer<http.Response>();
      final tokenizer = buildTokenizer((_) async {
        if (!requestStarted.isCompleted) requestStarted.complete();
        return response.future;
      });
      final securityCode = pci('123');

      final pending = tokenizer.createSavedCardToken(
        cardId: 'card_123',
        securityCode: securityCode,
        device: const DeviceData.empty(),
      );
      await requestStarted.future;
      // A different length than the original, so the assertion below is
      // conclusive rather than accidentally matching the seeded value.
      debugSeedPciField(securityCode, '4567');
      response.complete(http.Response('{"id":"tok_inflight"}', 201));

      expect((await pending).token, 'tok_inflight');
      expect(securityCode.length, 4);
    });

    test('an untouched field is cleared once the request completes', () async {
      final requestStarted = Completer<void>();
      final response = Completer<http.Response>();
      final tokenizer = buildTokenizer((_) async {
        if (!requestStarted.isCompleted) requestStarted.complete();
        return response.future;
      });
      final securityCode = pci('123');

      final pending = tokenizer.createSavedCardToken(
        cardId: 'card_123',
        securityCode: securityCode,
        device: const DeviceData.empty(),
      );
      await requestStarted.future;
      expect(securityCode.length, 3);
      response.complete(http.Response('{"id":"tok_inflight"}', 201));

      expect((await pending).token, 'tok_inflight');
      expect(securityCode.length, 0);
    });
  });
}
