import 'package:flutter/material.dart';
import 'package:kenteken/rdw.dart';

import 'license_plate_view.dart';

/// Looks [plate] up at RDW and shows the vehicle, its fuels and its recalls.
class VehiclePage extends StatefulWidget {
  const VehiclePage({super.key, required this.rdw, required this.plate});

  final RdwClient rdw;
  final LicensePlate plate;

  @override
  State<VehiclePage> createState() => _VehiclePageState();
}

class _VehiclePageState extends State<VehiclePage> {
  late Future<Vehicle?> _vehicle = _lookUp();

  Future<Vehicle?> _lookUp() => widget.rdw.vehicle(
    widget.plate,
    include: {RdwData.fuel, RdwData.recalls},
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.plate.formatted)),
      body: FutureBuilder(
        future: _vehicle,
        builder: (context, snapshot) => switch (snapshot) {
          AsyncSnapshot(connectionState: ConnectionState.waiting) =>
            const Center(child: CircularProgressIndicator()),
          AsyncSnapshot(:final error?) => _Message(
            icon: Icons.cloud_off,
            text: switch (error) {
              RdwException() => _describe(error),
              _ => 'Something went wrong: $error',
            },
            onRetry: () => setState(() => _vehicle = _lookUp()),
          ),
          AsyncSnapshot(data: final vehicle?) => _VehicleDetails(vehicle),
          _ => _Message(
            icon: Icons.search_off,
            text: 'RDW has no vehicle with plate ${widget.plate}.',
          ),
        },
      ),
    );
  }

  static String _describe(RdwException error) => switch (error) {
    RdwNetworkException() => 'Could not reach RDW. Check your connection.',
    RdwRateLimitedException(:final retryAfter) =>
      'RDW is busy. Try again '
          '${retryAfter == null ? 'later' : 'in ${retryAfter.inSeconds} s'}.',
    RdwResponseException(:final message) =>
      'RDW sent something unexpected: $message',
  };
}

class _VehicleDetails extends StatelessWidget {
  const _VehicleDetails(this.vehicle);

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final apkExpiry = vehicle.apkExpiry;
    final recalls = vehicle.recalls ?? const <Recall>[];

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      children: [
        Center(
          child: LicensePlateView(text: vehicle.plate.formatted, height: 48),
        ),
        const SizedBox(height: 16),
        Text(
          [vehicle.make, ?vehicle.model].join(' '),
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        Text(
          vehicle.vehicleType,
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        if (vehicle.hasOpenRecall)
          Card.filled(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            color: theme.colorScheme.errorContainer,
            child: ListTile(
              leading: Icon(
                Icons.warning_amber,
                color: theme.colorScheme.onErrorContainer,
              ),
              title: Text(
                'This vehicle has an open recall',
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ),
        const _Heading('Details'),
        ?_fact('Body style', vehicle.bodyStyle),
        ?_fact('Colour', vehicle.primaryColor),
        ?_fact('First admission', _date(vehicle.firstAdmission)),
        ?_fact('Registered to holder since', _date(vehicle.registeredSince)),
        ?_fact(
          'APK expires',
          apkExpiry == null
              ? null
              : apkExpiry.isBefore(DateTime.now())
              ? '${_date(apkExpiry)} (expired)'
              : _date(apkExpiry),
        ),
        ?_fact('Insured', _yesNo(vehicle.insured)),
        ?_fact('Odometer', switch (vehicle.odometer) {
          OdometerVerdict.logical => 'Readings add up',
          OdometerVerdict.illogical => 'Readings do not add up',
          OdometerVerdict.noVerdict => 'No verdict',
          null => null,
        }),
        ?_fact('Energy label', vehicle.energyLabel),
        ?_fact('Seats', vehicle.seats?.toString()),
        ?_fact('Engine', _unit(vehicle.engineDisplacement, 'cc')),
        ?_fact('Empty mass', _unit(vehicle.mass.empty, 'kg')),
        ?_fact('Catalogue price', _unit(vehicle.catalogPrice, 'euro')),
        const _Heading('Fuel'),
        for (final fuel in vehicle.fuels ?? const <Fuel>[])
          ListTile(
            leading: Icon(
              fuel.type == 'Elektriciteit'
                  ? Icons.electric_bolt
                  : Icons.local_gas_station,
            ),
            title: Text(fuel.type),
            subtitle: Text(
              [
                ?_unit(fuel.netMaxPowerKw?.round(), 'kW'),
                ?_unit(
                  (fuel.co2CombinedWltp ?? fuel.co2Combined)?.round(),
                  'g CO₂/km',
                ),
                ?fuel.emissionStandard,
              ].join(' · '),
            ),
          ),
        const _Heading('Recalls'),
        if (recalls.isEmpty) const ListTile(title: Text('No recalls')),
        for (final recall in recalls) _RecallCard(recall),
      ],
    );
  }

  static Widget? _fact(String label, String? value) => value == null
      ? null
      : ListTile(dense: true, title: Text(label), trailing: Text(value));

  static String? _date(DateTime? date) => date == null
      ? null
      : '${_two(date.day)}-${_two(date.month)}-${date.year}';

  static String _two(int value) => value.toString().padLeft(2, '0');

  static String? _yesNo(bool? value) => switch (value) {
    true => 'Yes',
    false => 'No',
    null => null,
  };

  static String? _unit(num? value, String unit) =>
      value == null ? null : '$value $unit';
}

class _RecallCard extends StatelessWidget {
  const _RecallCard(this.recall);

  final Recall recall;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final open = recall.status == RecallStatus.open;
    return Card.outlined(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    recall.referenceCode,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text(switch (recall.status) {
                    RecallStatus.open => 'Open',
                    RecallStatus.repairReported => 'Repaired',
                    RecallStatus.unknown => 'Unknown',
                  }),
                  backgroundColor: open
                      ? theme.colorScheme.errorContainer
                      : null,
                ),
              ],
            ),
            if (recall.defect case final defect?) Text(defect),
            if (recall.remedy case final remedy?)
              Text(remedy, style: theme.textTheme.bodySmall),
            if (recall.moreInfoUrl case final url?)
              SelectableText(
                url.toString(),
                style: TextStyle(color: theme.colorScheme.primary),
              ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.onRetry});

  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          Icon(icon, size: 48),
          Text(text, textAlign: TextAlign.center),
          if (onRetry != null)
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
