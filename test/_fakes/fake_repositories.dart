import 'dart:async';

import 'package:mercadopago/mercadopago.dart';
import 'package:mercadopago/src/domain/repositories.dart' as repos;

class FakePaymentMethodRepository implements repos.PaymentMethodRepository {
  FakePaymentMethodRepository({
    this.response = const [],
    this.responseFuture,
    this.error,
  });

  List<PaymentMethod> response;
  Future<List<PaymentMethod>>? responseFuture;
  Object? error;
  String? lastBin;
  repos.ProcessingMode? lastMode;

  @override
  Future<List<PaymentMethod>> getByBin({
    required String bin,
    required repos.ProcessingMode mode,
  }) async {
    lastBin = bin;
    lastMode = mode;
    if (error != null) throw error!;
    if (responseFuture != null) return responseFuture!;
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
  String? lastPaymentMethodId;

  @override
  Future<List<Issuer>> get({
    required String paymentMethodId,
    required String bin,
  }) async {
    lastPaymentMethodId = paymentMethodId;
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
