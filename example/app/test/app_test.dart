import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kenteken/rdw.dart';
import 'package:kenteken_example/main.dart';
import 'package:kenteken_example/src/license_plate_formatter.dart';

/// Real RDW records, shared with the package's own tests.
List<Object?> fixture(String name) =>
    jsonDecode(File('../../test/fixtures/$name.json').readAsStringSync())
        as List<Object?>;

/// Answers like RDW, from the fixtures, for the van 00-BBN-6.
RdwClient fakeRdw({int status = 200}) {
  final datasets = {
    'm9d7-ebf2': fixture('vehicle_00BBN6'),
    '8ys7-d773': fixture('fuel_00BBN6'),
    't49b-isb7': fixture('recall_status_00BBN6'),
    'af5r-44mf': fixture('recall_00BBN6'),
  };
  return RdwClient(
    httpClient: MockClient((request) async {
      if (status != 200) return http.Response('', status);
      final where = request.url.queryParameters[r'$where']!;
      final dataset = request.url.pathSegments.last.replaceAll('.json', '');
      // A plate other than the van gets no records.
      final rows = where.contains('00BBN6') || dataset == 'af5r-44mf'
          ? datasets[dataset]!
          : const <Object?>[];
      return http.Response.bytes(utf8.encode(jsonEncode(rows)), 200);
    }),
  );
}

Future<void> search(
  WidgetTester tester,
  String input, {
  int status = 200,
}) async {
  await tester.pumpWidget(KentekenApp(rdw: fakeRdw(status: status)));
  await tester.enterText(find.byType(TextField), input);
  await tester.pump();
}

void main() {
  group('LicensePlateFormatter', () {
    String format(String input) => LicensePlateFormatter()
        .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: input))
        .text;

    test('adds dashes once the plate fits a sidecode', () {
      expect(format('84xxpj'), '84-XX-PJ');
      expect(format('00bbn6'), '00-BBN-6');
    });

    test('keeps an incomplete plate without dashes', () {
      expect(format('84-xx-p'), '84XXP');
    });

    test('drops other characters and stops at six', () {
      expect(format('ab 12!34 56'), 'AB-12-34');
    });
  });

  testWidgets('enables the lookup only for a valid plate', (tester) async {
    await search(tester, 'abcdef');
    expect(find.text('Not a Dutch licence plate'), findsOneWidget);
    expect(
      tester.widget<ButtonStyleButton>(find.bySubtype<FilledButton>()).enabled,
      isFalse,
    );

    await tester.enterText(find.byType(TextField), '84xxpj');
    await tester.pump();
    expect(find.text('Sidecode 6: 99-XX-XX'), findsOneWidget);
    expect(find.bySemanticsLabel('Licence plate 84-XX-PJ'), findsOneWidget);
    expect(
      tester.widget<ButtonStyleButton>(find.bySubtype<FilledButton>()).enabled,
      isTrue,
    );
  });

  testWidgets('shows the vehicle with its fuel and recalls', (tester) async {
    await search(tester, '00bbn6');
    await tester.tap(find.bySubtype<FilledButton>());
    await tester.pumpAndSettle();

    expect(find.text('MERCEDES-BENZ 513CDI'), findsOneWidget);
    expect(find.text('This vehicle has an open recall'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Diesel'), 200);
    expect(find.text('95 kW · EEV K'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('MGP240217'), 200);
    expect(find.text('MGP220252'), findsOneWidget);
    expect(find.text('Open'), findsNWidgets(2));
  });

  testWidgets('says so when RDW does not know the plate', (tester) async {
    await search(tester, '84xxpj');
    await tester.tap(find.bySubtype<FilledButton>());
    await tester.pumpAndSettle();

    expect(
      find.text('RDW has no vehicle with plate 84-XX-PJ.'),
      findsOneWidget,
    );
  });

  testWidgets('explains a rate limit and offers a retry', (tester) async {
    await search(tester, '00bbn6', status: 429);
    await tester.tap(find.bySubtype<FilledButton>());
    await tester.pumpAndSettle();

    expect(find.text('RDW is busy. Try again later.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
