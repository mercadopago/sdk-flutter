import 'constants.dart';
import 'sdk_error.dart';

/// Countries where MercadoPago operates and which the SDK supports.
///
/// The string value is the ISO 3-letter code expected by the API.
enum Country {
  argentina('ARG'),
  brazil('BRA'),
  chile('CHL'),
  colombia('COL'),
  mexico('MEX'),
  peru('PER'),
  uruguay('URY');

  const Country(this.code);

  final String code;

  /// MercadoLibre site identifier for this country, used in the analytics
  /// `application.site_id` field. Mirrors the native Android `SiteIdMapper`
  /// (the authoritative mapping — note the native iOS SDK maps `COL` to `MLC`,
  /// which is a bug: it collides with Chile; the correct value is `MCO`).
  String get siteId => switch (this) {
        Country.argentina => 'MLA',
        Country.brazil => 'MLB',
        Country.chile => 'MLC',
        Country.colombia => 'MCO',
        Country.mexico => 'MLM',
        Country.peru => 'MPE',
        Country.uruguay => 'MLU',
      };

  /// Resolves a [Country] from its ISO 3-letter code. Case-insensitive.
  ///
  /// Throws [SDKInvalidCountryError] if the code is not supported.
  static Country fromCode(String code) {
    final upper = code.toUpperCase();
    for (final c in Country.values) {
      if (c.code == upper) return c;
    }
    throw SDKInvalidCountryError(code);
  }
}

/// Immutable configuration describing the active SDK environment.
class Configuration {
  Configuration({
    required this.publicKey,
    required this.country,
    this.locale,
  }) {
    if (!kPublicKeyPattern.hasMatch(publicKey)) {
      throw const SDKInvalidPublicKeyError();
    }
  }

  /// Factory that accepts the raw country code string and validates it.
  factory Configuration.fromValues({
    required String publicKey,
    required String countryCode,
    String? locale,
  }) {
    return Configuration(
      publicKey: publicKey,
      country: Country.fromCode(countryCode),
      locale: locale,
    );
  }

  final String publicKey;
  final Country country;
  final String? locale;

  @override
  String toString() =>
      'Configuration(country: ${country.code}, locale: ${locale ?? 'auto'})';
}
