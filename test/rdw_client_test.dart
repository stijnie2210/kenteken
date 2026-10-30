import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kenteken/rdw.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

final car = LicensePlate.parse('84-XX-PJ');
final van = LicensePlate.parse('00-BBN-6');

/// A fake RDW that answers `$where=<column> in(...)` queries from fixtures,
/// and records every request it gets.
class FakeRdw {
  FakeRdw([Map<String, List<Map<String, Object?>>>? datasets])
    : datasets =
          datasets ??
          {
            'm9d7-ebf2': [
              ...fixture('vehicle_84XXPJ'),
              ...fixture('vehicle_00BBN6'),
            ],
            '8ys7-d773': [...fixture('fuel_84XXPJ'), ...fixture('fuel_00BBN6')],
            't49b-isb7': fixture('recall_status_00BBN6'),
            'af5r-44mf': fixture('recall_00BBN6'),
          };

  final Map<String, List<Map<String, Object?>>> datasets;
  final requests = <http.Request>[];

  /// The datasets that were queried, in order.
  List<String> get queried => [
    for (final request in requests) request.url.pathSegments.last,
  ];

  late final client = MockClient((request) async {
    requests.add(request);
    final dataset = request.url.pathSegments.last.replaceAll('.json', '');
    final where = RegExp(
      r'^(\w+) in\((.*)\)$',
    ).firstMatch(request.url.queryParameters[r'$where']!)!;
    final values = {
      for (final match in RegExp("'([^']*)'").allMatches(where[2]!)) match[1],
    };
    final rows = [
      for (final row in datasets[dataset]!)
        if (values.contains(row[where[1]!])) row,
    ];
    // No charset in the response, like RDW: the client must decode UTF-8 itself.
    return http.Response.bytes(utf8.encode(jsonEncode(rows)), 200);
  });
}

