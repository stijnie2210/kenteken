import 'rdw_row.dart';

/// Whether a recall still has to be carried out on a vehicle.
enum RecallStatus {
  /// The recall is still open for this vehicle (`O`).
  open,

  /// The manufacturer reported the repair as done (`P`).
  repairReported,

  /// RDW sent a status this package does not know.
  unknown;

  static RecallStatus _fromCode(String? code) => switch (code) {
    'O' => open,
    'P' => repairReported,
    _ => unknown,
  };
}

/// A recall that applies to a vehicle.
///
/// The status comes from RDW's recall status dataset (`t49b-isb7`), the
/// details from its recall dataset (`af5r-44mf`). If RDW has no details for
/// the recall, the detail fields are `null`.
final class Recall {
  /// Reads a record from the recall status dataset and, if there is one, the
  /// matching record from the recall dataset.
  ///
  /// Throws a [FormatException] if [status] has no reference code.
  factory Recall.fromRdw(
    Map<String, Object?> status, [
    Map<String, Object?>? details,
  ]) {
    final statusRow = RdwRow(status);
    final detailRow = RdwRow(details ?? const {});
    return Recall._(
      referenceCode: statusRow.requiredText('referentiecode_rdw'),
      status: RecallStatus._fromCode(statusRow.text('code_status')),
      manufacturer: detailRow.text('meldende_producent_distributeur'),
      manufacturerReference: detailRow.text('referentiecode_producent'),
      defect: detailRow.text('omschrijving_defect'),
      defectCategory: detailRow.text('categorie_defect'),
      consequences: detailRow.text('materi_le_gevolgen'),
      remedy: detailRow.text('beschrijving_van_het_herstel'),
      moreInfoUrl: switch (detailRow.text('meer_informatie_op_internet')) {
        final url? => Uri.tryParse(url),
        null => null,
      },
      moreInfoPhone: detailRow.text('meer_informatie_via_telefoonnummer'),
      publishedOn: detailRow.date('publicatiedatum_rdw'),
      riskAssessment: detailRow.text('risicobeoordeling_rdw'),
      affectedVehicles: detailRow.integer(
        'totaal_aantal_voertuigen_terugroepactie',
      ),
    );
  }

  const Recall._({
    required this.referenceCode,
    required this.status,
    required this.manufacturer,
    required this.manufacturerReference,
    required this.defect,
    required this.defectCategory,
    required this.consequences,
    required this.remedy,
    required this.moreInfoUrl,
    required this.moreInfoPhone,
    required this.publishedOn,
    required this.riskAssessment,
    required this.affectedVehicles,
  });

  /// RDW's reference for the recall, such as `MGP220252`
  /// (`referentiecode_rdw`).
  final String referenceCode;

  /// Whether the recall is still open for this vehicle (`code_status`).
  final RecallStatus status;

  /// The manufacturer or importer that reported the recall
  /// (`meldende_producent_distributeur`).
  final String? manufacturer;

  /// The manufacturer's own reference (`referentiecode_producent`).
  final String? manufacturerReference;

  /// What is wrong, in Dutch (`omschrijving_defect`).
  final String? defect;

  /// The part of the vehicle concerned, in Dutch (`categorie_defect`).
  final String? defectCategory;

  /// What can happen because of the defect, in Dutch (`materi_le_gevolgen`).
  final String? consequences;

  /// How it is fixed, in Dutch (`beschrijving_van_het_herstel`).
  final String? remedy;

  /// Where to read more (`meer_informatie_op_internet`).
  final Uri? moreInfoUrl;

  /// Who to call for more information
  /// (`meer_informatie_via_telefoonnummer`).
  final String? moreInfoPhone;

  /// When RDW published the recall (`publicatiedatum_rdw`).
  final DateTime? publishedOn;

  /// RDW's risk code, such as `ERN` (`risicobeoordeling_rdw`).
  final String? riskAssessment;

  /// How many vehicles the recall covers in total
  /// (`totaal_aantal_voertuigen_terugroepactie`).
  final int? affectedVehicles;
}
