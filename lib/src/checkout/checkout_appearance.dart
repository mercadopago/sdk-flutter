import 'package:flutter/material.dart';

/// Visual configuration for the hosted checkout UI.
///
/// [themeMode] mirrors the native SDKs' `System`/`Light`/`Dark` interface style
/// (Flutter's own [ThemeMode]): the default [ThemeMode.system] follows the
/// device's light/dark setting automatically. [primaryColor] seeds a Material 3
/// color scheme.
class MPCheckoutAppearance {
  const MPCheckoutAppearance({
    this.themeMode = ThemeMode.system,
    this.primaryColor,
  });

  /// How the checkout resolves light vs. dark. [ThemeMode.system] adapts to the
  /// device; [ThemeMode.light]/[ThemeMode.dark] force a mode.
  final ThemeMode themeMode;

  /// Seed color for the Material 3 scheme. Defaults to MercadoPago blue.
  final Color? primaryColor;

  /// Analytics value for the `appearance` track field (`system`/`light`/`dark`).
  String get analyticsStyle => switch (themeMode) {
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
      };

  /// Analytics `seller_customization` list: `['customized_token']` when a custom
  /// [primaryColor] is set, otherwise empty (mirrors the native SDKs).
  List<String> get sellerCustomization =>
      primaryColor != null ? const ['customized_token'] : const [];

  /// Builds the effective [ThemeData], resolving [ThemeMode.system] against the
  /// supplied [platformBrightness] (the device setting).
  ThemeData themeFor(Brightness platformBrightness) {
    final brightness = switch (themeMode) {
      ThemeMode.system => platformBrightness,
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
    };
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryColor ?? const Color(0xFF009EE3),
      brightness: brightness,
    );
    return ThemeData(useMaterial3: true, colorScheme: scheme);
  }
}
