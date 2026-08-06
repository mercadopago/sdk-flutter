# GitHub Copilot — MercadoPago Flutter SDK

Full reference: `ai/sdk-context.md` | Package: `mercadopago_flutter_sdk`

## Always suggest this import

```dart
import 'package:mercadopago_flutter_sdk/mercadopago_flutter_sdk.dart';
```

## Tokenization — PciFieldState controllers, never raw strings

```dart
// Correct pattern for all card tokenization
final result = await MercadoPagoSDK.shared.coreMethods.createTokenForNewCard(
  cardNumber: cardNumberController,     // PciFieldState from CardNumberField
  expirationDate: expirationController, // PciFieldState from ExpirationDateField (MMYY)
  securityCode: cvvController,          // PciFieldState from SecurityCodeField
  identification: BuyerIdentification(name: nameController.text.trim()),
);
```

## PCI widget setup (always dispose)

```dart
final _cardNumber     = PciFieldState();
final _securityCode   = PciFieldState();
final _expirationDate = PciFieldState();

@override
void dispose() {
  _cardNumber.dispose();     // zeroes out raw value
  _securityCode.dispose();
  _expirationDate.dispose();
  super.dispose();
}

// In build():
CardNumberField(controller: _cardNumber),
ExpirationDateField(controller: _expirationDate),
SecurityCodeField(controller: _securityCode),
```

## Result handling (exhaustive switch required)

```dart
switch (result) {
  case Success(:final data):
    // send data.token.token to backend — never store on device
  case Failure(:final error):
    // error.toString() or pattern-match MercadoPagoError subtypes
  case Cancelled():
    // user closed the UI
}
```

## Hosted checkout (preferred when UI flexibility not needed)

```dart
// Card Save — one unified builder + MPCheckoutType + .show(context)
MercadoPagoCheckout(MPCheckoutType.cardSave()).show(context, onResult: (r) { ... });

// Card Transaction (order-bound; amount from the server; SDK processes the payment)
MercadoPagoCheckout(
  MPCheckoutType.cardTransaction(MPOrder(orderId: '...', clientToken: '...')),
).show(context, onResult: (r) { ... });
// result cases: CheckoutSuccess / CheckoutError / CheckoutUserCancelled
```

## Initialization

```dart
MercadoPagoSDK.shared.initialize(
  publicKey: 'APP_USR-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
  countryCode: 'ARG', // ARG | BRA | CHL | COL | MEX | PER | URY
);
```

## BIN lookups use 8 digits

```dart
// Correct — 8 digits
await sdk.coreMethods.getPaymentMethods(bin: '45099535');
// Wrong — 6 digits
await sdk.coreMethods.getPaymentMethods(bin: '450995'); // may return 404
```

## Never suggest

- `NewCardData(cardNumber: ...)` — removed from public API
- `field.rawValue` — bypasses PCI secure fields
- `pluginClass: none` in pubspec.yaml — invalid Flutter plugin syntax
- `setState` for app-wide state in SDK usage examples (SDK has no opinion on state management)