void main() {
  group('vehicle', () {
    test('looks up one plate in the vehicle dataset', () async {
      final rdw = FakeRdw();
      final vehicle = await RdwClient(httpClient: rdw.client).vehicle(car);

      expect(vehicle?.make, 'OPEL');
      expect(vehicle?.fuels, isNull);
      expect(rdw.queried, ['m9d7-ebf2.json']);
      expect(rdw.requests.single.url.queryParameters, {
        r'$where': "kenteken in('84XXPJ')",
        r'$limit': '50000',
      });
      expect(rdw.requests.single.url.host, 'opendata.rdw.nl');
    });

    test('returns null for a plate RDW does not know', () async {
      final vehicle = await RdwClient(
        httpClient: FakeRdw().client,
      ).vehicle(LicensePlate.parse('ZZ-99-ZZ'));
      expect(vehicle, isNull);
    });

    test('fetches fuels and recalls with their details', () async {
      final rdw = FakeRdw();
      final vehicle = await RdwClient(
        httpClient: rdw.client,
      ).vehicle(van, include: {RdwData.fuel, RdwData.recalls});

      expect(vehicle!.fuels!.single.type, 'Diesel');
      expect(vehicle.recalls!.map((recall) => recall.referenceCode), [
        'MGP220252',
        'MGP240217',
      ]);
      expect(vehicle.recalls!.first.defect, contains('Takata'));
      expect(
        rdw.queried,
        unorderedEquals([
          'm9d7-ebf2.json',
          '8ys7-d773.json',
          't49b-isb7.json',
          'af5r-44mf.json',
        ]),
      );
      expect(
        rdw.requests
            .firstWhere(
              (request) => request.url.path.endsWith('af5r-44mf.json'),
            )
            .url
            .queryParameters[r'$where'],
        "referentiecode_rdw in('MGP220252','MGP240217')",
      );
    });

    test('gives an empty list, not null, when there are no recalls', () async {
      final vehicle = await RdwClient(
        httpClient: FakeRdw().client,
      ).vehicle(car, include: {RdwData.recalls});
      expect(vehicle!.recalls, isEmpty);
      expect(vehicle.fuels, isNull);
    });

    test('sorts fuels by sequence', () async {
      final rdw = FakeRdw({
        'm9d7-ebf2': fixture('vehicle_84XXPJ'),
        '8ys7-d773': [
          {
            'kenteken': '84XXPJ',
            'brandstof_volgnummer': '2',
            'brandstof_omschrijving': 'Elektriciteit',
          },
          {
            'kenteken': '84XXPJ',
            'brandstof_volgnummer': '1',
            'brandstof_omschrijving': 'Benzine',
          },
        ],
      });
      final vehicle = await RdwClient(
        httpClient: rdw.client,
      ).vehicle(car, include: {RdwData.fuel});
      expect(vehicle!.fuels!.map((fuel) => fuel.type), [
        'Benzine',
        'Elektriciteit',
      ]);
    });

    test('decodes UTF-8 without a charset header', () async {
      final rdw = FakeRdw({
        'm9d7-ebf2': [
          {...fixture('vehicle_84XXPJ').single, 'merk': 'CITROËN'},
        ],
      });
      expect(
        (await RdwClient(httpClient: rdw.client).vehicle(car))!.make,
        'CITROËN',
      );
    });
  });

  group('vehicles', () {
    test('returns the plates RDW knows, keyed by plate', () async {
      final unknown = LicensePlate.parse('ZZ-99-ZZ');
      final vehicles = await RdwClient(
        httpClient: FakeRdw().client,
      ).vehicles([car, van, unknown, car]);

      expect(vehicles.keys, unorderedEquals([car, van]));
      expect(vehicles[van]!.make, 'MERCEDES-BENZ');
    });

    test('asks for a hundred plates per request', () async {
      final plates = [
        for (var i = 0; i < 150; i++)
          LicensePlate.parse('AB${i.toString().padLeft(4, '0')}'),
      ];
      final rdw = FakeRdw();
      await RdwClient(httpClient: rdw.client).vehicles(plates);

      final counts = [
        for (final request in rdw.requests)
          "'".allMatches(request.url.queryParameters[r'$where']!).length ~/ 2,
      ];
      expect(counts, [100, 50]);
    });
  });

  group('app token', () {
    test('is sent as X-App-Token', () async {
      final rdw = FakeRdw();
      await RdwClient(appToken: 'secret', httpClient: rdw.client).vehicle(car);
      expect(rdw.requests.single.headers['X-App-Token'], 'secret');
    });

    test('is left out when not set', () async {
      final rdw = FakeRdw();
      await RdwClient(httpClient: rdw.client).vehicle(car);
      expect(rdw.requests.single.headers.containsKey('X-App-Token'), isFalse);
    });
  });

  group('errors', () {
    Future<Vehicle?> lookUpWith(
      MockClientHandler handler, {
      Duration? timeout,
    }) => RdwClient(
      httpClient: MockClient(handler),
      timeout: timeout ?? const Duration(seconds: 15),
    ).vehicle(car, include: {RdwData.fuel, RdwData.recalls});

    test('HTTP 429 is an RdwRateLimitedException with the wait time', () async {
      await expectLater(
        lookUpWith(
          (_) async => http.Response('', 429, headers: {'retry-after': '30'}),
        ),
        throwsA(
          isA<RdwRateLimitedException>().having(
            (e) => e.retryAfter,
            'retryAfter',
            const Duration(seconds: 30),
          ),
        ),
      );
    });

    test('another HTTP error is an RdwResponseException', () async {
      await expectLater(
        lookUpWith((_) async => http.Response('oops', 500)),
        throwsA(
          isA<RdwResponseException>().having(
            (e) => e.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
    });

    test('invalid JSON is an RdwResponseException', () async {
      await expectLater(
        lookUpWith((_) async => http.Response('<html>', 200)),
        throwsA(isA<RdwResponseException>()),
      );
    });

    test(
      'JSON that is not a list of records is an RdwResponseException',
      () async {
        await expectLater(
          lookUpWith((_) async => http.Response('{"error": true}', 200)),
          throwsA(isA<RdwResponseException>()),
        );
        await expectLater(
          lookUpWith((_) async => http.Response('[1]', 200)),
          throwsA(isA<RdwResponseException>()),
        );
      },
    );

    test('a record that cannot be read is an RdwResponseException', () async {
      final rdw = FakeRdw({
        'm9d7-ebf2': [
          {'kenteken': '84XXPJ'},
        ],
      });
      await expectLater(
        RdwClient(httpClient: rdw.client).vehicle(car),
        throwsA(isA<RdwResponseException>()),
      );
    });

    test('a connection failure is an RdwNetworkException', () async {
      await expectLater(
        lookUpWith(
          (request) async =>
              throw http.ClientException('Connection refused', request.url),
        ),
        throwsA(
          isA<RdwNetworkException>().having(
            (e) => e.cause,
            'cause',
            isA<http.ClientException>(),
          ),
        ),
      );
    });

    test('a slow answer is an RdwNetworkException', () async {
      await expectLater(
        lookUpWith((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          return http.Response('[]', 200);
        }, timeout: const Duration(milliseconds: 20)),
        throwsA(
          isA<RdwNetworkException>().having(
            (e) => e.cause,
            'cause',
            isA<TimeoutException>(),
          ),
        ),
      );
    });
  });

  group('close', () {
    test('leaves a passed-in client open', () {
      final http = _ClosingClient();
      RdwClient(httpClient: http).close();
      expect(http.closed, isFalse);
    });
  });
}

class _ClosingClient extends http.BaseClient {
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      throw UnimplementedError();

  @override
  void close() => closed = true;
}
