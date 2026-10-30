import 'rdw_row.dart';

/// One fuel or energy source of a vehicle, from RDW's fuel dataset.
///
/// A hybrid has more than one. Values RDW does not have are `null`.
final class Fuel {
  /// Reads a record from RDW's fuel dataset (`8ys7-d773`).
  ///
  /// Throws a [FormatException] if the record has no fuel type.
  factory Fuel.fromRdw(Map<String, Object?> json) {
    final row = RdwRow(json);
    return Fuel._(
      sequence: row.integer('brandstof_volgnummer') ?? 1,
      type: row.requiredText('brandstof_omschrijving'),
      netMaxPowerKw: row.decimal('nettomaximumvermogen'),
      co2Combined: row.decimal('co2_uitstoot_gecombineerd'),
      co2CombinedWltp: row.decimal('emissie_co2_gecombineerd_wltp'),
      consumptionCombined: row.decimal('brandstofverbruik_gecombineerd'),
      consumptionCombinedWltp: row.decimal(
        'brandstof_verbruik_gecombineerd_wltp',
      ),
      electricRangeWltp: row.decimal('actie_radius_enkel_elektrisch_wltp'),
      emissionStandard: row.text('uitlaatemissieniveau'),
      maxSpeed: row.decimal('opgegeven_maximum_snelheid'),
      raw: Map.unmodifiable(json),
    );
  }

  const Fuel._({
    required this.sequence,
    required this.type,
    required this.netMaxPowerKw,
    required this.co2Combined,
    required this.co2CombinedWltp,
    required this.consumptionCombined,
    required this.consumptionCombinedWltp,
    required this.electricRangeWltp,
    required this.emissionStandard,
    required this.maxSpeed,
    required this.raw,
  });

  /// The order of this fuel for the vehicle, starting at 1
  /// (`brandstof_volgnummer`).
  final int sequence;

  /// The fuel as RDW names it, such as `Benzine`, `Diesel` or `Elektriciteit`
  /// (`brandstof_omschrijving`).
  final String type;

  /// Net maximum power in kW (`nettomaximumvermogen`).
  final double? netMaxPowerKw;

  /// Combined CO₂ emission in g/km, NEDC (`co2_uitstoot_gecombineerd`).
  final double? co2Combined;

  /// Combined CO₂ emission in g/km, WLTP (`emissie_co2_gecombineerd_wltp`).
  final double? co2CombinedWltp;

  /// Combined consumption in l/100 km, NEDC (`brandstofverbruik_gecombineerd`).
  final double? consumptionCombined;

  /// Combined consumption in l/100 km, WLTP
  /// (`brandstof_verbruik_gecombineerd_wltp`).
  final double? consumptionCombinedWltp;

  /// Range on electricity only in km, WLTP
  /// (`actie_radius_enkel_elektrisch_wltp`).
  final double? electricRangeWltp;

  /// The exhaust emission standard, such as `EURO 6 AP`
  /// (`uitlaatemissieniveau`).
  final String? emissionStandard;

  /// Top speed in km/h as given by the manufacturer
  /// (`opgegeven_maximum_snelheid`).
  final double? maxSpeed;

  /// The record as RDW sent it, for fields this class does not read.
  final Map<String, Object?> raw;
}
