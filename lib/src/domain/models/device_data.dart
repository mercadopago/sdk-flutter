/// Opaque device fingerprint emitted by the native Platform Channel.
///
/// The exact shape is defined by the native fingerprinting SDK and is not
/// interpreted by Dart code — it is forwarded verbatim to the tokenization
/// endpoint under the `device` key.
class DeviceData {
  const DeviceData(this.raw);

  /// Sentinel used when the native SDK is unavailable (e.g. simulator).
  /// Tokenization continues without device data.
  const DeviceData.empty() : raw = const <String, dynamic>{};

  final Map<String, dynamic> raw;

  bool get isEmpty => raw.isEmpty;

  Map<String, dynamic> toJson() => raw;
}
