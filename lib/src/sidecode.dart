/// The layout of a Dutch licence plate.
///
/// In a [pattern], `X` stands for a letter and `9` for a digit. The dashes
/// show where the plate is split when it is written down.
enum Sidecode {
  /// `XX-99-99`.
  s1(1, 'XX-99-99'),

  /// `99-99-XX`.
  s2(2, '99-99-XX'),

  /// `99-XX-99`.
  s3(3, '99-XX-99'),

  /// `XX-99-XX`.
  s4(4, 'XX-99-XX'),

  /// `XX-XX-99`.
  s5(5, 'XX-XX-99'),

  /// `99-XX-XX`.
  s6(6, '99-XX-XX'),

  /// `99-XXX-9`.
  s7(7, '99-XXX-9'),

  /// `9-XXX-99`.
  s8(8, '9-XXX-99'),

  /// `XX-999-X`.
  s9(9, 'XX-999-X'),

  /// `X-999-XX`.
  s10(10, 'X-999-XX'),

  /// `XXX-99-X`.
  s11(11, 'XXX-99-X'),

  /// `X-99-XXX`.
  s12(12, 'X-99-XXX'),

  /// `9-XX-999`.
  s13(13, '9-XX-999'),

  /// `999-XX-9`.
  s14(14, '999-XX-9');

  const Sidecode(this.number, this.pattern);

  /// The sidecode number RDW uses, 1 to 14.
  final int number;

  /// The layout, for example `99-XX-XX`.
  final String pattern;

  String get _shape => pattern.replaceAll('-', '');

  /// The sidecode whose layout fits [normalized], or `null` if none does.
  ///
  /// [normalized] must already be six upper-case letters and digits without
  /// dashes. Only the order of letters and digits is checked, not whether
  /// RDW actually hands out those letters.
  static Sidecode? match(String normalized) {
    final shape = normalized
        .replaceAll(RegExp('[A-Z]'), 'X')
        .replaceAll(RegExp('[0-9]'), '9');
    for (final sidecode in values) {
      if (sidecode._shape == shape) return sidecode;
    }
    return null;
  }

  /// Writes [normalized] with dashes in the places this layout puts them.
  String format(String normalized) {
    final buffer = StringBuffer();
    var index = 0;
    for (final char in pattern.split('')) {
      buffer.write(char == '-' ? '-' : normalized[index++]);
    }
    return buffer.toString();
  }
}
