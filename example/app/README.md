# kenteken example app

A Flutter app that shows what `package:kenteken` does:

- Type a plate; it gets dashes as soon as it fits a sidecode, and is shown as a
  Dutch plate.
- Look it up at RDW: vehicle details, fuel, and recalls with their status.

Try `84-XX-PJ` (a car) or `00-BBN-6` (a van with two open recalls).

```sh
flutter run
```

Runs on Android, iOS, macOS and the web, with Flutter 3.35 or newer.

`LicensePlateFormatter` and `LicensePlateView` in `lib/src` are small enough to
copy into your own app.
