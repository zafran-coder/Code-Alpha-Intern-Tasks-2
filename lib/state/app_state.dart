import 'dart:math';

import 'package:flutter/widgets.dart';

import '../models/entry.dart';
import '../services/storage.dart';
import '../utils/dates.dart';

enum Metric { steps, calories, minutes }

/// Holds all data and UI selection state. Screens read it through [AppScope].
class AppState extends ChangeNotifier {
  AppState(this._storage);

  final Storage _storage;

  List<Entry> _entries = [];
  Goals goals = const Goals();
  double weightKg = 70;
  bool loaded = false;
  bool saveFailed = false;

  int tabIndex = 0;
  DateTime selected = today();
  DateTime weekStart = mondayOf(today());
  Metric metric = Metric.steps;

  /// Entry currently being edited in the Log tab (null = adding a new one).
  Entry? editing;

  List<Entry> get entries => List.unmodifiable(_entries);

  // ---------- loading & saving ----------

  Future<void> load() async {
    final data = await _storage.load();
    _entries = List<Entry>.from(data.entries);
    goals = data.goals;
    weightKg = data.weightKg;
    loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final ok = await _storage.save(
      StoredData(entries: _entries, goals: goals, weightKg: weightKg),
    );
    saveFailed = !ok;
  }

  // ---------- navigation ----------

  void goTo(int index) {
    if (index != 1) editing = null;
    tabIndex = index;
    notifyListeners();
  }

  void startEdit(Entry e) {
    editing = e;
    tabIndex = 1;
    notifyListeners();
  }

  void cancelEdit() {
    editing = null;
    tabIndex = 2;
    notifyListeners();
  }

  void selectDay(DateTime d) {
    if (d.isAfter(today())) return;
    selected = dateOnly(d);
    notifyListeners();
  }

  bool get canGoNextWeek => weekStart.isBefore(mondayOf(today()));

  void shiftWeek(int dir) {
    final start = addDays(weekStart, dir * 7);
    if (start.isAfter(mondayOf(today()))) return;
    weekStart = start;
    final end = addDays(start, 6);
    selected = end.isAfter(today()) ? today() : end;
    notifyListeners();
  }

  void setMetric(Metric m) {
    metric = m;
    notifyListeners();
  }

  // ---------- calculations ----------

  List<Entry> entriesOn(DateTime day) {
    final key = isoDate(day);
    return _entries.where((e) => e.date == key).toList();
  }

  DayTotals totalsFor(DateTime day) {
    var steps = 0, minutes = 0, calories = 0, count = 0;
    final key = isoDate(day);
    for (final e in _entries) {
      if (e.date != key) continue;
      steps += e.steps;
      minutes += e.minutes;
      calories += e.calories;
      count++;
    }
    return DayTotals(
      steps: steps,
      minutes: minutes,
      calories: calories,
      count: count,
    );
  }

  /// With a workout: MET x kg x hours. Steps only: ~0.04 kcal/step at 70 kg.
  int estimateCalories(String exercise, int minutes, int steps) {
    if (exercise.isNotEmpty && minutes > 0) {
      final met = kExercises[exercise] ?? 4.0;
      return (met * weightKg * minutes / 60).round();
    }
    if (steps > 0) return (steps * 0.04 * (weightKg / 70)).round();
    return 0;
  }

  /// Consecutive days with any activity, ending today (or yesterday if today
  /// has nothing logged yet).
  int streak() {
    var d = today();
    if (totalsFor(d).count == 0) d = addDays(d, -1);
    var n = 0;
    while (totalsFor(d).count > 0) {
      n++;
      d = addDays(d, -1);
    }
    return n;
  }

  // ---------- changes ----------

  String newId() =>
      '${DateTime.now().microsecondsSinceEpoch}${Random().nextInt(9999)}';

  /// Adds a new entry, or replaces the one with the same id.
  Future<void> saveEntry(Entry entry) async {
    final i = _entries.indexWhere((e) => e.id == entry.id);
    if (i >= 0) {
      _entries[i] = entry;
    } else {
      _entries.add(entry);
    }
    editing = null;
    selected = parseIso(entry.date);
    weekStart = mondayOf(selected);
    tabIndex = 0;
    notifyListeners();
    await _persist();
  }

  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persist();
  }

  Future<void> saveGoals(Goals g, double weight) async {
    goals = g;
    weightKg = weight;
    notifyListeners();
    await _persist();
  }

  Future<void> clearEntries() async {
    _entries = [];
    notifyListeners();
    await _persist();
  }

  Future<void> addSampleData() async {
    final rnd = Random(7);
    const names = [
      'Running', 'Cycling', 'Strength training', 'Yoga',
      'Football', 'HIIT', 'Swimming', 'Walking'
    ];
    for (var i = 20; i >= 0; i--) {
      final day = isoDate(addDays(today(), -i));
      final steps = 4200 + rnd.nextInt(8800);
      _entries.add(Entry(
        id: newId(),
        date: day,
        steps: steps,
        calories: estimateCalories('', 0, steps),
        estimated: true,
      ));
      if (rnd.nextDouble() < 0.6) {
        final ex = names[rnd.nextInt(names.length)];
        final min = 20 + rnd.nextInt(6) * 10;
        _entries.add(Entry(
          id: newId(),
          date: day,
          exercise: ex,
          minutes: min,
          calories: estimateCalories(ex, min, 0),
          estimated: true,
        ));
      }
    }
    tabIndex = 0;
    notifyListeners();
    await _persist();
  }

  String toCsv() {
    String cell(String v) =>
        RegExp(r'[",\n]').hasMatch(v) ? '"${v.replaceAll('"', '""')}"' : v;
    final sorted = [..._entries]..sort((a, b) => a.date.compareTo(b.date));
    final rows = <String>[
      'date,exercise,minutes,steps,calories,calories_estimated,note'
    ];
    for (final e in sorted) {
      rows.add([
        e.date,
        e.exercise,
        '${e.minutes}',
        '${e.steps}',
        '${e.calories}',
        e.estimated ? 'yes' : 'no',
        e.note,
      ].map(cell).join(','));
    }
    return rows.join('\n');
  }
}

/// Makes [AppState] available to the widget tree.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found above this widget');
    return scope!.notifier!;
  }
}
