# GitHub Copilot — MercadoPago Flutter SDK

Full reference: `ai/sdk-context.md` | Package: `mercadopago`

## Always suggest this import

```dart
import 'package:mercadopago/mercadopago.dart';
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
  _cardNumber.dispose();     // clears the retained value
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
    // send data.token to backend — never store on device
  case Failure(:final error):
    // error.toString() or pattern-match MercadoPagoError subtypes
}
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
// Correct — first 8 card-number digits
await sdk.coreMethods.getPaymentMethods(bin: '45099535');
```

## Never suggest

- `NewCardData(cardNumber: ...)` — removed from public API
- imports of `lib/src/` helpers to read sensitive field values
- `pluginClass: none` in pubspec.yaml — invalid Flutter plugin syntax
- `setState` for app-wide state in SDK usage examples (SDK has no opinion on state management)

## Native privacy release gates

- iOS bundles no fingerprint framework and returns an empty device payload.
  The release owner must still inspect the final app archive and privacy report
  because the host app and other dependencies can add declarations.
- Android DeviceSDK contributes `com.google.android.gms.permission.AD_ID`; the
  host owns Play Data Safety, advertising-ID, consent, and privacy disclosures.
