# GitHub Copilot — MercadoPago Flutter SDK

> Full SDK reference: see `ai/sdk-context.md`

## Suggest this import

```dart
import 'package:mercadopago/mercadopago.dart';
```

## Tokenization pattern (always use PciFieldState, never raw strings)

```dart
final result = await MercadoPagoSDK.shared.coreMethods.createTokenForNewCard(
  cardNumber: cardNumberController,    // PciFieldState — not a String
  expirationDate: expirationController, // PciFieldState — not a String
  securityCode: cvvController,         // PciFieldState — not a String
  identification: BuyerIdentification(name: nameController.text.trim()),
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
MercadoPagoCheckout(MPCheckoutType.cardSave()).show(context, onResult: (r) { ... });
// Card transaction: order-bound; SDK processes the payment and returns orderStatus.
MercadoPagoCheckout(MPCheckoutType.cardTransaction(MPOrder(orderId: '...', clientToken: '...')))
    .show(context, onResult: (r) { ... });
// result: CheckoutSuccess / CheckoutError / CheckoutUserCancelled
```
