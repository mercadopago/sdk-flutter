import 'package:uuid/uuid.dart';

/// Owns the session UUID sent in the `Meli-Session-id` header.
///
/// A new UUID is generated when [regenerate] is called, which happens during
/// [MercadoPagoSDK.initialize] and [MercadoPagoSDK.setNewConfiguration].
class SessionManager {
  SessionManager({Uuid? uuid}) : _uuid = uuid ?? const Uuid() {
    regenerate();
  }

  final Uuid _uuid;
  late String _sessionId;

  String get sessionId => _sessionId;

  void regenerate() {
    _sessionId = _uuid.v4();
  }
}
