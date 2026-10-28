# Feature Plan: MercadoPago Flutter SDK

> Feature ID: 001
> Phase: v0.1
> Status: implemented; release validation and native privacy blockers remain

## Summary

Implementación del núcleo del SDK Flutter de MercadoPago. El SDK expone una API pública idiomática en Dart para tokenización de tarjetas, detección de métodos de pago por BIN, consulta de cuotas y widgets orientados a reducir la exposición accidental de datos sensibles. La arquitectura sigue Clean Architecture (Domain → Data) con un único punto de entrada público (`MercadoPagoSDK`) y un modelo de resultado sellado (`MercadoPagoResult<T>`). El diseño no constituye por sí solo una certificación PCI DSS para la aplicación integradora.

## Scope

### In scope

- Inicialización del SDK con `publicKey` y `countryCode`
- CoreMethods: `createToken` (tarjeta nueva + guardada), `getPaymentMethods`, `getInstallments`, `getIssuers`, `getIdentificationTypes`
- PCI widgets: `CardNumberField`, `SecurityCodeField`, `ExpirationDateField`
- HTTP client con `Meli-Session-id`, `SDK-version`, `User-Agent` y `public_key`; product ID como header del POST de token o query param de los GET que lo requieren
- Device fingerprinting vía Platform Channel (Android DeviceSDK; iOS retorna
  un mapa vacío de compatibilidad)
- Session UUID (generado en init, enviado en `Meli-Session-id`)
- Auto-tracking de eventos a `/tracks`
- Example app que demuestra CoreMethods con widgets PCI
- Tests unitarios con ≥ 80% coverage independiente en domain, CoreMethods y PCI

### Out of scope

- Apple Pay (v0.3)
- ESC (Encrypted Security Code) para tarjetas guardadas (v0.3)
- Publicación en pub.dev (v0.2)
- Tests de integración con dispositivo real (v0.2)
- Flows de pago distintos a tarjeta (QR, Wallet, etc.)

## Approach

### Grupo 1: Project setup

Scaffold mínimo del proyecto Flutter plugin.

- `pubspec.yaml` con dependencias reales (`http`, `uuid`)
- `analysis_options.yaml` extendiendo `package:flutter_lints/flutter.yaml`
- Estructura de directorios `lib/src/` según la Constitution
- Implementaciones Android/iOS para el Platform Channel
- `.gitignore` y `.pubignore` para desarrollo y publicación
- Gate local reproducible con toolchain fijado, cobertura, builds nativos y dry-run de pub.dev; GitHub Actions no está disponible por política de seguridad
- `example/` app mínima con pantalla de inicio

**Archivos clave**: `pubspec.yaml`, `analysis_options.yaml`, `lib/mercadopago_sdk_flutter.dart`

---

### Grupo 2: Core infrastructure

HTTP client, session management y configuración del SDK.

- `MercadoPagoSDK` singleton: `initialize(publicKey, countryCode)`, `setNewConfiguration(...)`, `isInitialized`
- `Configuration` value object: `publicKey` (formatos `TEST-*` y `APP_USR-*`), `countryCode` (enum 7 países: ARG, BRA, CHL, COL, MEX, PER, URY), `locale`
- `SessionManager`: genera UUID v4 en init, lo expone como `sessionId`
- `ApiClient`: aplica el contrato de headers/query por endpoint, cache de GETs (5 min TTL) y timeout de 30s
- `SDKError` sealed class con `SDKNotInitializedError`, `SDKAlreadyInitializedError`, `SDKInvalidPublicKeyError` y `SDKInvalidCountryError`

**Archivos clave**: `lib/src/core/mercadopago_sdk.dart`, `lib/src/core/api_client.dart`, `lib/src/core/session_manager.dart`, `lib/src/core/configuration.dart`

---

### Grupo 3: Domain layer

Modelos de dominio e interfaces de repositorios.

- **Modelos**: `CardToken`, `PaymentMethod`, `Installment`, `PayerCost`, `PaymentAgreement`, `Issuer`, `IdentificationType`, `BuyerIdentification`
- Los modelos públicos conservan los datos nativos necesarios para aggregator y gateway: processing mode, merchant account, agreements, payer costs, issuer, thumbnails, labels y metadata BIN/card
- **Interfaces**: `TokenRepository`, `PaymentMethodRepository`, `InstallmentRepository`, `IssuerRepository`, `IdentificationRepository`
- **Result type**: `MercadoPagoResult<T>` sealed class con `Success(T)` y `Failure(MercadoPagoError)`
`CoreMethods` orquesta directamente estas interfaces; no existe una capa pública de clases `*UseCase`.

**Archivos clave**: `lib/src/domain/models/`, `lib/src/domain/repositories/`

---

### Grupo 4: CoreMethods

Implementación de los repositorios y exposición pública de la API de bajo nivel.

- `CardTokenRepositoryImpl`: POST `/v1/card_tokens`; incluye `device` únicamente cuando fingerprinting produce un payload no vacío
- `PaymentMethodRepositoryImpl`: GET `/cho-off/v1/payment_methods` con `bin` y `processing_mode`; `aggregator` es el default y gateway debe propagarse de extremo a extremo
- `InstallmentRepositoryImpl`: GET `/cho-off/v1/installments` con `bin`, `amount`, `processing_mode`
- `IssuerRepositoryImpl`: GET `/cho-off/v1/card_issuers` con `payment_method_id`, `bin`
- `IdentificationRepositoryImpl`: GET `/cho-off/v1/identification_types`
- `CoreMethods` clase pública: valida y coordina repositorios, fingerprinting y analytics; expone `Future<MercadoPagoResult<T>>` y exige el mismo `ProcessingMode` al resolver métodos y cuotas
- Validación Luhn local antes de POST token

