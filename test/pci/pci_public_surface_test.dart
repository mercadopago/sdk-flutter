import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the PCI library's public surface.
///
/// Every public symbol in `lib/src/pci/` is reachable by any consuming app via
/// `import 'package:mercadopago_sdk_flutter/src/pci/pci.dart'` — `lib/src/` is a pub
/// packaging convention, not a language boundary. The library's whole purpose
/// is that none of those symbols can hand out a raw PAN or CVV, so a new public
/// symbol appearing here needs a deliberate review.
///
/// This is intentionally a text check rather than an AST walk: CI already runs
/// `dart format --set-exit-if-changed`, which guarantees every top-level
/// declaration starts at column 0. It catches the shape of regression that
/// actually happened — a new public top-level helper sitting next to the
/// private state — at a fraction of the cost.
void main() {
  /// Public symbols the PCI library is allowed to expose.
  ///
  /// Adding to this list means asserting that the symbol cannot return, or
  /// hand to a caller-supplied sink, a raw card value. Say why in the PR.
  const allowedPublicSymbols = {
    // The controller. Exposes only `length`, `clear()`, `dispose()`.
    'PciFieldState',
    // The three SDK-owned inputs. They write into the controller; they do not
    // expose what they wrote.
    'CardNumberField',
    'SecurityCodeField',
    'ExpirationDateField',
    // Reads the values and returns only errors, non-sensitive revision
    // counters, or an opaque CardToken.
    'PciTokenizer',
    // Assembles and sends the token request. Returns only a CardToken.
    'CardTokenRepositoryImpl',
    // Write-only, debug-only test seed. Never returns a value.
    'debugSeedPciField',
  };

  const allowedParts = {
    'card_number_field.dart',
    'expiration_date_field.dart',
    'pci_field_state.dart',
    'pci_token_repository.dart',
    'pci_tokenizer.dart',
    'security_code_field.dart',
  };

  final libraryFile = File('lib/src/pci/pci.dart');

  test('the PCI library exposes only the reviewed public symbols', () {
    final found = <String, String>{};

    for (final name in allowedParts.followedBy(const ['pci.dart'])) {
      final file = File('lib/src/pci/$name');
      if (!file.existsSync()) continue;
      for (final symbol in _publicTopLevelSymbols(file.readAsLinesSync())) {
        found[symbol] = name;
      }
    }

    final unexpected = found.keys.toSet().difference(allowedPublicSymbols);
    expect(
      unexpected,
      isEmpty,
      reason:
          'New public symbol(s) in the PCI library: '
          '${unexpected.map((s) => '$s (${found[s]})').join(', ')}.\n'
          'Every public symbol here can be reached by any consuming app via '
          "import 'package:mercadopago_sdk_flutter/src/pci/pci.dart'. If it can return a "
          'PAN or CVV — directly, inside an object, or by handing it to a sink '
          'the caller supplies — make it private. If it is genuinely safe, add '
          'it to allowedPublicSymbols and justify it in the PR.',
    );

    // Also fail if an allowed symbol disappears, so the list cannot rot.
    expect(
      allowedPublicSymbols.difference(found.keys.toSet()),
      isEmpty,
      reason: 'Allowlisted symbol(s) no longer exist — prune the allowlist.',
    );
  });

  test('the set of part files is the reviewed one', () {
    final declared = libraryFile
        .readAsLinesSync()
        .map((line) => RegExp(r"^part\s+'([^']+)';").firstMatch(line)?.group(1))
        .whereType<String>()
        .toSet();

    expect(
      declared,
      allowedParts,
      reason:
          'The PCI library part list changed. A new part shares this '
          "library's privacy, so its symbols must be reviewed too: add the "
          'file here and re-check the public-symbol allowlist above.',
    );
  });
}

/// Extracts public top-level declaration names from Dart source lines.
///
/// Relies on `dart format`: top-level declarations begin at column 0, while
/// class members are indented. Directives, annotations and comments are
/// skipped, as are private (`_`-prefixed) names.
Iterable<String> _publicTopLevelSymbols(List<String> lines) {
  final declaration = RegExp(
    r'^(?:(?:abstract|base|final|sealed|interface|mixin)\s+)*'
    r'(?:class|enum|mixin|extension|typedef)\s+(\w+)',
  );
  // A top-level function or variable: the identifier before `(` or `=`.
  final function = RegExp(r'^[\w$<>,?\[\]\. ]+?\s(\w+)\s*\(');
  final variable = RegExp(r'^(?:final|const)\s+[\w$<>,?\[\]\. ]*?\s?(\w+)\s*=');

  return lines.expand((line) {
    if (line.isEmpty || !RegExp(r'^[A-Za-z]').hasMatch(line)) return const [];
    if (RegExp(r'^(import|export|part|library)\b').hasMatch(line)) {
      return const [];
    }
    final name =
        declaration.firstMatch(line)?.group(1) ??
        function.firstMatch(line)?.group(1) ??
        variable.firstMatch(line)?.group(1);
    if (name == null || name.startsWith('_')) return const [];
    return [name];
  });
}
