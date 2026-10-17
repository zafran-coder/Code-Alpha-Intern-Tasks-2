import '../utils/dates.dart';

/// MET values used to estimate calories (MET x weight in kg x hours).
const Map<String, double> kExercises = {
  'Walking': 3.5,
  'Running': 9.8,
  'Cycling': 7.5,
  'Swimming': 8.0,
  'Strength training': 5.0,
  'HIIT': 8.0,
  'Yoga': 2.5,
  'Football': 7.0,
  'Cricket': 5.0,
  'Other': 4.0,
};

int _asInt(Object? v) {
  if (v is num) return v.round();
  return int.tryParse('$v') ?? 0;
}

/// One logged activity: steps, a workout, or both.
class Entry {
  const Entry({
    required this.id,
    required this.date,
    this.exercise = '',
    this.minutes = 0,
    this.steps = 0,
    this.calories = 0,
    this.estimated = false,
    this.note = '',
  });

  final String id;

  /// Day in yyyy-MM-dd form.
  final String date;
  final String exercise;
  final int minutes;
  final int steps;
  final int calories;

  /// True when calories were calculated by the app instead of typed in.
  final bool estimated;
  final String note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'exercise': exercise,
        'minutes': minutes,
        'steps': steps,
        'calories': calories,
        'estimated': estimated,
        'note': note,
      };

  factory Entry.fromJson(Map<String, dynamic> j) => Entry(
        id: (j['id'] ?? '').toString(),
        date: (j['date'] ?? '').toString(),
        exercise: (j['exercise'] ?? '').toString(),
        minutes: _asInt(j['minutes']),
        steps: _asInt(j['steps']),
        calories: _asInt(j['calories']),
        estimated: j['estimated'] == true,
        note: (j['note'] ?? '').toString(),
      );

  /// e.g. "35 min · 8,200 steps · 320 kcal (est.)"
  String get meta {
    final parts = <String>[];
    if (minutes > 0) parts.add('$minutes min');
    if (steps > 0) parts.add('${fmtInt(steps)} steps');
    if (calories > 0) {
      parts.add('${fmtInt(calories)} kcal${estimated ? ' (est.)' : ''}');
    }
    return parts.join(' · ');
  }

  String get title => exercise.isEmpty ? 'Steps' : exercise;
}

class Goals {
  const Goals({this.steps = 10000, this.minutes = 45, this.calories = 500});

  final int steps;
  final int minutes;
  final int calories;

  Map<String, dynamic> toJson() =>
      {'steps': steps, 'minutes': minutes, 'calories': calories};

  factory Goals.fromJson(Map<String, dynamic> j) {
    const d = Goals();
    int pick(String k, int fallback) {
      final v = _asInt(j[k]);
      return v > 0 ? v : fallback;
    }

    return Goals(
      steps: pick('steps', d.steps),
      minutes: pick('minutes', d.minutes),
      calories: pick('calories', d.calories),
    );
  }
}

/// Sum of all entries for one day.
class DayTotals {
  const DayTotals({
    this.steps = 0,
    this.minutes = 0,
    this.calories = 0,
    this.count = 0,
  });

  final int steps;
  final int minutes;
  final int calories;
  final int count;
}
