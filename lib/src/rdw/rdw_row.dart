/// A record from RDW open data, with readers for the way RDW writes values.
///
/// RDW sends every value as a string: dates as `20270531`, yes/no as `Ja` and
/// `Nee`, and missing values as `Niet geregistreerd` or `N.v.t.`. Fields
/// without a value are left out of the record.
extension type const RdwRow(Map<String, Object?> json) {
  static const _noValue = {
    'Niet geregistreerd',
    'N.v.t.',
    'Geen verstrekking in Open Data',
  };

  /// The value of [key], or `null` if RDW has no value for it.
  String? text(String key) {
    final text = json[key]?.toString().trim();
    return text == null || text.isEmpty || _noValue.contains(text)
        ? null
        : text;
  }

  /// The value of [key]; throws a [FormatException] if it is missing.
  String requiredText(String key) =>
      text(key) ?? (throw FormatException('RDW record has no $key', json));

  /// The value of [key] as a whole number, or `null` if it has none.
  int? integer(String key) => switch (text(key)) {
    final text? => int.tryParse(text),
    null => null,
  };

  /// The value of [key] as a number, or `null` if it has none.
  double? decimal(String key) => switch (text(key)) {
    final text? => double.tryParse(text),
    null => null,
  };

  /// A date written as `yyyyMMdd`, as a UTC date at midnight.
  DateTime? date(String key) {
    final text = this.text(key);
    if (text == null || !RegExp(r'^\d{8}$').hasMatch(text)) return null;
    return DateTime.utc(
      int.parse(text.substring(0, 4)),
      int.parse(text.substring(4, 6)),
      int.parse(text.substring(6, 8)),
    );
  }

  /// `Ja` as `true`, `Nee` as `false`, anything else as `null`.
  bool? yesNo(String key) => switch (text(key)) {
    'Ja' => true,
    'Nee' => false,
    _ => null,
  };

  /// Like [yesNo], but throws a [FormatException] for anything other than
  /// `Ja` or `Nee`.
  bool requiredYesNo(String key) =>
      yesNo(key) ??
      (throw FormatException('RDW record has no yes/no value for $key', json));
}
