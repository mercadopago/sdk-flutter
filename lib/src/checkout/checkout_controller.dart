import 'dart:async';

import 'package:flutter/foundation.dart';

import '../analytics/analytics_event.dart';
import '../analytics/analytics_service.dart';
import '../core/error_mapper.dart';
import '../core_methods/card_data.dart';
import '../core_methods/core_methods.dart';
import '../domain/errors.dart';
import '../domain/models/card_save_result.dart';
import '../domain/models/card_token.dart';
import '../domain/models/card_transaction_result.dart';
import '../domain/models/installment.dart';
import '../domain/models/mp_cancel_context.dart';
import '../domain/models/payment_method.dart';
import '../domain/result.dart';

/// Type of checkout flow the user is performing.
enum CheckoutKind { cardSave, cardTransaction }

/// Coordinates state between checkout screens (card form → installments →
/// review) and triggers the underlying [CoreMethods] calls.
class CheckoutController extends ChangeNotifier {
  CheckoutController({
    required this.kind,
    required CoreMethods coreMethods,
    required AnalyticsService analytics,
    this.amount,
    this.payerEmail,
  })  : _coreMethods = coreMethods,
        _analytics = analytics,
        assert(
          kind == CheckoutKind.cardSave || amount != null,
          'CardTransaction requires an amount.',
        );

  final CheckoutKind kind;
  final CoreMethods _coreMethods;
  final AnalyticsService _analytics;
  final double? amount;
  final String? payerEmail;

  CheckoutStep _step = CheckoutStep.cardForm;
  CheckoutStep get step => _step;

  // Card-form state (raw values come from PciFieldState controllers held by
  // the screen; the controller stores derived data after submission).
  CardToken? _token;
  PaymentMethod? _selectedMethod;
  List<Installment> _installments = const [];
  PayerCost? _selectedPayerCost;
  MercadoPagoError? _lastError;

  CardToken? get token => _token;
  PaymentMethod? get selectedMethod => _selectedMethod;
  List<Installment> get installments => _installments;
  PayerCost? get selectedPayerCost => _selectedPayerCost;
  MercadoPagoError? get lastError => _lastError;

  bool _busy = false;
  bool get isBusy => _busy;
  Timer? _binDebounce;

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }

  /// Loads payment methods for the entered BIN. Called as the user types.
  /// Debounced to 300 ms to avoid flooding the API on rapid keystrokes.
  void onBinChanged(String bin) {
    _binDebounce?.cancel();
    _binDebounce = Timer(const Duration(milliseconds: 300), () async {
      final result = await _coreMethods.getPaymentMethods(bin: bin);
      switch (result) {
        case Success(:final data):
          if (data.isNotEmpty) {
            _selectedMethod = data.first;
            notifyListeners();
          }
        case Failure(:final error):
          _lastError = error;
          notifyListeners();
        case Cancelled():
          break;
      }
    });
  }

  /// Submits the card form. Performs tokenization and, for CardTransaction
  /// flows, advances to installment selection. For CardSave flows the result
  /// is delivered immediately to the caller via the screen's callback.
  ///
  /// Returns immediately with a [Failure] if a submission is already in
  /// progress — callers must not call this concurrently.
  Future<MercadoPagoResult<CardToken>> submitCardForm(NewCardData data) async {
    if (_busy) {
      return const Failure(
        ValidationError(
          field: 'submit',
          message: 'A submission is already in progress.',
        ),
      );
    }
    _setBusy(true);
    try {
      final result = await _coreMethods.createTokenForNewCard(data);
      switch (result) {
        case Success(:final data):
          _token = data;
          _lastError = null;
          if (kind == CheckoutKind.cardTransaction) {
            await _loadInstallments(bin: data.bin);
            if (_installments.isNotEmpty) {
              _step = CheckoutStep.installmentSelection;
            }
          }
        case Failure(:final error):
          _lastError = error;
        case Cancelled():
          break;
      }
      return result;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _loadInstallments({required String bin}) async {
    final amt = amount;
    if (amt == null) return;
    final result =
        await _coreMethods.getInstallments(bin: bin, amount: amt);
    switch (result) {
      case Success(:final data):
        _installments = data;
        if (data.isNotEmpty && data.first.payerCosts.isNotEmpty) {
          _selectedPayerCost = data.first.payerCosts.first;
        }
      case Failure(:final error):
        _lastError = error;
      case Cancelled():
        break;
    }
  }

  void selectPayerCost(PayerCost cost) {
    _selectedPayerCost = cost;
    _analytics.track(
      AnalyticsEvent.installmentSelected(installments: cost.installments),
    );
    notifyListeners();
  }

  void goToReview() {
    _step = CheckoutStep.review;
    notifyListeners();
  }

  void backToCardForm() {
    _lastError = null;
    _step = CheckoutStep.cardForm;
    notifyListeners();
  }

  void backToInstallments() {
    _lastError = null;
    _step = CheckoutStep.installmentSelection;
    notifyListeners();
  }

  /// Builds the final CardSave result.
  MercadoPagoResult<CardSaveResult> buildCardSaveResult() {
    final t = _token;
    final m = _selectedMethod;
    if (t == null || m == null) {
      return const Failure(
        InitializationFailedError(reason: 'Token or payment method missing.'),
      );
    }
    return Success(
      CardSaveResult(
        token: t,
        paymentMethodId: m.id,
        paymentTypeId: m.paymentTypeId,
        issuerId: '',
      ),
    );
  }

  /// Builds the final CardTransaction result.
  MercadoPagoResult<CardTransactionResult> buildCardTransactionResult() {
    final t = _token;
    final m = _selectedMethod;
    final cost = _selectedPayerCost;
    if (t == null || m == null || cost == null) {
      return const Failure(
        InitializationFailedError(reason: 'Required checkout state missing.'),
      );
    }
    return Success(
      CardTransactionResult(
        token: t,
        paymentMethodId: m.id,
        paymentTypeId: m.paymentTypeId,
        issuerId: '',
        payerCost: cost,
        transactionAmount: cost.totalAmount,
      ),
    );
  }

  MercadoPagoError mapApi(Object e, ErrorLocation location) =>
      mapApiError(e, location);

  @override
  void dispose() {
    _binDebounce?.cancel();
    super.dispose();
  }
}
