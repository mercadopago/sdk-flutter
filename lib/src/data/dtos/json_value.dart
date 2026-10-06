typedef JsonObjectMapper<T> = T Function(Map<String, dynamic> json);

String requiredString(
  Map<String, dynamic> json,
  String key, {
  String? fieldName,
}) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) return value;
  throw FormatException(
    "Response field '${fieldName ?? key}' must be a non-empty string.",
  );
}

String? optionalString(
  Map<String, dynamic> json,
  String key, {
  String? fieldName,
}) {
  final value = json[key];
  if (value == null) return null;
  if (value is String && value.trim().isNotEmpty) return value;
  throw FormatException(
    "Response field '${fieldName ?? key}' must be a non-empty string when present.",
  );
}

/// Reads an optional string while accepting the empty-string sentinel used by
/// some native CoreMethods responses.
///
/// Missing, null, empty, and whitespace-only values are normalized to null.
/// A present value of any other type still fails closed.
String? optionalStringOrNullWhenBlank(
  Map<String, dynamic> json,
  String key, {
  String? fieldName,
}) {
  final value = json[key];
  if (value == null) return null;
  if (value is String) return value.trim().isEmpty ? null : value;
  throw FormatException(
    "Response field '${fieldName ?? key}' must be a string when present.",
  );
}

/// Reads an identifier represented by either a JSON string or integer.
///
/// Native CoreMethods contracts disagree on some identifier types. Converting
/// integers to their decimal representation preserves the value while keeping
/// string identifiers lossless (including leading zeroes and non-digits).
String? optionalStringOrInteger(
  Map<String, dynamic> json,
  String key, {
  String? fieldName,
}) {
  final value = json[key];
  if (value == null) return null;
  if (value is String) return value.trim().isEmpty ? null : value;
  if (value is int) return value.toString();
  throw FormatException(
    "Response field '${fieldName ?? key}' must be a string or integer when present.",
  );
}

/// Reads an optional boolean, returning null when the key is absent.
bool? optionalBool(Map<String, dynamic> json, String key, {String? fieldName}) {
  final value = json[key];
  if (value == null) return null;
  if (value is bool) return value;
  throw FormatException(
    "Response field '${fieldName ?? key}' must be a boolean when present.",
  );
}

/// Reads an optional integer array, returning an empty list when absent.
List<int> optionalIntList(
  Map<String, dynamic> json,
  String key, {
  String? fieldName,
}) {
  final name = fieldName ?? key;
  final value = json[key];
  if (value == null) return const [];
  if (value is! List<dynamic>) {
    throw FormatException("Response field '$name' must be a JSON array.");
  }
  return [
    for (var index = 0; index < value.length; index++)
      if (value[index] is int)
        value[index] as int
      else
        throw FormatException(
          "Response field '$name[$index]' must be an integer.",
        ),
  ];
}

/// Reads an optional integer, returning null when the key is absent.
/// A present-but-malformed value still throws — absence and corruption are
/// different failures and only the first one is tolerated.
int? optionalInt(
  Map<String, dynamic> json,
  String key, {
  String? fieldName,
  bool allowNumericString = false,
}) {
  if (json[key] == null) return null;
  return requiredInt(
    json,
    key,
    fieldName: fieldName,
    allowNumericString: allowNumericString,
  );
}

/// Reads an optional finite number, returning null when the key is absent.
double? optionalDouble(
  Map<String, dynamic> json,
  String key, {
  String? fieldName,
  bool allowNumericString = false,
}) {
  if (json[key] == null) return null;
  return requiredDouble(
    json,
    key,
    fieldName: fieldName,
    allowNumericString: allowNumericString,
  );
}

/// Reads an optional string array, returning an empty list when absent.
List<String> optionalStringList(
  Map<String, dynamic> json,
  String key, {
  String? fieldName,
}) {
  if (json[key] == null) return const [];
  return requiredStringList(json, key, fieldName: fieldName);
}

Map<String, dynamic> requiredMap(
  Map<String, dynamic> json,
  String key, {
  String? fieldName,
}) {
  final value = json[key];
  if (value is Map<String, dynamic>) return value;
  throw FormatException(
    "Response field '${fieldName ?? key}' must be a JSON object.",
  );
}

/// Reads an optional JSON object, returning null when the key is absent.
Map<String, dynamic>? optionalMap(
  Map<String, dynamic> json,
  String key, {
  String? fieldName,
}) {
  if (json[key] == null) return null;
  return requiredMap(json, key, fieldName: fieldName);
}

int requiredInt(
  Map<String, dynamic> json,
  String key, {
  String? fieldName,
  bool allowNumericString = false,
}) {
  final value = json[key];
  if (value is int) return value;
  if (value is num && value.isFinite && value == value.truncateToDouble()) {
    return value.toInt();
  }
  if (allowNumericString && value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException(
    "Response field '${fieldName ?? key}' must be an integer.",
  );
}

double requiredDouble(
  Map<String, dynamic> json,
  String key, {
  String? fieldName,
  bool allowNumericString = false,
}) {
  final value = json[key];
  if (value is num && value.isFinite) return value.toDouble();
  if (allowNumericString && value is String) {
    final parsed = double.tryParse(value);
    if (parsed != null && parsed.isFinite) return parsed;
  }
  throw FormatException(
    "Response field '${fieldName ?? key}' must be a finite number.",
  );
}

List<String> requiredStringList(
  Map<String, dynamic> json,
  String key, {
  String? fieldName,
}) {
  final name = fieldName ?? key;
  final value = json[key];
  if (value is! List<dynamic>) {
    throw FormatException("Response field '$name' must be a JSON array.");
  }
  return [
    for (var index = 0; index < value.length; index++)
      if (value[index] is String && (value[index] as String).trim().isNotEmpty)
        value[index] as String
      else
        throw FormatException(
          "Response field '$name[$index]' must be a non-empty string.",
        ),
  ];
}

List<T> mapJsonObjectList<T>(
  List<dynamic> values,
  String fieldName,
  JsonObjectMapper<T> mapper,
) => [
  for (var index = 0; index < values.length; index++)
    if (values[index] is Map<String, dynamic>)
      mapper(values[index] as Map<String, dynamic>)
    else
      throw FormatException(
        "Response field '$fieldName[$index]' must be a JSON object.",
      ),
];

List<T> requiredObjectList<T>(
  Map<String, dynamic> json,
  String key,
  JsonObjectMapper<T> mapper, {
  String? fieldName,
}) {
  final name = fieldName ?? key;
  final value = json[key];
  if (value is! List<dynamic>) {
    throw FormatException("Response field '$name' must be a JSON array.");
  }
  return mapJsonObjectList(value, name, mapper);
}
