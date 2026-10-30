import '../license_plate.dart';
import 'fuel.dart';
import 'rdw_row.dart';
import 'recall.dart';

/// RDW's verdict on the odometer history of a vehicle (`tellerstandoordeel`).
enum OdometerVerdict {
  /// The readings add up (`Logisch`).
  logical,

  /// The readings do not add up (`Onlogisch`).
  illogical,

  /// RDW gives no verdict (`Geen oordeel`).
  noVerdict;

  static OdometerVerdict? _fromRdw(String? value) => switch (value) {
    'Logisch' => logical,
    'Onlogisch' => illogical,
    'Geen oordeel' => noVerdict,
    _ => null,
  };
}

/// The masses of a vehicle, in kg. Values RDW does not have are `null`.
final class VehicleMass {
  const VehicleMass._({
    required this.empty,
    required this.readyToDrive,
    required this.maxAllowed,
    required this.technicalMax,
    required this.maxCombination,
    required this.maxTowingBraked,
    required this.maxTowingUnbraked,
    required this.payload,
  });

  /// Empty vehicle (`massa_ledig_voertuig`).
  final int? empty;

  /// Ready to drive, with driver and fuel (`massa_rijklaar`).
  final int? readyToDrive;

  /// Maximum allowed (`toegestane_maximum_massa_voertuig`).
  final int? maxAllowed;

  /// Technical maximum (`technische_max_massa_voertuig`).
  final int? technicalMax;

  /// Maximum of vehicle and trailer together (`maximum_massa_samenstelling`).
  final int? maxCombination;

  /// Maximum braked trailer (`maximum_trekken_massa_geremd`).
  final int? maxTowingBraked;

  /// Maximum unbraked trailer (`maximum_massa_trekken_ongeremd`).
  final int? maxTowingUnbraked;

  /// Load capacity, mostly for commercial vehicles (`laadvermogen`).
  final int? payload;
}

/// A registered vehicle, from RDW's dataset of registered vehicles
/// (`m9d7-ebf2`).
///
/// Values RDW does not have are `null`. Text such as [vehicleType] and
/// [primaryColor] is in Dutch, as RDW writes it. Each field's documentation
/// names the RDW field it comes from.
final class Vehicle {
  /// Reads a record from RDW's dataset of registered vehicles.
  ///
  /// Pass [fuels] and [recalls] if they were fetched as well; otherwise they
  /// stay `null`. Throws a [FormatException] if a required field is missing
  /// or unreadable.
  factory Vehicle.fromRdw(
    Map<String, Object?> json, {
    List<Fuel>? fuels,
    List<Recall>? recalls,
  }) {
    final row = RdwRow(json);
    return Vehicle._(
      plate: LicensePlate.parse(row.requiredText('kenteken')),
      make: row.requiredText('merk'),
      model: row.text('handelsbenaming'),
      vehicleType: row.requiredText('voertuigsoort'),
      bodyStyle: row.text('inrichting'),
      euCategory: row.text('europese_voertuigcategorie'),
      primaryColor: row.text('eerste_kleur'),
      secondaryColor: row.text('tweede_kleur'),
      firstAdmission: row.date('datum_eerste_toelating'),
      firstRegisteredInNetherlands: row.date(
        'datum_eerste_tenaamstelling_in_nederland',
      ),
      registeredSince: row.date('datum_tenaamstelling'),
      apkExpiry: row.date('vervaldatum_apk'),
      insured: row.yesNo('wam_verzekerd'),
      hasOpenRecall: row.requiredYesNo('openstaande_terugroepactie_indicator'),
      exported: row.requiredYesNo('export_indicator'),
      isTaxi: row.requiredYesNo('taxi_indicator'),
      canBeRegistered: row.yesNo('tenaamstellen_mogelijk'),
      seats: row.integer('aantal_zitplaatsen'),
      doors: row.integer('aantal_deuren'),
      wheels: row.integer('aantal_wielen'),
      cylinders: row.integer('aantal_cilinders'),
      engineDisplacement: row.integer('cilinderinhoud'),
      wheelbase: row.integer('wielbasis'),
      catalogPrice: row.integer('catalogusprijs'),
      grossBpm: row.integer('bruto_bpm'),
      powerToMassRatio: row.decimal('vermogen_massarijklaar'),
      energyLabel: row.text('zuinigheidsclassificatie'),
      typeApprovalNumber: row.text('typegoedkeuringsnummer'),
      variant: row.text('variant'),
      version: row.text('uitvoering'),
      odometer: OdometerVerdict._fromRdw(row.text('tellerstandoordeel')),
      odometerLastRegisteredYear: row.integer(
        'jaar_laatste_registratie_tellerstand',
      ),
      mass: VehicleMass._(
        empty: row.integer('massa_ledig_voertuig'),
        readyToDrive: row.integer('massa_rijklaar'),
        maxAllowed: row.integer('toegestane_maximum_massa_voertuig'),
        technicalMax: row.integer('technische_max_massa_voertuig'),
        maxCombination: row.integer('maximum_massa_samenstelling'),
        maxTowingBraked: row.integer('maximum_trekken_massa_geremd'),
        maxTowingUnbraked: row.integer('maximum_massa_trekken_ongeremd'),
        payload: row.integer('laadvermogen'),
      ),
      fuels: fuels == null ? null : List.unmodifiable(fuels),
      recalls: recalls == null ? null : List.unmodifiable(recalls),
      raw: Map.unmodifiable(json),
    );
  }

