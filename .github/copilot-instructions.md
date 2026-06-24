# GitHub Copilot — MercadoPago Flutter SDK

This is `mercadopago_flutter_sdk`. Full reference: `ai/sdk-context.md`.

## Always import

```dart
import 'package:mercadopago_flutter_sdk/mercadopago_flutter_sdk.dart';
```

## Tokenization — use PciFieldState, never raw strings

```dart
final result = await MercadoPagoSDK.shared.coreMethods.createTokenForNewCard(
  cardNumber: cardNumberController,     // PciFieldState
  securityCode: cvvController,          // PciFieldState
  expirationDate: expirationController, // PciFieldState
  cardholderName: nameController.text.trim(),
);
switch (result) {
  case Success(:final data): // send data.token.token to backend
  case Failure(:final error): // handle error
  case Cancelled(): break;
}
```

## Hosted checkout (recommended)

```dart
MercadoPagoCheckout.forCardSave(onResult: (r) { ... }).build()
MercadoPagoCheckout.forCardTransaction(amount: 1000.0, payerEmail: '...', onResult: (r) { ... }).build()
```

## Never suggest

- `NewCardData(cardNumber: rawString)` — removed from public API
- `field.rawValue` in integrator code — bypasses secure fields
