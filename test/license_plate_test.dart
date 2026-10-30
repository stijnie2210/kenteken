import 'package:kenteken/kenteken.dart';
import 'package:test/test.dart';

void main() {
  group('LicensePlate.tryParse', () {
    const examples = {
      Sidecode.s1: ('AB1234', 'AB-12-34'),
      Sidecode.s2: ('1234AB', '12-34-AB'),
      Sidecode.s3: ('12AB34', '12-AB-34'),
      Sidecode.s4: ('AB12CD', 'AB-12-CD'),
      Sidecode.s5: ('ABCD12', 'AB-CD-12'),
      Sidecode.s6: ('12ABCD', '12-AB-CD'),
      Sidecode.s7: ('12ABC3', '12-ABC-3'),
      Sidecode.s8: ('1ABC23', '1-ABC-23'),
      Sidecode.s9: ('AB123C', 'AB-123-C'),
      Sidecode.s10: ('A123BC', 'A-123-BC'),
      Sidecode.s11: ('ABC12D', 'ABC-12-D'),
      Sidecode.s12: ('A12BCD', 'A-12-BCD'),
      Sidecode.s13: ('1AB234', '1-AB-234'),
      Sidecode.s14: ('123AB4', '123-AB-4'),
    };

    for (final MapEntry(key: sidecode, value: (normalized, formatted))
        in examples.entries) {
      test('recognises sidecode ${sidecode.number} (${sidecode.pattern})', () {
        final plate = LicensePlate.tryParse(normalized)!;
        expect(plate.sidecode, sidecode);
        expect(plate.normalized, normalized);
        expect(plate.formatted, formatted);
      });
    }

    test('covers every sidecode', () {
      expect(examples.keys, unorderedEquals(Sidecode.values));
    });

    test('ignores case, spaces and dashes', () {
      for (final input in ['84-xx-pj', ' 84 XX PJ ', '84xxpj', '8-4XXP-J']) {
        expect(
          LicensePlate.tryParse(input)?.normalized,
          '84XXPJ',
          reason: input,
        );
      }
    });

    test('rejects input that fits no sidecode', () {
      for (final input in [
        '',
        'ABCDEF',
        '123456',
        'AB12345',
        'AB123',
        'A1B2C3',
        '84-XX-P!',
        'ÄB1234',
      ]) {
        expect(LicensePlate.tryParse(input), isNull, reason: input);
      }
    });
  });

  test('LicensePlate.parse throws a FormatException for invalid input', () {
    expect(() => LicensePlate.parse('nope'), throwsFormatException);
    expect(LicensePlate.parse('84-XX-PJ').normalized, '84XXPJ');
  });

  test('LicensePlate.isValid', () {
    expect(LicensePlate.isValid('84-XX-PJ'), isTrue);
    expect(LicensePlate.isValid('84-XX-P'), isFalse);
  });

  test('plates are equal by their normalized form', () {
    expect(LicensePlate.parse('84-xx-pj'), LicensePlate.parse('84XXPJ'));
    expect({
      LicensePlate.parse('84XXPJ'),
      LicensePlate.parse('84-XX-PJ'),
    }, hasLength(1));
    expect(LicensePlate.parse('84XXPJ').toString(), '84-XX-PJ');
  });
}
