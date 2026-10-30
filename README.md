# kenteken

Dutch licence plates (kentekens) for Dart and Flutter:

- **Offline:** parse, validate and format plates by sidecode (1–14). No dependencies.
- **RDW lookup:** vehicle details, fuel and emission data, and recalls from
  [RDW open data](https://opendata.rdw.nl), with typed fields instead of RDW's
  strings.

## Plates

```dart
import 'package:kenteken/kenteken.dart';

final plate = LicensePlate.tryParse(' 84-xx-pj '); // null if it fits no sidecode
plate!.normalized;  // '84XXPJ'
plate.formatted;    // '84-XX-PJ'
plate.sidecode;     // Sidecode.s6 (99-XX-XX)

LicensePlate.isValid('84XXPJ'); // true
LicensePlate.parse('nope');     // throws FormatException
```

Parsing ignores case, spaces and dashes, and puts the dashes back where the
sidecode says. It checks the order of letters and digits only: whether a plate
was ever issued is something only RDW can tell you. Special plates (such as
diplomatic plates) are not supported.

## RDW lookup

```dart
import 'package:kenteken/rdw.dart';

final rdw = RdwClient();

final car = await rdw.vehicle(plate); // null if RDW does not know the plate
print('${car?.make} ${car?.model}, APK until ${car?.apkExpiry}');

// Fuel and recalls cost one extra request each.
final van = await rdw.vehicle(
  LicensePlate.parse('00-BBN-6'),
  include: {RdwData.fuel, RdwData.recalls},
);
for (final recall in van!.recalls!) {
  print('${recall.referenceCode}: ${recall.status.name}');
}

// Many plates at once, a hundred per request.
final fleet = await rdw.vehicles(plates);

rdw.close();
```

What the package does with RDW's data:

- `20270531` becomes `DateTime.utc(2027, 5, 31)`.
- `Ja` / `Nee` become `bool`.
- `Niet geregistreerd` and `N.v.t.` become `null`.
- Numbers become `int` or `double`.

Field names are in English; each field's documentation names the RDW field it
comes from. Text values such as `vehicleType` stay in Dutch, as RDW writes them.
Fields the package does not read are in `vehicle.raw`.

### Errors

A plate RDW does not know is not an error. Real failures throw a sealed
`RdwException`:

| Exception | When |
|---|---|
| `RdwNetworkException` | RDW cannot be reached or does not answer in time |
| `RdwRateLimitedException` | Too many requests (HTTP 429); has `retryAfter` |
| `RdwResponseException` | Another HTTP error, or data the package cannot read |

### Rate limits

The RDW API is free and needs no account. Without an app token RDW limits how
many requests you can make. For production use, get a free app token at
[opendata.rdw.nl](https://opendata.rdw.nl) and pass it:

```dart
final rdw = RdwClient(appToken: '...');
```

## Flutter example app

[`example/app`](example/app) is a Flutter app with a plate input that adds the
dashes as you type, a Dutch plate widget, and a vehicle page with fuel and
recalls. Both widgets are small enough to copy into your own app.

```sh
cd example/app
flutter run
```

## Datasets used

| Data | RDW dataset |
|---|---|
| Registered vehicles | [`m9d7-ebf2`](https://opendata.rdw.nl/d/m9d7-ebf2) |
| Fuel and emissions | [`8ys7-d773`](https://opendata.rdw.nl/d/8ys7-d773) |
| Recall status per vehicle | [`t49b-isb7`](https://opendata.rdw.nl/d/t49b-isb7) |
| Recall details | [`af5r-44mf`](https://opendata.rdw.nl/d/af5r-44mf) |

## Development

```sh
dart test                          # unit tests, using recorded RDW data
dart test --run-skipped -t live    # also call the real RDW API
```
