import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pub_semver/pub_semver.dart';

/// Reads the `<key>: "<constraint>"` entry from the `environment:` block of
/// [path], relative to the package root where `flutter test` runs.
VersionConstraint _environment(String path, String key) {
  final pubspec = File(path).readAsStringSync();
  final block = RegExp(
    r'^environment:\n((?:[ \t]+\S.*\n)+)',
    multiLine: true,
  ).firstMatch(pubspec);
  if (block == null) fail('no environment block in $path');
  final entry = RegExp(
    '^\\s+$key:\\s*"([^"]+)"',
    multiLine: true,
  ).firstMatch(block.group(1)!);
  if (entry == null) fail('no environment.$key in $path');
  return VersionConstraint.parse(entry.group(1)!);
}

// GHSA-frr6-h895-5pxp: Dart's bundled trust store on Android trusts
// compromised eMudhra intermediate CAs. The versions below come from the
// advisory and Flutter's release list; the betas sort between the patched
// 3.13.7 stable and 3.14.0, so a lower bound of 3.13.7 would admit them.
final _vulnerableDart = [
  '3.12.2', // Flutter 3.44.2, the previous minimum
  '3.13.5', // Flutter 3.47.7
  '3.14.0-95.2.beta', // Flutter 3.48.0-0.x.pre
  '3.14.0-211.1.beta', // Flutter 3.49.0-0.x.pre
  '3.14.0-315.1.beta', // Flutter 3.50.0-0.1.pre
];
final _patchedDart = [
  '3.14.0-315.3.beta', // Flutter 3.50.0-0.2.pre, first patched beta
  '3.14.0', // Flutter 3.50.0
];
final _vulnerableFlutter = [
  '3.44.2',
  '3.47.7',
  '3.48.0-0.5.pre',
  '3.49.0-0.2.pre',
  '3.50.0-0.1.pre',
];
final _patchedFlutter = ['3.50.0-0.2.pre', '3.50.0'];

void main() {
  for (final pubspec in ['pubspec.yaml', 'example/pubspec.yaml']) {
    group('$pubspec toolchain constraints', () {
      final dart = _environment(pubspec, 'sdk');
      final flutter = _environment(pubspec, 'flutter');

      for (final version in _vulnerableDart) {
        test('rejects vulnerable Dart $version', () {
          expect(dart.allows(Version.parse(version)), isFalse);
        });
      }
      for (final version in _patchedDart) {
        test('accepts patched Dart $version', () {
          expect(dart.allows(Version.parse(version)), isTrue);
        });
      }
      for (final version in _vulnerableFlutter) {
        test('rejects vulnerable Flutter $version', () {
          expect(flutter.allows(Version.parse(version)), isFalse);
        });
      }
      for (final version in _patchedFlutter) {
        test('accepts patched Flutter $version', () {
          expect(flutter.allows(Version.parse(version)), isTrue);
        });
      }
    });
  }
}
