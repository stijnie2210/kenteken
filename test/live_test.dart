@Tags(['live'])
library;

import 'package:kenteken/rdw.dart';
import 'package:test/test.dart';

/// Calls the real RDW API, to notice when RDW changes its data.
/// Skipped by default; run with `dart test --run-skipped -t live`.
void main() {
  late RdwClient rdw;
  setUp(() => rdw = RdwClient());
  tearDown(() => rdw.close());

  test('looks up a real van with fuel and recalls', () async {
    final van = await rdw.vehicle(
      LicensePlate.parse('00-BBN-6'),
      include: {RdwData.fuel, RdwData.recalls},
    );

    expect(van, isNotNull);
    expect(van!.make, 'MERCEDES-BENZ');
    expect(van.fuels, isNotEmpty);
    expect(
      van.recalls!.map((recall) => recall.referenceCode),
      contains('MGP220252'),
    );
  });

  test('looks up several real plates at once', () async {
    final plates = [
      LicensePlate.parse('84-XX-PJ'),
      LicensePlate.parse('00-BBN-6'),
    ];
    expect((await rdw.vehicles(plates)).keys, unorderedEquals(plates));
  });
}
