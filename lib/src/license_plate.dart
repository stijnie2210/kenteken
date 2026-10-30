import 'sidecode.dart';

final _separators = RegExp(r'[\s-]');
final _sixLettersOrDigits = RegExp(r'^[A-Z0-9]{6}$');

/// A Dutch licence plate (kenteken) whose layout fits one of the sidecodes.
///
/// A plate that parses has a valid layout. Whether RDW ever issued it is
/// something only an RDW lookup can tell.
final class LicensePlate {
  const LicensePlate._(this.normalized, this.sidecode);

  /// Parses [input], ignoring case, spaces and dashes.
  ///
  /// Throws a [FormatException] if [input] fits no sidecode.
  factory LicensePlate.parse(String input) =>
      tryParse(input) ??
      (throw FormatException('Not a Dutch licence plate', input));

  /// Parses [input], ignoring case, spaces and dashes.
  ///
  /// Returns `null` if [input] fits no sidecode.
  static LicensePlate? tryParse(String input) {
    final normalized = input.toUpperCase().replaceAll(_separators, '');
    if (!_sixLettersOrDigits.hasMatch(normalized)) return null;
    return switch (Sidecode.match(normalized)) {
      final sidecode? => LicensePlate._(normalized, sidecode),
      null => null,
    };
  }

  /// Whether [input] fits a sidecode, ignoring case, spaces and dashes.
  static bool isValid(String input) => tryParse(input) != null;

  /// The plate in upper case without dashes, for example `84XXPJ`.
  ///
  /// This is the form RDW uses.
  final String normalized;

  /// The layout of this plate.
  final Sidecode sidecode;

  /// The plate with dashes where its sidecode puts them, for example
  /// `84-XX-PJ`.
  String get formatted => sidecode.format(normalized);

  @override
  bool operator ==(Object other) =>
      other is LicensePlate && other.normalized == normalized;

  @override
  int get hashCode => normalized.hashCode;

  @override
  String toString() => formatted;
}
