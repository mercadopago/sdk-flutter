/// SDK-wide constants. Centralized here so they are easy to audit and update.
library;

/// Product identifier sent in the `X-Product-id` header on every request.
///
/// TODO: replace with the official identifier provided by MercadoPago before
/// the first stable release (v1.0). The current value is a placeholder used
/// during development.
const String kProductId = 'MP_FLUTTER_SDK_001';

/// Current SDK version. Must stay in sync with `pubspec.yaml`.
const String kSdkVersion = '0.1.0';

/// Base URL for the MercadoPago payments API.
const String kApiBaseUrl = 'https://api.mercadopago.com';

/// Base URL for the MercadoLibre tracks (analytics) endpoint.
const String kTracksUrl = 'https://api.mercadolibre.com/tracks';

/// Default timeout applied to every HTTP request.
const Duration kHttpTimeout = Duration(seconds: 30);

/// Time-to-live for cached GET responses.
const Duration kCacheTtl = Duration(minutes: 5);

/// HTTP header keys.
const String kHeaderProductId = 'X-Product-id';
const String kHeaderSessionId = 'Meli-Session-id';
const String kHeaderSdkVersion = 'SDK-version';
const String kHeaderContentType = 'Content-Type';
const String kHeaderUserAgent = 'User-Agent';

const String kContentTypeJson = 'application/json';

/// Public-key validation pattern. Public keys are issued as `APP_USR-{alphanum}`.
final RegExp kPublicKeyPattern = RegExp(r'^APP_USR-[A-Za-z0-9]+$');
