import 'package:kenteken/rdw.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('Vehicle.fromRdw', () {
    test('reads a passenger car', () {
      final car = Vehicle.fromRdw(fixture('vehicle_84XXPJ').single);

      expect(car.plate, LicensePlate.parse('84-XX-PJ'));
      expect(car.make, 'OPEL');
      expect(car.model, 'CORSA');
      expect(car.vehicleType, 'Personenauto');
      expect(car.bodyStyle, 'MPV');
      expect(car.euCategory, 'M1');
      expect(car.primaryColor, 'ZWART');
      expect(car.secondaryColor, isNull, reason: 'Niet geregistreerd');
      expect(car.firstAdmission, DateTime.utc(2007, 10, 31));
      expect(car.registeredSince, DateTime.utc(2024, 11, 14));
      expect(car.apkExpiry, DateTime.utc(2027, 5, 31));
      expect(car.insured, isTrue);
      expect(car.hasOpenRecall, isFalse);
      expect(car.exported, isFalse);
      expect(car.isTaxi, isFalse);
      expect(car.canBeRegistered, isTrue);
      expect(car.seats, 5);
      expect(car.doors, 4);
      expect(car.engineDisplacement, 1364);
      expect(car.catalogPrice, 16865);
      expect(car.powerToMassRatio, 0.06);
      expect(car.energyLabel, 'B');
      expect(car.odometer, OdometerVerdict.logical);
      expect(car.mass.empty, 1063);
      expect(car.mass.maxTowingBraked, 1000);
      expect(car.mass.payload, isNull);
      expect(car.fuels, isNull, reason: 'not fetched');
      expect(car.recalls, isNull, reason: 'not fetched');
      expect(
        car.raw['plaats_chassisnummer'],
        'op bodemplaat by r. voorzitting',
      );
    });

    test('reads a commercial vehicle with "N.v.t." values', () {
      final van = Vehicle.fromRdw(fixture('vehicle_00BBN6').single);

      expect(van.vehicleType, 'Bedrijfsauto');
      expect(van.primaryColor, isNull, reason: 'N.v.t.');
      expect(van.insured, isFalse);
      expect(van.exported, isTrue);
      expect(van.hasOpenRecall, isTrue);
      expect(van.odometer, isNull, reason: 'Niet geregistreerd');
      expect(van.mass.payload, 1960);
    });

    test('throws a FormatException when a required field is missing', () {
      final json = {...fixture('vehicle_84XXPJ').single}..remove('merk');
      expect(() => Vehicle.fromRdw(json), throwsFormatException);
    });

    test('throws a FormatException for an unknown yes/no value', () {
      final json = {
        ...fixture('vehicle_84XXPJ').single,
        'taxi_indicator': 'Misschien',
      };
      expect(() => Vehicle.fromRdw(json), throwsFormatException);
    });
  });

  test('Fuel.fromRdw', () {
    final fuel = Fuel.fromRdw(fixture('fuel_84XXPJ').single);

    expect(fuel.sequence, 1);
    expect(fuel.type, 'Benzine');
    expect(fuel.netMaxPowerKw, 66);
    expect(fuel.co2Combined, 142);
    expect(fuel.consumptionCombined, 5.9);
    expect(fuel.emissionStandard, 'EURO 4');
    expect(fuel.co2CombinedWltp, isNull);
  });

  group('Recall.fromRdw', () {
    test('combines status and details', () {
      final recall = Recall.fromRdw(
        fixture('recall_status_00BBN6').first,
        fixture('recall_00BBN6').first,
      );

      expect(recall.referenceCode, 'MGP220252');
      expect(recall.status, RecallStatus.open);
      expect(recall.manufacturer, 'Mercedes-Benz Nederland B.V. (Vans)');
      expect(recall.defect, contains('Takata'));
      expect(recall.publishedOn, DateTime.utc(2022, 11, 8));
      expect(recall.riskAssessment, 'ERN');
      expect(recall.affectedVehicles, 43895);
      expect(recall.moreInfoUrl?.host, 'www.mercedes-benz.be');
    });

    test('works without details', () {
      final recall = Recall.fromRdw({
        'kenteken': '00BBN6',
        'referentiecode_rdw': 'X1',
        'code_status': 'P',
      });

      expect(recall.status, RecallStatus.repairReported);
      expect(recall.defect, isNull);
    });

    test('maps an unknown status code to unknown', () {
      expect(
        Recall.fromRdw({'referentiecode_rdw': 'X1', 'code_status': 'Z'}).status,
        RecallStatus.unknown,
      );
    });
  });
}
