/// PCI capture and tokenization.
///
/// Everything that can observe a raw PAN or CVV lives in **this one library**,
/// so the values are kept in by Dart's library privacy — enforced by the
/// compiler — rather than by an `@internal` annotation, which is only an
/// analyzer hint and does not stop a consuming app from importing
/// `package:mercadopago/src/...` and calling the helper.
///
/// The invariant this library exists to hold: **no symbol reachable from
/// outside returns a raw value** — not as a `String`, not inside a request
/// object, not as JSON. Calling [PciTokenizer] is fine (that is what the SDK
/// is for); extracting the card number is not.
///
/// CONTRIBUTORS: part files cannot declare their own imports (the
/// `enhanced-parts` language feature is still experimental in Dart 3.12, and
/// enabling it would require an `--enable-experiment` flag in every consuming
/// app). Add every new import here, and keep new top-level declarations
/// private unless `test/pci/pci_public_surface_test.dart` is updated too.
library;

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/luhn.dart';
import '../data/dtos/card_token_dto.dart';
import '../domain/errors.dart';
import '../domain/models/buyer_identification.dart';
import '../domain/models/card_token.dart';
import '../domain/models/device_data.dart';
import '_formatters.dart';

part 'card_number_field.dart';
part 'expiration_date_field.dart';
part 'pci_field_state.dart';
part 'pci_token_repository.dart';
part 'pci_tokenizer.dart';
part 'security_code_field.dart';
