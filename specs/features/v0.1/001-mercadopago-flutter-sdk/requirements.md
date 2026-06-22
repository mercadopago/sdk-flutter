# Feature Requirements: MercadoPago Flutter SDK

> Feature ID: 001
> Phase: v0.1

## Technical requirements

- [ ] Compatible con Flutter 3.10+ y Dart 3.x (null-safety, sealed classes)
- [ ] Targets móviles únicamente: iOS 13.0+ y Android API 23+
- [ ] `MercadoPagoSDK.initialize()` debe ser llamado antes de cualquier otra operación; si no, lanzar `SDKError.notInitialized`
- [ ] `publicKey` debe validarse en init: formato `APP_USR-{alphanum}` — rechazar cualquier otro formato con `SDKError.invalidPublicKey`
- [ ] `countryCode` debe ser uno de los 7 países soportados (ARG, BRA, CHL, COL, MEX, PER, URY) — rechazar inválidos con `SDKError.countryInvalid`
- [ ] Todos los requests HTTP deben incluir los headers: `X-Product-id` (ver nota abajo), `Meli-Session-id` (UUID v4), `SDK-version`, y `public_key` como query param en GETs
- [ ] Session UUID regenerado en cada llamada a `initialize()` o `setNewConfiguration()`
- [ ] Validación Luhn de número de tarjeta localmente antes de llamar al server
- [ ] Tokens NO deben ser persistidos por el SDK (TTL ~15 min — responsabilidad del backend)
- [ ] Device fingerprint incluido en el body del POST `/v1/card_tokens` bajo la key `device`
- [ ] Datos de tarjeta (número, CVV, vencimiento) solo en memoria — nunca en disco, nunca en logs
- [ ] `PciFieldState` se limpia si el widget es disposed o la app pasa a background
- [ ] HTTP timeout: 30 segundos para todos los requests
- [ ] Cache para GETs de `paymentMethods`, `installments`, `issuers`, `identificationTypes`: 5 minutos TTL en memoria
- [ ] Toda la API pública devuelve `Future<MercadoPagoResult<T>>` — nunca lanza excepciones no capturadas al caller
- [ ] `flutter analyze` con cero warnings/errores sobre el código de `lib/`
- [ ] Cobertura de tests ≥ 80% en `lib/src/domain/` y `lib/src/core_methods/`

## Constraints

- **Sin third-party DI frameworks** en producción (`get_it`, `injectable`, etc.) — usar inyección manual
- **Sin state management externo** (`riverpod`, `bloc`, `provider`) en el core del SDK — el checkout UI puede usar `StatefulWidget` + `setState` o `ChangeNotifier`
- **Sin acceso a datos del dispositivo en Dart puro** para fingerprinting — obligatorio usar Platform Channel
- **Sin almacenamiento persistente** de card data (`SharedPreferences`, `flutter_secure_storage`, `Hive`, etc.)
- **No incluir `dart:mirrors`** — incompatible con Flutter release builds
- La API pública expuesta por `lib/mercadopago_sdk.dart` debe ser mínima: solo lo que el developer necesita integrar
- Los internals de `lib/src/` no deben ser importables directamente (no son parte del contrato público)

## Key decisions

| Decisión | Opción elegida | Rationale |
|----------|---------------|-----------|
| HTTP client | `http` (package:http) | Más liviano, sin magia implícita, suficiente para los casos de uso del SDK. `dio` es overkill y agrega 300KB+ al bundle. |
| Estado de PCI fields | `StatefulWidget` con controller propio | Evita dependencia de state management externo; el controller es el único que accede al valor crudo |
| Resultado type | `sealed class MercadoPagoResult<T>` | Pattern matching seguro en Dart 3; alinea con el patrón de iOS (enum con associated values) y Android (sealed class) |
| Fingerprinting | Platform Channel a SDK nativo | El SDK nativo contiene lógica de detección anti-tampering que no puede reimplementarse en Dart |
| Checkout navigation | `Navigator` estándar de Flutter (push/pop) | Sin dependencia de `go_router` ni `auto_route`; el SDK no asume nada del router del app host |
| Checkout presentación | `showModalBottomSheet` o `Navigator.push` | Configurable en el builder (`asModal` flag); default: pantalla completa |

## Conventions

- Nombres de clases públicas con prefijo `MercadoPago` solo donde evite ambigüedad; en general, nombres descriptivos sin prefijo innecesario
- `CoreMethods` es la clase de bajo nivel; `MercadoPagoCheckout` es el de alto nivel — no mezclar
- Los errores de red se mapean a `MercadoPagoError.network(code, isRetriable)` — incluir el flag `isRetriable` para que el developer decida reintentar
- `locationDescription` en errores: indica en qué paso del flujo ocurrió (`tokenization`, `paymentMethods`, `installments`, `issuer`, `initialization`)
- `CardToken.token` es el único valor que el developer necesita para crear un pago — documentarlo prominentemente

## Constants

| Constante | Valor actual | Nota |
|-----------|-------------|------|
| `X-Product-id` | `CVQP49FTT60D1548Q56G` | Identificador interno del producto para analytics/tracking. |
| `SDK-version` | `0.1.0` | Se actualiza en cada release sincronizado con `pubspec.yaml` |
| Base URL | `https://api.mercadopago.com` | Fijo, sin configuración por el developer |
| Tracks URL | `https://api.mercadolibre.com/tracks` | Fijo, para analytics |

> **DeviceFingerPrint.xcframework (iOS)**: integrado desde `sdk-ios/Sources/Frameworks/`. Bundleado en `ios/Frameworks/` del plugin.

## Security considerations

- **Card data en memoria**: `PciFieldState` usa `final` fields no expuestos y el widget nunca llama `toString()` sobre los valores
- **Sin logs de card data**: usar `assert` + linter rule para garantizar que `CardNumber`, `SecurityCode` y `ExpirationDate` no aparecen en `print()` ni `debugPrint()`
- **Public key**: enviada como query param en GETs (igual que iOS/Android), nunca en headers ni en el body de POST — es una clave pública, no un secreto
- **Session ID**: UUID v4, regenerado en cada init, correlaciona requests para detección de fraude — no debe ser modificable por el developer
- **Token TTL**: el SDK no reutiliza tokens; cada flujo de pago genera uno nuevo
- **HTTPS only**: toda la comunicación es TLS 1.2+ (garantizado por iOS ATS y Android Network Security Config)
- **No SSL pinning**: igual que los SDK nativos de referencia — se usa el certificate store del sistema
- **Permisos Android**: solo `INTERNET` es requerido; `ACCESS_COARSE_LOCATION` y `READ_PHONE_STATE` son opcionales para mejor fingerprinting (documentar en README)
- **ProGuard/R8**: proveer reglas keep para `com.mercadopago.**` y las clases de serialización en `android/proguard-rules.pro`
