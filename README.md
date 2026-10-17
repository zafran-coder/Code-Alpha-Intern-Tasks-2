# Stride - Fitness Tracker (Flutter)

A simple, clean fitness tracker built with **Flutter**. Log steps, workouts and calories, and see daily and weekly progress with rings, progress bars and a bar chart. Data is saved on the device.

## Run it

You need the Flutter SDK (3.10 or newer): https://docs.flutter.dev/get-started/install

This zip contains the app source only (`lib/`, `pubspec.yaml`, `test/`). Generate the Android/iOS/web runner folders once, then run:

```bash
cd stride_fitness
flutter create .          # adds android/, ios/, web/ ... (does not touch lib/)
flutter pub get
flutter run               # pick an emulator, a phone, or Chrome
```

Run the logic tests with `flutter test`.

## Features

| Requirement | Where |
|---|---|
| Track steps, workouts, calories | Log tab: steps, exercise type, duration, calories, note |
| Manual logging | Form with validation; edit and delete from History |
| Dashboard (daily / weekly) | Dashboard tab: goal rings, progress bars, weekly totals, average, active days, streak |
| Graphs / progress bars | `lib/widgets/rings.dart` and `lib/widgets/bar_chart.dart` (custom painters, no chart package) |
| Local storage | `lib/services/storage.dart` using `shared_preferences` (JSON on device) |

Extras: week-by-week navigation, tap a bar to inspect a day, editable daily goals and weight, automatic calorie estimate (shown as "est."), copy data as CSV, sample data for demos.

## Project structure

```
lib/
  main.dart                 App entry
  theme.dart                Colors, theme, input style
  models/entry.dart         Entry, Goals, DayTotals, exercise list (MET values)
  services/storage.dart     Load/save (shared_preferences)
  state/app_state.dart      All data + UI state (ChangeNotifier + AppScope)
  screens/                  Dashboard, Log, History, Goals, bottom-nav shell
  widgets/                  Rings, bar chart, Panel
  utils/                    Date and paint helpers
test/logic_test.dart        Unit tests
```

## Calories estimate

If calories are left blank: workout = `MET x weight (kg) x hours`; steps only = about 0.04 kcal per step at 70 kg, scaled by weight.

## Using SQLite or Firebase instead

The rest of the app only calls `Storage.load()` and `Storage.save()`. Replace what happens inside those two methods (keep the `StoredData` shape) to use `sqflite` or Firebase.
