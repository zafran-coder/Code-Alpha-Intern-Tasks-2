import 'package:flutter_test/flutter_test.dart';
import 'package:stride_fitness/models/entry.dart';
import 'package:stride_fitness/services/storage.dart';
import 'package:stride_fitness/state/app_state.dart';
import 'package:stride_fitness/utils/dates.dart';

void main() {
  test('Entry survives a JSON round trip', () {
    const e = Entry(
      id: 'a1',
      date: '2026-10-15',
      exercise: 'Running',
      minutes: 30,
      steps: 4200,
      calories: 320,
      estimated: true,
      note: 'Lake loop',
    );
    final back = Entry.fromJson(e.toJson());
    expect(back.id, 'a1');
    expect(back.exercise, 'Running');
    expect(back.minutes, 30);
    expect(back.calories, 320);
    expect(back.estimated, true);
    expect(back.note, 'Lake loop');
  });

  test('fmtInt adds thousands separators', () {
    expect(fmtInt(0), '0');
    expect(fmtInt(999), '999');
    expect(fmtInt(10000), '10,000');
    expect(fmtInt(1234567), '1,234,567');
  });

  test('mondayOf returns the Monday of that week', () {
    // 2026-10-15 is a Thursday.
    final monday = mondayOf(DateTime(2026, 10, 15));
    expect(isoDate(monday), '2026-10-12');
    expect(isoDate(mondayOf(DateTime(2026, 10, 18))), '2026-10-12');
  });

  test('calorie estimate uses MET x kg x hours', () {
    final app = AppState(Storage());
    // Running 9.8 MET, 70 kg, 30 min = 343 kcal
    expect(app.estimateCalories('Running', 30, 0), 343);
    // Steps only: 10,000 steps at 70 kg = 400 kcal
    expect(app.estimateCalories('', 0, 10000), 400);
    expect(app.estimateCalories('', 0, 0), 0);
  });
}
