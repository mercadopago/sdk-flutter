# MercadoPago Flutter SDK — AI Agents Context

This is the `mercadopago_flutter_sdk` Flutter plugin. Full reference: `ai/sdk-context.md`.

## What this SDK does

Tokenizes credit/debit cards for MercadoPago payments in Latin America.
The SDK ensures raw card data (number, CVV) never reaches integrator code —
only an opaque, short-lived token is returned.

## Setup

```yaml
# pubspec.yaml
dependencies:
  mercadopago_flutter_sdk: ^0.1.0
```

Android requires adding MercadoLibre's Artifactory to `android/settings.gradle`
(see `ai/sdk-context.md` → Installation).

## The three integration patterns

1. `MercadoPagoCheckout.forCardSave(onResult: ...)` — hosted UI, card save
2. `MercadoPagoCheckout.forCardTransaction(amount:, payerEmail:, onResult: ...)` — hosted UI + installments
3. `CoreMethods` + PCI widgets — custom UI, full control

## Critical: secure fields pattern

```dart
// Correct — pass PciFieldState controllers, never raw strings
final result = await MercadoPagoSDK.shared.coreMethods.createTokenForNewCard(
  cardNumber: cardNumberField,     // PciFieldState
  securityCode: cvvField,          // PciFieldState
  expirationDate: expirationField, // PciFieldState (MMYY from ExpirationDateField)
  cardholderName: nameCtrl.text,
);
```

## Result handling

```dart
switch (result) {
  case Success(:final data): // data.token.token → backend
  case Failure(:final error): // see MercadoPagoError variants in ai/sdk-context.md
  case Cancelled(): break;
}
```
