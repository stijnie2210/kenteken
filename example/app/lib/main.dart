import 'package:flutter/material.dart';
import 'package:kenteken/rdw.dart';

import 'src/search_page.dart';

void main() => runApp(KentekenApp(rdw: RdwClient()));

/// Type a Dutch licence plate and look the vehicle up at RDW.
class KentekenApp extends StatelessWidget {
  const KentekenApp({super.key, required this.rdw});

  final RdwClient rdw;

  @override
  Widget build(BuildContext context) {
    // The blue of the EU band on the plate.
    const seed = Color(0xFF003399);
    return MaterialApp(
      title: 'Kenteken',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: seed)),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
      ),
      home: SearchPage(rdw: rdw),
    );
  }
}