  const Vehicle._({
    required this.plate,
    required this.make,
    required this.model,
    required this.vehicleType,
    required this.bodyStyle,
    required this.euCategory,
    required this.primaryColor,
    required this.secondaryColor,
    required this.firstAdmission,
    required this.firstRegisteredInNetherlands,
    required this.registeredSince,
    required this.apkExpiry,
    required this.insured,
    required this.hasOpenRecall,
    required this.exported,
    required this.isTaxi,
    required this.canBeRegistered,
    required this.seats,
    required this.doors,
    required this.wheels,
    required this.cylinders,
    required this.engineDisplacement,
    required this.wheelbase,
    required this.catalogPrice,
    required this.grossBpm,
    required this.powerToMassRatio,
    required this.energyLabel,
    required this.typeApprovalNumber,
    required this.variant,
    required this.version,
    required this.odometer,
    required this.odometerLastRegisteredYear,
    required this.mass,
    required this.fuels,
    required this.recalls,
    required this.raw,
  });

  /// The licence plate (`kenteken`).
  final LicensePlate plate;

  /// The make, such as `OPEL` (`merk`).
  final String make;

  /// The model name, such as `CORSA` (`handelsbenaming`).
  final String? model;

  /// The kind of vehicle, such as `Personenauto` or `Bedrijfsauto`
  /// (`voertuigsoort`).
  final String vehicleType;

  /// The body style, such as `MPV` or `hatchback` (`inrichting`).
  final String? bodyStyle;

  /// The EU vehicle category, such as `M1` (`europese_voertuigcategorie`).
  final String? euCategory;

  /// The main colour, such as `ZWART` (`eerste_kleur`).
  final String? primaryColor;

  /// The second colour, if one is registered (`tweede_kleur`).
  final String? secondaryColor;

  /// When the vehicle was first admitted to the road anywhere
  /// (`datum_eerste_toelating`).
  final DateTime? firstAdmission;

  /// When the vehicle was first registered in the Netherlands
  /// (`datum_eerste_tenaamstelling_in_nederland`).
  final DateTime? firstRegisteredInNetherlands;

  /// When the vehicle was registered to its current holder
  /// (`datum_tenaamstelling`).
  final DateTime? registeredSince;

  /// When the current APK (periodic inspection) expires (`vervaldatum_apk`).
  final DateTime? apkExpiry;

  /// Whether the vehicle has third-party insurance; `null` where it does not
  /// apply (`wam_verzekerd`).
  final bool? insured;

  /// Whether a recall is still open for the vehicle
  /// (`openstaande_terugroepactie_indicator`).
  final bool hasOpenRecall;

  /// Whether the vehicle has been exported (`export_indicator`).
  final bool exported;

  /// Whether the vehicle is registered as a taxi (`taxi_indicator`).
  final bool isTaxi;

  /// Whether the vehicle can be registered to a new holder
  /// (`tenaamstellen_mogelijk`).
  final bool? canBeRegistered;

  /// Number of seats (`aantal_zitplaatsen`).
  final int? seats;

  /// Number of doors (`aantal_deuren`).
  final int? doors;

  /// Number of wheels (`aantal_wielen`).
  final int? wheels;

  /// Number of cylinders (`aantal_cilinders`).
  final int? cylinders;

  /// Engine displacement in cm³ (`cilinderinhoud`).
  final int? engineDisplacement;

  /// Wheelbase in cm (`wielbasis`).
  final int? wheelbase;

  /// List price in euros when new (`catalogusprijs`).
  final int? catalogPrice;

  /// Gross BPM (registration tax) in euros (`bruto_bpm`).
  final int? grossBpm;

  /// Power in kW per kg ready-to-drive mass (`vermogen_massarijklaar`).
  final double? powerToMassRatio;

  /// The energy label, `A` to `G` (`zuinigheidsclassificatie`).
  final String? energyLabel;

  /// The EU type approval number (`typegoedkeuringsnummer`).
  final String? typeApprovalNumber;

  /// The type approval variant (`variant`).
  final String? variant;

  /// The type approval version (`uitvoering`).
  final String? version;

  /// RDW's verdict on the odometer readings (`tellerstandoordeel`).
  final OdometerVerdict? odometer;

  /// The last year an odometer reading was registered
  /// (`jaar_laatste_registratie_tellerstand`).
  final int? odometerLastRegisteredYear;

  /// The masses of the vehicle.
  final VehicleMass mass;

  /// The fuels, in RDW's order; `null` unless they were fetched.
  final List<Fuel>? fuels;

  /// The recalls that apply; `null` unless they were fetched.
  final List<Recall>? recalls;

  /// The record as RDW sent it, for fields this class does not read.
  final Map<String, Object?> raw;
}
