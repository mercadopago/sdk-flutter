# Feature Plan: MercadoPago Flutter SDK

> Feature ID: 001
> Phase: v0.1
> Status: accepted
> Branch: feature/001-mercadopago-flutter-sdk

## Summary

Implementación completa del SDK Flutter de MercadoPago. El SDK expone una API pública idiomática en Dart que replica las capacidades de los SDK nativos iOS y Android: tokenización de tarjetas, detección de métodos de pago por BIN, cálculo de cuotas, campos PCI-compliant para entrada de datos sensibles, y un flujo de checkout completo con UI hospedada. La arquitectura sigue Clean Architecture (Domain → Data → Presentation) con un único punto de entrada público (`MercadoPagoSDK`) y un modelo de resultado sellado (`MercadoPagoResult<T>`).

## Scope

### In scope

- Inicialización del SDK con `publicKey` y `countryCode`
- CoreMethods: `createToken` (tarjeta nueva + guardada), `getPaymentMethods`, `getInstallments`, `getIssuers`, `getIdentificationTypes`
- PCI widgets: `CardNumberField`, `SecurityCodeField`, `ExpirationDateField`
- Checkout UI: flujo `CardSave` y flujo `CardTransaction` (con selección de cuotas y resumen)
- HTTP client con headers obligatorios: `X-Product-id`, `Meli-Session-id`, `SDK-version`, `public_key`
- Device fingerprinting vía Platform Channel (delega a SDK nativo iOS/Android)
- Session UUID (generado en init, enviado en `Meli-Session-id`)
- Auto-tracking de eventos a `/tracks`
- Example app que demuestra todos los flujos
- Tests unitarios con ≥ 80% coverage en domain + CoreMethods

### Out of scope

- Apple Pay (v0.3)
- ESC (Encrypted Security Code) para tarjetas guardadas (v0.3)
- Publicación en pub.dev (v0.2)
- Tests de integración con dispositivo real (v0.2)
- Flows de pago distintos a tarjeta (QR, Wallet, etc.)

## Approach

### Grupo 1: Project setup

Scaffold mínimo del proyecto Flutter plugin.

- `pubspec.yaml` con dependencias reales (`http`/`dio`, `uuid`)
- `analysis_options.yaml` extendiendo `package:flutter_lints/flutter.yaml`
- Estructura de directorios `lib/src/` según la Constitution
- `android/` stub y `ios/` stub para Platform Channel
- `.gitignore` estándar Flutter
- `example/` app mínima con pantalla de inicio

**Archivos clave**: `pubspec.yaml`, `analysis_options.yaml`, `lib/mercadopago_sdk.dart`

---

### Grupo 2: Core infrastructure

HTTP client, session management y configuración del SDK.

- `MercadoPagoSDK` singleton: `initialize(publicKey, countryCode)`, `setNewConfiguration(...)`, `isInitialized`
- `Configuration` value object: `publicKey` (validado formato `APP_USR-*`), `countryCode` (enum 19 países), `locale`
- `SessionManager`: genera UUID v4 en init, lo expone como `sessionId`
- `ApiClient`: agrega headers obligatorios en todos los requests, cache de GETs (5 min TTL), timeout 30s
- `SDKError` sealed class: `notInitialized`, `alreadyInitialized`, `invalidPublicKey`, `countryInvalid`

**Archivos clave**: `lib/src/core/mercadopago_sdk.dart`, `lib/src/core/api_client.dart`, `lib/src/core/session_manager.dart`, `lib/src/core/configuration.dart`

---

### Grupo 3: Domain layer

Modelos de dominio, interfaces de repositorios y use cases.

- **Modelos**: `CardToken`, `PaymentMethod`, `Installment`, `PayerCost`, `Issuer`, `IdentificationType`, `CardSaveResult`, `CardTransactionResult`
- **Interfaces**: `TokenRepository`, `PaymentMethodRepository`, `InstallmentRepository`, `IssuerRepository`, `IdentificationRepository`
- **Result type**: `MercadoPagoResult<T>` sealed class con `success(T)`, `error(MercadoPagoError)`, `userCancelled(MPCancelContext)`
- **Use cases**: `CreateCardTokenUseCase`, `GetPaymentMethodsUseCase`, `GetInstallmentsUseCase`, `GetIssuersUseCase`, `GetIdentificationTypesUseCase`

**Archivos clave**: `lib/src/domain/models/`, `lib/src/domain/repositories/`, `lib/src/domain/use_cases/`

---

### Grupo 4: CoreMethods

Implementación de los repositorios y exposición pública de la API de bajo nivel.

- `CardTokenRepositoryImpl`: POST `/v1/card_tokens` con body completo incluyendo `device` (fingerprint)
- `PaymentMethodRepositoryImpl`: GET `/cho-off/v1/payment_methods` con `bin` query param
- `InstallmentRepositoryImpl`: GET `/cho-off/v1/installments` con `bin`, `amount`, `processing_mode`
- `IssuerRepositoryImpl`: GET `/cho-off/v1/issuers` con `payment_method_id`, `bin`
- `IdentificationRepositoryImpl`: GET `/v1/identification_types`
- `CoreMethods` clase pública: envuelve los use cases, expone API `Future<MercadoPagoResult<T>>`
- Validación Luhn local antes de POST token

