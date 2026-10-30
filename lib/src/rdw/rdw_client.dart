import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../license_plate.dart';
import 'fuel.dart';
import 'rdw_exception.dart';
import 'rdw_row.dart';
import 'recall.dart';
import 'vehicle.dart';

/// Data [RdwClient] can fetch on top of a vehicle's main record.
///
/// Each one costs an extra request per batch of plates.
enum RdwData {
  /// Fuel and emission data, in [Vehicle.fuels].
  fuel,

  /// Recalls with their status and details, in [Vehicle.recalls].
  recalls,
}

/// Looks up vehicles in RDW open data (opendata.rdw.nl).
///
/// The API is public. Without an [appToken] RDW limits how many requests you
/// can make; with one the limit is much higher. Call [close] when done.
final class RdwClient {
  /// Creates a client.
  ///
  /// Pass [httpClient] to reuse your own client or to test with a mock; this
  /// client then leaves closing it to you.
  RdwClient({
    this.appToken,
    http.Client? httpClient,
    Uri? baseUri,
    this.timeout = const Duration(seconds: 15),
  }) : baseUri = baseUri ?? defaultBaseUri,
       _http = httpClient ?? http.Client(),
       _ownsHttp = httpClient == null;

  /// Where RDW's datasets live.
  static final defaultBaseUri = Uri.parse('https://opendata.rdw.nl/resource/');

  static const _vehicleDataset = 'm9d7-ebf2';
  static const _fuelDataset = '8ys7-d773';
  static const _recallStatusDataset = 't49b-isb7';
  static const _recallDataset = 'af5r-44mf';

  /// How many values go in one request.
  static const _batchSize = 100;

  /// The most rows RDW returns for one request.
  static const _rowLimit = 50000;

  /// A Socrata app token, sent as `X-App-Token`. Get one for free at
  /// opendata.rdw.nl.
  final String? appToken;

  /// The base URI of the datasets; [defaultBaseUri] unless overridden.
  final Uri baseUri;

  /// How long to wait for each response.
  final Duration timeout;

  final http.Client _http;
  final bool _ownsHttp;

  /// Looks up the vehicle with [plate].
  ///
  /// Returns `null` if RDW has no vehicle with that plate. Throws an
  /// [RdwException] if the lookup fails.
  Future<Vehicle?> vehicle(
    LicensePlate plate, {
    Set<RdwData> include = const {},
  }) async => (await vehicles([plate], include: include))[plate];

  /// Looks up the vehicles with [plates], a hundred plates per request.
  ///
  /// Plates RDW does not know are left out of the result. Throws an
  /// [RdwException] if a lookup fails.
  Future<Map<LicensePlate, Vehicle>> vehicles(
    Iterable<LicensePlate> plates, {
    Set<RdwData> include = const {},
  }) async {
    final vehicles = <LicensePlate, Vehicle>{};
    for (final batch in _batches(plates.toSet().toList())) {
      vehicles.addAll(await _fetchBatch(batch, include));
    }
    return vehicles;
  }

  /// Closes the HTTP client, unless it was passed in.
  void close() {
    if (_ownsHttp) _http.close();
  }

  Future<Map<LicensePlate, Vehicle>> _fetchBatch(
    List<LicensePlate> plates,
    Set<RdwData> include,
  ) async {
    try {
      final keys = [for (final plate in plates) plate.normalized];
      final vehicleRows = _rows(_vehicleDataset, 'kenteken', keys);
      final fuelRows = include.contains(RdwData.fuel)
          ? _rows(_fuelDataset, 'kenteken', keys)
          : null;
      final recalls = include.contains(RdwData.recalls) ? _recalls(keys) : null;
      // Wait for all requests, so a failing one does not leave the others'
      // errors unhandled.
      await Future.wait<Object>([vehicleRows, ?fuelRows, ?recalls]);

      final fuels = <String, List<Fuel>>{};
      for (final row in await fuelRows ?? const <RdwRow>[]) {
        fuels
            .putIfAbsent(row.requiredText('kenteken'), () => [])
            .add(Fuel.fromRdw(row.json));
      }
      for (final list in fuels.values) {
        list.sort((a, b) => a.sequence.compareTo(b.sequence));
      }
      final recallsByPlate = await recalls;

      final vehicles = <LicensePlate, Vehicle>{};
      for (final row in await vehicleRows) {
        final key = row.requiredText('kenteken');
        final vehicle = Vehicle.fromRdw(
          row.json,
          fuels: fuelRows == null ? null : fuels[key] ?? const [],
          recalls: recallsByPlate == null
              ? null
              : recallsByPlate[key] ?? const [],
        );
        vehicles[vehicle.plate] = vehicle;
      }
      return vehicles;
    } on FormatException catch (e) {
      throw RdwResponseException('Could not read RDW data: ${e.message}');
    }
  }

