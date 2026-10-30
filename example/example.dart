import 'package:kenteken/rdw.dart';

Future<void> main(List<String> args) async {
  final plate = LicensePlate.tryParse(args.isEmpty ? '84-xx-pj' : args.first);
  if (plate == null) {
    print('That is not a Dutch licence plate.');
    return;
  }
  print('$plate (sidecode ${plate.sidecode.number})');

  final rdw = RdwClient();
  try {
    final vehicle = await rdw.vehicle(
      plate,
      include: {RdwData.fuel, RdwData.recalls},
    );
    if (vehicle == null) {
      print('RDW does not know this plate.');
      return;
    }
    print('${vehicle.make} ${vehicle.model ?? ''}, ${vehicle.vehicleType}');
    print(
      'APK expires: ${vehicle.apkExpiry?.toIso8601String().substring(0, 10) ?? 'unknown'}',
    );
    print('Fuel: ${vehicle.fuels!.map((fuel) => fuel.type).join(' + ')}');
    for (final recall in vehicle.recalls!) {
      print(
        'Recall ${recall.referenceCode} (${recall.status.name}): ${recall.defect ?? 'no details'}',
      );
    }
  } on RdwException catch (e) {
    print('Lookup failed: $e');
  } finally {
    rdw.close();
  }
}
