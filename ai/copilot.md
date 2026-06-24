# GitHub Copilot — MercadoPago Flutter SDK

> Full SDK reference: see `ai/sdk-context.md`

## Suggest this import

```dart
import 'package:mercadopago_flutter_sdk/mercadopago_flutter_sdk.dart';
```

## Tokenization pattern (always use PciFieldState, never raw strings)

```dart
final result = await MercadoPagoSDK.shared.coreMethods.createTokenForNewCard(
  cardNumber: cardNumberController,    // PciFieldState — not a String
  securityCode: cvvController,         // PciFieldState — not a String
  expirationDate: expirationController, // PciFieldState — not a String
  cardholderName: nameController.text.trim(),
);
```

## Result handling (sealed class — all cases required)

```dart
switch (result) {
  case Success(:final data): // send data.token.token to backend
  case Failure(:final error): // show error to user
  case Cancelled(): // user dismissed
}
```

## Hosted checkout (preferred for most integrations)

```dart
MercadoPagoCheckout.forCardSave(onResult: (r) { ... }).build()
MercadoPagoCheckout.forCardTransaction(amount: 1000, payerEmail: '...', onResult: (r) { ... }).build()
```
