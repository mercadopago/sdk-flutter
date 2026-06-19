# Feature Validation: MercadoPago Flutter SDK

> Feature ID: 001
> Phase: v0.1

## Automated checks

- [ ] `flutter analyze` pasa con cero errores o warnings en `lib/`
- [ ] `dart format --output=none --set-exit-if-changed .` pasa (código formateado)
- [ ] `flutter test` pasa sin tests fallidos
- [ ] `flutter test --coverage` genera coverage ≥ 80% en `lib/src/domain/` y `lib/src/core_methods/`
- [ ] `flutter build apk` en `example/` compila sin errores (Android release build)
- [ ] `flutter build ios --no-codesign` en `example/` compila sin errores (iOS release build)

## Manual verification

### Inicialización
- [ ] Llamar `CoreMethods` sin inicializar el SDK lanza `SDKError.notInitialized`
- [ ] Inicializar con `publicKey` inválido (sin prefijo `APP_USR-`) lanza `SDKError.invalidPublicKey`
- [ ] Inicializar con `countryCode` no soportado lanza `SDKError.countryInvalid`
- [ ] Inicializar dos veces sin `setNewConfiguration` lanza `SDKError.alreadyInitialized`

### CoreMethods — Tokenización nueva tarjeta
- [ ] Con datos de tarjeta válidos (número Luhn-OK, CVV correcto, vencimiento futuro) devuelve `MercadoPagoResult.success(CardToken)` con `token` no vacío
- [ ] Con número de tarjeta con Luhn inválido devuelve `MercadoPagoResult.error` antes de hacer request HTTP
- [ ] Con vencimiento pasado devuelve `MercadoPagoResult.error(CardExpiredError)`
- [ ] El `CardToken` devuelto tiene `bin` (primeros 6 dígitos), `lastFourDigits`, y `token`

### CoreMethods — Tarjeta guardada
- [ ] `createToken(cardId, securityCode)` devuelve token válido
- [ ] CVV con longitud incorrecta devuelve error de validación local

### CoreMethods — Payment Methods
- [ ] `getPaymentMethods(bin: "4235")` devuelve lista con al menos 1 `PaymentMethod` de tipo Visa
- [ ] BIN vacío devuelve `MercadoPagoResult.error(CoreMethodsError.binIsEmpty)` sin hacer request

### CoreMethods — Installments
- [ ] `getInstallments(bin, amount: 1000.0)` devuelve lista de cuotas con `installmentAmount` y `totalAmount`
- [ ] El campo `payerCosts` contiene al menos la opción de 1 cuota

### PCI Fields
- [ ] `CardNumberField` formatea automáticamente con espacios cada 4 dígitos
- [ ] `CardNumberField.onBinChanged` se dispara al escribir el 8vo dígito
- [ ] `CardNumberField` no expone el número en texto plano a través de `toString()` o logs
- [ ] `SecurityCodeField` muestra puntos (oscurecer texto) mientras se escribe
- [ ] `ExpirationDateField` inserta `/` automáticamente después de los 2 primeros dígitos del mes
- [ ] `ExpirationDateField` rechaza mes > 12 con error inmediato
- [ ] Al hacer dispose del widget, `PciFieldState` es limpiado

### Checkout UI — CardSave
- [ ] El flujo abre `CardFormScreen`, permite completar datos y devuelve `MercadoPagoResult.success(CardSaveResult)` con token
- [ ] Tap en "cancelar" / cerrar devuelve `MercadoPagoResult.userCancelled`
- [ ] Error de red durante tokenización muestra mensaje de error recuperable con opción de reintentar

### Checkout UI — CardTransaction
- [ ] El flujo muestra `CardFormScreen` → `InstallmentScreen` → `ReviewScreen`
- [ ] `ReviewScreen` muestra el monto total correcto según la cuota seleccionada
- [ ] Resultado final incluye `token`, `installment`, `transactionAmount`, `paymentMethodId`

### Device Fingerprinting
- [ ] En build real (no simulador), el `device` object es incluido en el body del POST `/v1/card_tokens`
- [ ] En simulador sin SDK nativo disponible, la tokenización continúa sin error (fingerprint vacío)

### Analytics
- [ ] El evento `sdk_initialize` es enviado (fire-and-forget) al inicializar el SDK
- [ ] El evento `core_methods_tokenize` es enviado después de una tokenización exitosa
- [ ] Un error en el tracking no interrumpe el flujo principal

### Headers HTTP
- [ ] Todos los requests incluyen `Meli-Session-id` con un UUID válido
- [ ] Todos los requests incluyen `X-Product-id`
- [ ] Todos los GET requests incluyen `public_key` como query param

## Test coverage

- [ ] `CreateCardTokenUseCase` — test con datos válidos, Luhn inválido, CVV inválido, vencimiento pasado
- [ ] `GetPaymentMethodsUseCase` — test con BIN válido, BIN vacío, respuesta HTTP 400
- [ ] `GetInstallmentsUseCase` — test con amount positivo, amount cero
- [ ] `ApiClient` — test de headers obligatorios presentes en cada request
- [ ] `SessionManager` — test que el UUID cambia entre reinits
- [ ] `Configuration` — test de validación de publicKey y countryCode
- [ ] `CardNumberField` (widget test) — test de formato, BIN detection callback, Luhn feedback
- [ ] `ExpirationDateField` (widget test) — test de inserción automática de `/`, rechazo mes inválido

## Spec alignment

- [ ] Todos los grupos del `plan.md` tienen al menos un archivo de implementación correspondiente
- [ ] Los `Key decisions` de `requirements.md` están reflejados en el código (HTTP client elegido, sin DI externo, etc.)
- [ ] Los constraints de `requirements.md` verificables con grep: ningún `dart:mirrors`, ningún `SharedPreferences` para card data, ningún `print(cardNumber)`

## Review checklist

- [ ] No hay secrets ni credenciales de test en el código fuente
- [ ] `lib/mercadopago_sdk.dart` exporta solo la API pública (nada de `src/`)
- [ ] `README.md` documenta instalación, inicialización, CoreMethods, Checkout, y manejo de errores
- [ ] `CHANGELOG.md` tiene entrada para v0.1.0
- [ ] `pubspec.yaml` tiene `description` válida (> 60 chars recomendado para pub.dev score)
- [ ] `example/` app corre sin errores y demuestra los 3 flujos principales
- [ ] ProGuard rules para Android están en `android/proguard-rules.pro`
- [ ] No hay `TODO` ni `FIXME` pendientes en `lib/` al momento del merge
