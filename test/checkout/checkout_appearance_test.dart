import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago_flutter_sdk/mercadopago_flutter_sdk.dart';

void main() {
  group('MPCheckoutAppearance.themeFor', () {
    test('defaults to system mode', () {
      const appearance = MPCheckoutAppearance();
      expect(appearance.themeMode, ThemeMode.system);
    });

    test('system mode follows the platform brightness', () {
      const appearance = MPCheckoutAppearance();
      expect(
        appearance.themeFor(Brightness.dark).colorScheme.brightness,
        Brightness.dark,
      );
      expect(
        appearance.themeFor(Brightness.light).colorScheme.brightness,
        Brightness.light,
      );
    });

    test('light mode forces light regardless of platform', () {
      const appearance = MPCheckoutAppearance(themeMode: ThemeMode.light);
      expect(
        appearance.themeFor(Brightness.dark).colorScheme.brightness,
        Brightness.light,
      );
    });

    test('dark mode forces dark regardless of platform', () {
      const appearance = MPCheckoutAppearance(themeMode: ThemeMode.dark);
      expect(
        appearance.themeFor(Brightness.light).colorScheme.brightness,
        Brightness.dark,
      );
    });

    test('produces a Material 3 theme seeded by primaryColor', () {
      const appearance =
          MPCheckoutAppearance(primaryColor: Color(0xFFAA0000));
      final theme = appearance.themeFor(Brightness.light);
      expect(theme.useMaterial3, isTrue);
    });
  });
}