**Archivos clave**: `lib/src/core_methods/`, `lib/src/data/repositories/`

---

### Grupo 5: PCI Fields

Widgets Flutter PCI-compliant para entrada de datos de tarjeta.

- `CardNumberField`: BIN detection a 8 dígitos, validación Luhn, callback `onBinChanged`, `onCardFilled`, `onError`
- `SecurityCodeField`: longitud configurable (3 o 4), callback `onFilled`, `onError`
- `ExpirationDateField`: formato MM/YY automático, validación mes/año, callback `onFilled`, `onError`
- `PciFieldState`: contenedor en memoria de los valores — nunca serializado, nunca pasado a logs
- Todos los campos extienden `StatefulWidget` con `obscureText` / rendering seguro
- `CardFieldError` sealed class con variantes por campo

**Archivos clave**: `lib/src/components/card_number_field.dart`, `lib/src/components/security_code_field.dart`, `lib/src/components/expiration_date_field.dart`, `lib/src/components/pci_field_state.dart`

---

### Grupo 6: Checkout UI

Flujo completo de checkout hospedado con navegación interna.

- `MercadoPagoCheckout` builder: `forCardSave()`, `forCardTransaction(amount, payerEmail)`
- `CheckoutController`: orquesta la navegación entre pantallas
- Pantallas (Widgets):
  - `CardFormScreen`: entrada de datos de tarjeta usando PCI Fields + nombre del titular + documento
  - `InstallmentScreen`: lista de cuotas (solo para `CardTransaction`)
  - `ReviewScreen`: resumen tarjeta + cuotas + total (solo para `CardTransaction`)
- Resultado vía callback: `onResult(MercadoPagoResult<T>)`
- Soporte para `MPCheckoutAppearance`: tema claro/oscuro, colores primarios
- Cancelación del usuario: `userCancelled` result con contexto de pantalla activa

**Archivos clave**: `lib/src/checkout/`, incluyendo pantallas, controlador y builder

---

### Grupo 7: Device fingerprinting

Platform Channel que delega a SDK nativo iOS/Android.

- `FingerprintService` en Dart: llama channel `mercadopago/fingerprint`
- iOS (Swift): invoca `DeviceFingerPrint.xcframework` nativo, retorna JSON con device data
- Android (Kotlin): invoca `com.mercadolibre.android:device` nativo, retorna JSON con device data
- `DeviceData` model en Dart: deserializa la respuesta del channel
- Si el channel falla (simulador sin SDK nativo): retorna `DeviceData.empty()` sin lanzar error
- `FingerprintService` es inyectado en `CardTokenRepositoryImpl` para incluir `device` en el POST

**Archivos clave**: `lib/src/fingerprint/fingerprint_service.dart`, `android/src/main/kotlin/.../FingerprintHandler.kt`, `ios/Classes/FingerprintHandler.swift`

---

### Grupo 8: Analytics

Auto-tracking de eventos de uso al endpoint `/tracks`.

- `AnalyticsService`: fire-and-forget, no bloquea el flujo principal
- Eventos tracked: `sdk_initialize`, `core_methods_tokenize`, `checkout_start`, `checkout_complete`, `checkout_cancel`, `checkout_error`, `installment_selected`, `issuer_selected`
- Payload: `event_name`, `session_id`, `sdk_version`, `timestamp`, `event_data` (contextual)
- Errores de tracking silenciados (no deben afectar la operación principal)
- `AnalyticsService` inyectado en SDK singleton e iniciado en `initialize()`

**Archivos clave**: `lib/src/analytics/analytics_service.dart`, `lib/src/analytics/analytics_event.dart`

---

### Grupo 9: Example app + documentación

Ejemplo funcional y README de integración.

- `example/lib/main.dart`: app Flutter con pantallas demostrando:
  - CardSave flow completo
  - CardTransaction flow completo
  - CoreMethods directo (pantalla custom usando PCI fields)
- `README.md` actualizado con: instalación, inicialización, uso de CoreMethods, uso de Checkout, manejo de errores
- `CHANGELOG.md` con entrada v0.1.0
- `dartdoc` comments en toda la API pública

**Archivos clave**: `example/`, `README.md`, `CHANGELOG.md`

---

## Dependencies

- Ninguna dependencia de otras features (001 es la feature inicial)
- Dependencia externa: SDK nativo iOS (`DeviceFingerPrint.xcframework`) y Android (`com.mercadolibre.android:device`) — deben estar disponibles para los Platform Channels

## Open questions

- [ ] ¿Se usa `http` (más liviano) o `dio` (más features) como HTTP client? — decidir en Grupo 2 antes de implementar repositorios
- [ ] ¿Dónde se obtiene `DeviceFingerPrint.xcframework` para iOS? ¿Se incluye en el repo o se descarga en CI?
- [ ] ¿`X-Product-id` tiene un valor fijo para el SDK Flutter o debe ser configurado por el developer?
