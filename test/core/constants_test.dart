import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago_sdk_flutter/src/core/constants.dart';

/// Reads the first `<key> <value>` line matched by [pattern] from [path],
/// relative to the package root where `flutter test` runs.
String _versionIn(String path, RegExp pattern) {
  final match = pattern.firstMatch(File(path).readAsStringSync());
  if (match == null) fail('no version found in $path');
  return match.group(1)!;
}

void main() {
  // kSdkVersion feeds the SDK-version and User-Agent headers and analytics, so
  // a release that forgets to bump it reports itself as the previous version.
  group('kSdkVersion', () {
    test('matches the pubspec.yaml package version', () {
      expect(
        kSdkVersion,
        _versionIn(
          'pubspec.yaml',
          RegExp(r'^version:\s*(\S+)', multiLine: true),
        ),
      );
    });

    test('matches the Android plugin Gradle version', () {
      expect(
        kSdkVersion,
        _versionIn(
          'android/build.gradle',
          RegExp(r"^version\s+'([^']+)'", multiLine: true),
        ),
      );
    });
  });
}
