import 'package:flutter/material.dart';
import 'package:kenteken/rdw.dart';

import 'license_plate_formatter.dart';
import 'license_plate_view.dart';
import 'vehicle_page.dart';

/// Real plates to try: a passenger car, and a van with open recalls.
const _samples = ['84-XX-PJ', '00-BBN-6'];

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.rdw});

  final RdwClient rdw;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  LicensePlate? get _plate => LicensePlate.tryParse(_controller.text);

  void _lookUp() {
    final plate = _plate;
    if (plate == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VehiclePage(rdw: widget.rdw, plate: plate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plate = _plate;
    final complete = _controller.text.replaceAll('-', '').length == 6;

    return Scaffold(
      appBar: AppBar(title: const Text('Kenteken')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(child: LicensePlateView(text: _controller.text)),
          const SizedBox(height: 32),
          TextField(
            controller: _controller,
            inputFormatters: [LicensePlateFormatter()],
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _lookUp(),
            decoration: InputDecoration(
              labelText: 'Licence plate',
              hintText: 'For example 84-XX-PJ',
              border: const OutlineInputBorder(),
              helperText: plate == null
                  ? 'Letters and digits; the dashes are added for you'
                  : 'Sidecode ${plate.sidecode.number}: '
                        '${plate.sidecode.pattern}',
              errorText: complete && plate == null
                  ? 'Not a Dutch licence plate'
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: plate == null ? null : _lookUp,
            icon: const Icon(Icons.search),
            label: const Text('Look up at RDW'),
          ),
          const SizedBox(height: 32),
          Text('Try one', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final sample in _samples)
                ActionChip(
                  label: Text(sample),
                  onPressed: () => _controller.text = sample,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
