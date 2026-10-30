import 'package:flutter/material.dart';

/// A Dutch licence plate: black on yellow, with the blue EU band.
class LicensePlateView extends StatelessWidget {
  const LicensePlateView({super.key, required this.text, this.height = 64});

  /// What is on the plate. Empty shows a faded placeholder.
  final String text;

  final double height;

  static const _yellow = Color(0xFFFFC800);
  static const _blue = Color(0xFF003399);

  @override
  Widget build(BuildContext context) {
    final empty = text.isEmpty;
    return Semantics(
      label: empty ? 'Empty licence plate' : 'Licence plate $text',
      excludeSemantics: true,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: _yellow,
          borderRadius: BorderRadius.circular(height * 0.12),
          border: Border.all(color: Colors.black, width: height * 0.04),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: height * 0.45,
              color: _blue,
              alignment: Alignment.bottomCenter,
              padding: EdgeInsets.only(bottom: height * 0.08),
              child: Text(
                'NL',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: height * 0.22,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: height * 0.25),
              child: Text(
                empty ? 'XX-99-XX' : text,
                style: TextStyle(
                  color: Colors.black.withValues(alpha: empty ? 0.25 : 1),
                  fontWeight: FontWeight.w900,
                  fontSize: height * 0.55,
                  letterSpacing: height * 0.03,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
