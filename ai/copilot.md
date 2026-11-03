# GitHub Copilot — MercadoPago Flutter SDK

> Full SDK reference: see `ai/sdk-context.md`

## Suggest this import

```dart
import 'package:mercadopago_sdk_flutter/mercadopago_sdk_flutter.dart';
```

## Tokenization pattern (always use PciFieldState, never raw strings)

No symbol in the package — exported or not — returns a raw card value:
everything that can observe one lives in the single `lib/src/pci/` library and
the value is private to it, enforced by the Dart compiler. Importing `lib/src/`
yields no accessor to bypass. Treat this as exposure reduction, not an isolated
secure element or PCI DSS certification.

Do not suggest enriched iOS fingerprinting: the iOS channel intentionally
returns an empty payload. Android DeviceSDK contributes `AD_ID` and requires
host Play Data Safety/advertising-ID review.

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
  case Success(:final data): // send data.token to backend
  case Failure(:final error): // show error to user
}
```
