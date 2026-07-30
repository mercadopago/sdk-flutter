/// Restricts the range of installment options offered during checkout.
///
/// Sellers can, for example, cap a purchase at 3 installments by passing
/// `MPInstallment(maxInstallments: 3)`. Defaults match the native Android/iOS
/// SDKs: `1..180`. Supplied inside [MPPaymentMethodConfig.card].
class MPInstallment {
  const MPInstallment({
    this.minInstallments = 1,
    this.maxInstallments = 180,
  });

  /// Minimum number of installments to offer (default `1`).
  final int minInstallments;

  /// Maximum number of installments to offer (default `180`).
  final int maxInstallments;
}
