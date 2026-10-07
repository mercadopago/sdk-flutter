/// SDK-wide constants. Centralized here so they are easy to audit and update.
library;

/// Product identifier sent according to each endpoint contract.
///
/// CoreMethods GETs use the `product_id` query parameter, tokenization POSTs
/// use `X-Product-id`, and identification-types requests omit it.
const String kProductId = 'CVQP49FTT60D1548Q56G';

/// Current SDK version. Must stay in sync with `pubspec.yaml`.
const String kSdkVersion = '0.1.0';

/// Base URL for the MercadoPago payments API.
const String kApiBaseUrl = 'https://api.mercadopago.com';

/// Base URL for the MercadoLibre tracks (analytics) endpoint.
const String kTracksUrl = 'https://api.mercadolibre.com/tracks';

/// Platform dimension reported in the analytics `device.platform` field. This
/// is a new value (the native SDKs report `/mobile/android` and `/mobile/ios`);
/// the Data Studio dashboard must add `/mobile/flutter` as a recognized
/// platform so Flutter events are not bucketed as UNKNOWN.
const String kAnalyticsPlatform = '/mobile/flutter';

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

/// Public-key validation pattern. Production keys use `APP_USR-*`; testing
/// credentials use `TEST-*`.
/// Length is bounded to reject clearly malformed input before the network call.
final RegExp kPublicKeyPattern = RegExp(
  r'^(?:APP_USR|TEST)-[A-Za-z0-9-]{10,200}$',
);
