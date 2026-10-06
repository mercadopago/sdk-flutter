import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago/src/data/dtos/installment_dto.dart';
import 'package:mercadopago/src/data/dtos/issuer_dto.dart';
import 'package:mercadopago/src/data/dtos/payment_method_dto.dart';

/// Conformance tests against the **canonical native payloads**.
///
/// These fixtures are copied verbatim from the native SDK test suites, which
/// are the source of truth for the wire contract:
///
/// * `sdk-ios/Tests/CoreMethodsTests/CoreMethodsTest+PaymentMethodStub.swift`
///   (`validResponse`)
/// * `sdk-android/core-methods/.../response/InstallmentsResponse.kt` and
///   `CardIssuerResponse.kt` (every field declared nullable)
///
/// The point of these tests is narrow and important: a payload the native SDKs
/// accept must never throw here. Requiring fields the contract does not
/// guarantee (`name`, `secure_thumbnail`, root-level `min/max_allowed_amount`)
/// made `getPaymentMethods` fail on valid responses.
void main() {
  group('payment_methods — canonical iOS fixture', () {
    // Verbatim from CoreMethodsTest+PaymentMethodStub.validResponse.
    const fixture = '''
    [
      {
        "financial_institutions": [],
        "payer_costs": [
          {
            "installment_rate": 0,
            "min_allowed_amount": 0.5,
            "max_allowed_amount": 60000,
            "installments": 1,
            "discount_rate": 0,
            "reimbursement_rate": 0,
            "labels": [],
            "payment_method_option_id": "123"
          },
          {
            "installment_rate": 8.14,
            "min_allowed_amount": 10,
            "max_allowed_amount": 60000,
            "installments": 2,
            "discount_rate": 0,
            "reimbursement_rate": 0,
            "labels": [],
            "payment_method_option_id": "123"
          }
        ],
        "agreements": [],
        "issuer": { "default": true, "id": 24, "thumbnail": "www.google.com" },
        "card": {
          "bin": 502432,
          "length": { "min": 16, "max": 16 },
          "validation": "standard",
          "security_code": { "mode": "mandatory", "location": "back", "length": 3 }
        },
        "total_financial_cost": 0,
        "min_accreditation_days": 0,
        "max_accreditation_days": 2,
        "accreditation_time": 2880,
        "merchant_account_id": "",
        "status": "active",
        "additional_info_needed": [
          "cardholder_identification_number",
          "cardholder_identification_type",
          "cardholder_name"
        ],
        "processing_mode": "aggregator",
        "site_id": "MLB",
        "labels": ["zero_dollar_auth"],
        "deferred_capture": "supported",
        "marketplace": "NONE",
        "id": "master",
        "payment_type_id": "credit_card",
        "thumbnail": "www.google.com"
      }
    ]
    ''';

    test('parses without throwing', () {
      final list = jsonDecode(fixture) as List<dynamic>;
      expect(
        () => PaymentMethodDto.fromJson(list.first as Map<String, dynamic>),
        returnsNormally,
      );
    });

    test('maps the fields the contract actually carries', () {
      final list = jsonDecode(fixture) as List<dynamic>;
      final dto = PaymentMethodDto.fromJson(list.first as Map<String, dynamic>);
      final method = dto.toDomain();

      expect(method.id, 'master');
      expect(method.paymentTypeId, 'credit_card');
      expect(method.status, 'active');
      expect(method.thumbnail, 'www.google.com');
      expect(method.accreditationTime, 2880);
      expect(method.cardNumberLengthMin, 16);
      expect(method.cardNumberLengthMax, 16);
      expect(method.securityCodeLength, 3);
      expect(method.securityCodeLocation, 'back');
      expect(method.additionalInfoNeeded, hasLength(3));
      expect(method.processingMode, 'aggregator');
      expect(method.merchantAccountId, isNull);
      expect(method.siteId, 'MLB');
      expect(method.minAccreditationDays, 0);
      expect(method.maxAccreditationDays, 2);
      expect(method.totalFinancialCost, 0);
      expect(method.financialInstitutions, isEmpty);
      expect(method.issuer?.id, '24');
      expect(method.issuer?.isDefault, isTrue);
      expect(method.issuer?.thumbnail, 'www.google.com');
      expect(method.card?.bin, 502432);
      expect(method.card?.length?.min, 16);
      expect(method.card?.length?.max, 16);
      expect(method.card?.validation, 'standard');
      expect(method.card?.securityCode?.mode, 'mandatory');
      expect(method.card?.securityCode?.location, 'back');
      expect(method.card?.securityCode?.length, 3);
      expect(method.bins, isEmpty);
      expect(method.marketplace, 'NONE');
      expect(method.deferredCapture, 'supported');
      expect(method.agreements, isEmpty);
      expect(method.payerCosts, hasLength(2));
      expect(method.payerCosts.first.installments, 1);
      expect(method.payerCosts.first.installmentRate, 0);
      expect(method.payerCosts.first.reimbursementRate, 0);
      expect(method.payerCosts.first.paymentMethodOptionId, '123');
      expect(method.labels, ['zero_dollar_auth']);
    });

    test('derives the allowed-amount range from payer_costs[]', () {
      final list = jsonDecode(fixture) as List<dynamic>;
      final dto = PaymentMethodDto.fromJson(list.first as Map<String, dynamic>);

      // The root carries no min/max_allowed_amount — they live in payer_costs.
      expect(dto.minAllowedAmount, 0.5);
      expect(dto.maxAllowedAmount, 60000);
    });

    test('tolerates the absent `name` and `secure_thumbnail`', () {
      final list = jsonDecode(fixture) as List<dynamic>;
      final root = list.first as Map<String, dynamic>;
      expect(root.containsKey('name'), isFalse);
      expect(root.containsKey('secure_thumbnail'), isFalse);

      final dto = PaymentMethodDto.fromJson(root);
      expect(dto.name, isEmpty);
      expect(dto.secureThumbnail, isEmpty);
    });

    test('accepts the optional card block when it is absent', () {
      final list = jsonDecode(fixture) as List<dynamic>;
      final root = Map<String, dynamic>.from(list.first as Map<String, dynamic>)
        ..remove('card');
      final method = PaymentMethodDto.fromJson(root).toDomain();

      expect(method.card, isNull);
      expect(method.cardNumberLengthMin, isNull);
      expect(method.cardNumberLengthMax, isNull);
      expect(method.securityCodeLength, isNull);
      expect(method.securityCodeLocation, isNull);
    });

    test('accepts card with optional PAN and CVV metadata absent', () {
      final list = jsonDecode(fixture) as List<dynamic>;
      final root = Map<String, dynamic>.from(list.first as Map<String, dynamic>)
        ..['card'] = {'bin': 502432, 'validation': 'standard'};
      final method = PaymentMethodDto.fromJson(root).toDomain();

      expect(method.card?.bin, 502432);
      expect(method.card?.length, isNull);
      expect(method.card?.securityCode, isNull);
      expect(method.cardNumberLengthMin, isNull);
      expect(method.securityCodeLength, isNull);
    });

    test('preserves gateway agreements and merchant-account metadata', () {
      final list = jsonDecode(fixture) as List<dynamic>;
      final root = Map<String, dynamic>.from(list.first as Map<String, dynamic>)
        ..['processing_mode'] = 'gateway'
        ..['merchant_account_id'] = 'merchant-1'
        ..['agreements'] = [
          {
            'merchant_accounts': [
              {'id': 'merchant-1', 'payment_method_option_id': 'option-1'},
            ],
            'time_frame': {
              'start_date': '2026-01-01',
              'end_date': '2026-12-31',
            },
          },
        ];

      final method = PaymentMethodDto.fromJson(root).toDomain();

      expect(method.processingMode, 'gateway');
      expect(method.merchantAccountId, 'merchant-1');
      expect(method.agreements.single.merchantAccounts.single.id, 'merchant-1');
      expect(method.agreements.single.timeFrame?.endDate, '2026-12-31');
    });

    test('preserves Android payer-cost fields and lossless issuer IDs', () {
      // Standalone Android-shaped payload. Keeping this independent from the
      // iOS fixture prevents either native contract from masking regressions
      // in the other one.
      final method = PaymentMethodDto.fromJson(const {
        'id': 'master',
        'payment_type_id': 'credit_card',
        'status': 'active',
        'issuer': {'id': '001A', 'default': false, 'thumbnail': ''},
        'card': {
          'bin': 502432,
          'length': {'min': 16, 'max': 16},
          'validation': 'standard',
          'security_code': {
            'mode': 'mandatory',
            'location': 'back',
            'length': 3,
          },
        },
        'payer_costs': [
          {
            'installments': 3,
            'installment_amount': 40.0,
            'installment_rate': 2.0,
            'installment_rate_collector': ['MERCADOPAGO'],
            'total_amount': 120.0,
            'min_allowed_amount': 1.0,
            'max_allowed_amount': 60000.0,
            'discount_rate': 0.0,
            'reimbursement_rate': 0.0,
            'labels': ['CFT_0%'],
            'payment_method_option_id': 'option-1',
          },
        ],
      }).toDomain();
      final cost = method.payerCosts.single;

      expect(method.issuer?.id, '001A');
      expect(method.issuer?.isDefault, isFalse);
      expect(cost.installments, 3);
      expect(cost.installmentAmount, 40);
      expect(cost.installmentRateCollector, ['MERCADOPAGO']);
      expect(cost.totalAmount, 120);
      expect(cost.labels, ['CFT_0%']);
    });
  });

  group('installments — canonical iOS fixture', () {
    // Verbatim from sdk-ios CoreMethodsTest.InstallmentsStub.validResponse.
    const fixture = '''
    [
      {
        "payment_method_id": "master",
        "payment_type_id": "credit_card",
        "thumbnail": "www.google.com",
        "issuer": { "id": "1", "thumbnail": "www.google.com" },
        "processing_mode": "aggregator",
        "merchant_account_id": "",
        "payer_costs": [
          {
            "installments": 1,
            "installment_amount": 5000,
            "installment_rate": 0,
            "installment_rate_collector": ["MP"],
            "total_amount": 5000,
            "min_allowed_amount": 0.5,
            "max_allowed_amount": 60000,
            "discount_rate": 0,
            "reimbursement_rate": 0,
            "labels": [],
            "payment_method_option_id": "000000"
          }
        ],
        "agreements": []
      }
    ]
    ''';

    test('accepts empty merchant account and maps every native field', () {
      final values = jsonDecode(fixture) as List<dynamic>;
      final value = InstallmentDto.fromJson(
        values.single as Map<String, dynamic>,
      ).toDomain();

      expect(value.merchantAccountId, isNull);
      expect(value.thumbnail, 'www.google.com');
      expect(value.issuer.id, '1');
      expect(value.payerCosts.single.installmentRateCollector, ['MP']);
      expect(value.payerCosts.single.reimbursementRate, 0);
      expect(value.agreements, isEmpty);
    });

    test('still rejects a non-string merchant account', () {
      final values = jsonDecode(fixture) as List<dynamic>;
      final root = Map<String, dynamic>.from(
        values.single as Map<String, dynamic>,
      )..['merchant_account_id'] = 42;

      expect(() => InstallmentDto.fromJson(root), throwsFormatException);
    });
  });

  group('card_issuers — canonical iOS fixture', () {
    // Verbatim from sdk-ios CoreMethodsTest.IssuerStub.validResponse.
    const fixture = '''
    [
      {
        "id": "0",
        "name": "Banco",
        "merchant_account_id": "",
        "processing_mode": "aggregator",
        "status": "active",
        "thumbnail": ""
      }
    ]
    ''';

    test('accepts empty native strings and normalizes merchant account', () {
      final values = jsonDecode(fixture) as List<dynamic>;
      final issuer = IssuerDto.fromJson(
        values.single as Map<String, dynamic>,
      ).toDomain();

      expect(issuer.id, '0');
      expect(issuer.name, 'Banco');
      expect(issuer.thumbnail, isEmpty);
      expect(issuer.merchantAccountId, isNull);
      expect(issuer.processingMode, 'aggregator');
      expect(issuer.status, 'active');
    });

    test('still rejects a non-string thumbnail', () {
      final values = jsonDecode(fixture) as List<dynamic>;
      final root = Map<String, dynamic>.from(
        values.single as Map<String, dynamic>,
      )..['thumbnail'] = false;

      expect(() => IssuerDto.fromJson(root), throwsFormatException);
    });
  });

  group('card_issuers — Android contract (all fields nullable, no name)', () {
    test('parses an entry carrying only id and thumbnail', () {
      final dto = IssuerDto.fromJson(const {
        'id': '24',
        'thumbnail': 'www.google.com',
      });

      expect(dto.id, '24');
      expect(dto.thumbnail, 'www.google.com');
      // Neither exists in the native contract.
      expect(dto.name, isEmpty);
      expect(dto.secureThumbnail, isEmpty);
      expect(dto.processingMode, isEmpty);
      expect(dto.status, isEmpty);
    });

    test('still requires the identifier', () {
      expect(() => IssuerDto.fromJson(const {}), throwsFormatException);
    });
  });

  group('installments — Android contract (every field nullable)', () {
    test('parses an entry whose issuer carries only id and thumbnail', () {
      final dto = InstallmentDto.fromJson(const {
        'payment_method_id': 'master',
        'payment_type_id': 'credit_card',
        'processing_mode': 'aggregator',
        'issuer': {'id': '24', 'thumbnail': 'www.google.com', 'default': true},
        'payer_costs': [
          {
            'installments': 1,
            'installment_amount': 100.0,
            'total_amount': 100.0,
            'min_allowed_amount': 0.5,
            'max_allowed_amount': 60000.0,
            'installment_rate': 0,
            'discount_rate': 0,
            'labels': <String>[],
            'payment_method_option_id': '123',
          },
        ],
      });

      expect(dto.issuer.id, '24');
      expect(dto.issuer.thumbnail, 'www.google.com');
      expect(dto.issuer.name, isEmpty);
      expect(dto.issuer.secureThumbnail, isEmpty);
      expect(dto.payerCosts, hasLength(1));
      expect(dto.payerCosts.first.installments, 1);
    });

    test('parses an entry with no issuer and no payer_costs', () {
      final dto = InstallmentDto.fromJson(const {
        'payment_method_id': 'master',
      });

      expect(dto.paymentMethodId, 'master');
      expect(dto.payerCosts, isEmpty);
      expect(dto.issuer.id, isEmpty);
    });

    test('still rejects a corrupt payer_cost', () {
      expect(
        () => InstallmentDto.fromJson(const {
          'payer_costs': [
            {'installments': 0},
          ],
        }),
        throwsFormatException,
      );
    });
  });
}