**Archivos clave**: `lib/src/core_methods/`, `lib/src/data/repositories/`

---

### Grupo 5: PCI Fields

Widgets Flutter orientados a reducir la exposición accidental de datos de tarjeta.

- `CardNumberField`: captura PCI y detección BIN a 8 dígitos, alineada con los Core Methods nativos; la validación final de longitud y Luhn ocurre al enviar mediante `CoreMethods`
- `SecurityCodeField`: longitud configurable (3 o 4), estado desconocido que admite ambos y callback seguro `onFilled`
- `ExpirationDateField`: formato MM/YY automático, validación mes/año y callback seguro `onFilled`
- `PciFieldState`: contenedor en memoria; la aplicación debe pasarlo directamente y llamar `dispose()`
- El barrel público no exporta helpers de lectura/escritura; importar `lib/src/` queda fuera del contrato y el diseño no es una barrera de aislamiento absoluta
- Los widgets limpian el valor al desmontarse o al pasar la app a `inactive`/`paused`/`detached`; una tokenización exitosa limpia los controllers entregados
- La tokenización captura contadores de revisión no sensibles antes de las operaciones asíncronas de BIN/fingerprint y se abstiene de enviar si cualquier campo cambia durante la espera
- Los campos extienden `StatefulWidget`; `SecurityCodeField` oscurece el texto y los demás aplican formato/validación local
- Los errores definitivos de tarjeta se devuelven como variantes tipadas de `MercadoPagoResult` al tokenizar; los widgets no exponen callbacks de error inalcanzables

**Archivos clave**: `lib/src/pci/card_number_field.dart`, `lib/src/pci/security_code_field.dart`, `lib/src/pci/expiration_date_field.dart`, `lib/src/pci/pci_field_state.dart`, `lib/src/pci/pci_tokenizer.dart`

---

### Grupo 6: Device fingerprinting

Platform Channel que delega a DeviceSDK en Android y conserva el contrato con
un fallback vacío en iOS.

- `FingerprintService` en Dart: llama channel `mercadopago/fingerprint`
- iOS (Swift): retorna un mapa vacío determinístico, sin framework ni identificadores de fallback
- Android (Kotlin): invoca `com.mercadolibre.android.device:sdk:4.0.1` y retorna `DeviceSDK.info`; si la colección falla retorna un mapa vacío, sin fabricar un segundo schema
- `DeviceData` model en Dart: deserializa la respuesta del channel
- Si el channel falta o falla: retorna `DeviceData.empty()` sin lanzar error
- `CoreMethods` recolecta fingerprint antes de delegar al repositorio, que incluye `device` solo cuando no está vacío
- No reintroducir fingerprinting enriquecido en iOS sin revisar licencia,
  privacidad y APIs con required reason
- DeviceSDK agrega `com.google.android.gms.permission.AD_ID` al manifest Android combinado; el host es responsable de Play Data Safety, advertising ID, consentimiento y disclosures

**Archivos clave**: `lib/src/fingerprint/fingerprint_service.dart`, `android/src/main/kotlin/.../FingerprintHandler.kt`, `ios/Classes/MercadopagoSdkPlugin.swift`

---

### Grupo 7: Analytics

Auto-tracking de eventos de uso al endpoint `/tracks`.

- `AnalyticsService`: fire-and-forget, no bloquea el flujo principal
- Eventos tracked: inicialización, tokenización y consultas de CoreMethods
- Payload: `event_name`, `session_id`, `sdk_version`, `timestamp`, `event_data` (contextual)
- Errores de tracking silenciados (no deben afectar la operación principal)
- `AnalyticsService` inyectado en SDK singleton e iniciado en `initialize()`

**Archivos clave**: `lib/src/analytics/analytics_service.dart`, `lib/src/analytics/analytics_event.dart`

---

### Grupo 8: Example app + documentación

Ejemplo funcional y README de integración.

- `example/lib/main.dart`: app Flutter que demuestra CoreMethods directo con una pantalla custom usando PCI fields
- `README.md` actualizado con instalación, inicialización, uso de CoreMethods, widgets PCI y manejo de errores
- `CHANGELOG.md` con entrada v0.1.0
- `dartdoc` comments en toda la API pública

**Archivos clave**: `example/`, `README.md`, `CHANGELOG.md`

---

## Dependencies

- Ninguna dependencia de otras features (001 es la feature inicial)
- Dependencia externa: SDK nativo Android (`com.mercadolibre.android.device:sdk:4.0.1`, resuelto desde Artifactory); iOS no tiene dependencia de fingerprint

## Open questions

- [x] ~~¿Se usa `http` o `dio`?~~ → **`http`** (package:http). Más liviano, suficiente para los endpoints fijos del SDK.
- [x] ~~`DeviceFingerPrint.xcframework` para iOS~~ → retirado; el channel iOS retorna un mapa vacío.
- [x] ~~¿`X-Product-id` fijo o configurable?~~ → **Fijo**. Valor: `CVQP49FTT60D1548Q56G`.
