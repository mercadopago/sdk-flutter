import 'package:flutter/material.dart';

/// Visual configuration for the hosted checkout UI.
class MPCheckoutAppearance {
  const MPCheckoutAppearance({
    this.brightness = Brightness.light,
    this.primaryColor,
  });

  final Brightness brightness;
  final Color? primaryColor;

  ThemeData toTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryColor ?? const Color(0xFF009EE3),
      brightness: brightness,
    );
    return ThemeData(useMaterial3: true, colorScheme: scheme);
  }
}
