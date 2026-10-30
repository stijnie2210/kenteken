import 'package:flutter/services.dart';
import 'package:kenteken/kenteken.dart';

/// Keeps a text field to at most six upper-case letters and digits, and adds
/// the dashes as soon as they fit a sidecode.
class LicensePlateFormatter extends TextInputFormatter {
  static final _notLetterOrDigit = RegExp('[^A-Z0-9]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.toUpperCase().replaceAll(_notLetterOrDigit, '');
    if (text.length > 6) text = text.substring(0, 6);
    final formatted = LicensePlate.tryParse(text)?.formatted ?? text;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