  Future<Map<String, List<Recall>>> _recalls(List<String> plates) async {
    final statuses = await _rows(_recallStatusDataset, 'kenteken', plates);
    final codes = {
      for (final status in statuses) ?status.text('referentiecode_rdw'),
    };
    final details = <String, RdwRow>{};
    for (final batch in _batches(codes.toList())) {
      for (final row in await _rows(
        _recallDataset,
        'referentiecode_rdw',
        batch,
      )) {
        if (row.text('referentiecode_rdw') case final code?) {
          details[code] = row;
        }
      }
    }

    final recalls = <String, List<Recall>>{};
    for (final status in statuses) {
      recalls
          .putIfAbsent(status.requiredText('kenteken'), () => [])
          .add(
            Recall.fromRdw(
              status.json,
              details[status.text('referentiecode_rdw')]?.json,
            ),
          );
    }
    return recalls;
  }

  /// Fetches the rows of [dataset] whose [column] is one of [values].
  Future<List<RdwRow>> _rows(
    String dataset,
    String column,
    List<String> values,
  ) async {
    final quoted = values
        .map((value) => "'${value.replaceAll("'", "''")}'")
        .join(',');
    final uri = baseUri
        .resolve('$dataset.json')
        .replace(
          queryParameters: {
            r'$where': '$column in($quoted)',
            r'$limit': '$_rowLimit',
          },
        );
    final response = await _get(uri);

    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException catch (e) {
      throw RdwResponseException(
        'RDW sent invalid JSON: ${e.message}',
        statusCode: response.statusCode,
      );
    }
    if (decoded is! List<Object?>) {
      throw RdwResponseException(
        'RDW did not send a list of records',
        statusCode: response.statusCode,
      );
    }
    return [
      for (final row in decoded)
        if (row is Map<String, Object?>)
          RdwRow(row)
        else
          throw RdwResponseException(
            'RDW sent a record that is not an object',
            statusCode: response.statusCode,
          ),
    ];
  }

  Future<http.Response> _get(Uri uri) async {
    final http.Response response;
    try {
      response = await _http
          .get(
            uri,
            headers: {'Accept': 'application/json', 'X-App-Token': ?appToken},
          )
          .timeout(timeout);
    } on TimeoutException catch (e) {
      throw RdwNetworkException(
        'RDW did not answer within ${timeout.inSeconds} s',
        cause: e,
      );
    } on http.ClientException catch (e) {
      throw RdwNetworkException('Could not reach RDW: ${e.message}', cause: e);
    }

    return switch (response.statusCode) {
      200 => response,
      429 => throw RdwRateLimitedException(
        'RDW refused the request: too many requests',
        retryAfter: switch (int.tryParse(
          response.headers['retry-after'] ?? '',
        )) {
          final seconds? => Duration(seconds: seconds),
          null => null,
        },
      ),
      final status => throw RdwResponseException(
        'RDW answered with HTTP $status',
        statusCode: status,
      ),
    };
  }

  static Iterable<List<T>> _batches<T>(List<T> items) sync* {
    for (var start = 0; start < items.length; start += _batchSize) {
      yield items.sublist(start, min(start + _batchSize, items.length));
    }
  }
}
