import 'package:flutter/material.dart';

import '../models/entry.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils/dates.dart';
import '../widgets/bar_chart.dart';
import '../widgets/panel.dart';
import '../widgets/rings.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final g = app.goals;
    final sel = app.selected;
    final t = app.totalsFor(sel);
    final isToday = sameDay(sel, today());

    final fSteps = t.steps / g.steps;
    final fMinutes = t.minutes / g.minutes;
    final fCalories = t.calories / g.calories;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        ScreenHeader(
          title: isToday ? 'Today' : longDate(sel),
          subtitle: _summaryLine(t, g),
        ),
        const SizedBox(height: 16),
        const _WeekNav(),
        const SizedBox(height: 16),

        // Daily progress
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 24,
                runSpacing: 20,
                children: [
                  AnimatedRings(
                    steps: fSteps,
                    minutes: fMinutes,
                    calories: fCalories,
                  ),
                  SizedBox(
                    width: 250,
                    child: Column(
                      children: [
                        _MetricRow(
                          color: kSteps,
                          name: 'Steps',
                          value: t.steps,
                          goal: g.steps,
                          unit: '',
                        ),
                        const SizedBox(height: 18),
                        _MetricRow(
                          color: kMove,
                          name: 'Workout minutes',
                          value: t.minutes,
                          goal: g.minutes,
                          unit: ' min',
                        ),
                        const SizedBox(height: 18),
                        _MetricRow(
                          color: kKcal,
                          name: 'Calories burned',
                          value: t.calories,
                          goal: g.calories,
                          unit: ' kcal',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: kLine, height: 1),
              const SizedBox(height: 16),
              const Text(
                'Logged this day',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 10),
              _DayList(entries: app.entriesOn(sel)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Weekly summary
        const _WeekSummary(),
        const SizedBox(height: 16),

        // Chart
        const _ChartPanel(),
      ],
    );
  }

  static String _summaryLine(DayTotals t, Goals g) {
    if (t.count == 0) return 'Nothing logged for this day yet.';
    final left = <String>[];
    if (t.steps < g.steps) left.add('${fmtInt(g.steps - t.steps)} steps');
    if (t.minutes < g.minutes) {
      left.add('${fmtInt(g.minutes - t.minutes)} workout minutes');
    }
    if (t.calories < g.calories) {
      left.add('${fmtInt(g.calories - t.calories)} kcal');
    }
    if (left.isEmpty) return 'All three goals reached. Nice work.';
    if (left.length == 1) return '${left.first} to go.';
    final last = left.removeLast();
    return '${left.join(', ')} and $last to go.';
  }
}

class _WeekNav extends StatelessWidget {
  const _WeekNav();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final start = app.weekStart;
    final end = addDays(start, 6);
    final sameMonth = start.month == end.month;
    final label =
        '${start.day}${sameMonth ? '' : ' ${kMonthShort[start.month - 1]}'} – ${end.day} ${kMonthShort[end.month - 1]}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.outlined(
          tooltip: 'Previous week',
          onPressed: () => app.shiftWeek(-1),
          icon: const Icon(Icons.chevron_left),
        ),
        SizedBox(
          width: 150,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        IconButton.outlined(
          tooltip: 'Next week',
          onPressed: app.canGoNextWeek ? () => app.shiftWeek(1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.color,
    required this.name,
    required this.value,
    required this.goal,
    required this.unit,
  });

  final Color color;
  final String name;
  final int value;
  final int goal;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final f = (value / goal).clamp(0.0, 1.0).toDouble();
    return Semantics(
      label: '$name: ${fmtInt(value)} of ${fmtInt(goal)}$unit',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                fmtInt(value),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: kInk,
                ),
              ),
              Text(
                ' / ${fmtInt(goal)}$unit',
                style: const TextStyle(color: kMuted, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: f),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 10,
                backgroundColor: kTrack,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayList extends StatelessWidget {
  const _DayList({required this.entries});

  final List<Entry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Row(
        children: [
          const Expanded(
            child: Text('No entries yet.', style: TextStyle(color: kMuted)),
          ),
          TextButton(
            onPressed: () => AppScope.of(context).goTo(1),
            child: const Text('Log activity'),
          ),
        ],
      );
    }
    return Column(
      children: [
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e.meta,
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: kMuted, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _WeekSummary extends StatelessWidget {
  const _WeekSummary();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final now = today();
    var steps = 0, minutes = 0, calories = 0, activeDays = 0, elapsed = 0;
    for (var i = 0; i < 7; i++) {
      final d = addDays(app.weekStart, i);
      final t = app.totalsFor(d);
      steps += t.steps;
      minutes += t.minutes;
      calories += t.calories;
      if (t.count > 0) activeDays++;
      if (!d.isAfter(now)) elapsed++;
    }
    final avg = elapsed == 0 ? 0 : steps / elapsed;
    final streak = app.streak();

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This week',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 16),
          Row(children: [
            _Stat(label: 'Steps', value: fmtInt(steps)),
            _Stat(label: 'Daily average', value: fmtInt(avg), unit: 'steps'),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            _Stat(label: 'Workout time', value: fmtInt(minutes), unit: 'min'),
            _Stat(label: 'Calories burned', value: fmtInt(calories), unit: 'kcal'),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            _Stat(
              label: 'Active days',
              value: '$activeDays',
              unit: 'of ${elapsed == 0 ? 7 : elapsed}',
            ),
            _Stat(
              label: 'Current streak',
              value: '$streak',
              unit: streak == 1 ? 'day' : 'days',
            ),
          ]),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.unit});

  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: kMuted, fontSize: 13)),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: kInk,
              ),
              children: [
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: kMuted,
                      letterSpacing: 0,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final now = today();

    final m = app.metric;
    final title = m == Metric.steps
        ? 'Steps per day'
        : m == Metric.calories
            ? 'Calories burned per day'
            : 'Workout minutes per day';
    final color = m == Metric.steps
        ? kSteps
        : m == Metric.calories
            ? kKcal
            : kMove;
    final goal = m == Metric.steps
        ? app.goals.steps
        : m == Metric.calories
            ? app.goals.calories
            : app.goals.minutes;
    int pick(DayTotals t) => m == Metric.steps
        ? t.steps
        : m == Metric.calories
            ? t.calories
            : t.minutes;

    final items = <BarItem>[
      for (var i = 0; i < 7; i++)
        () {
          final d = addDays(app.weekStart, i);
          return BarItem(
            date: d,
            label: kWeekdayShort[d.weekday - 1],
            sub: '${d.day}',
            value: pick(app.totalsFor(d)),
            future: d.isAfter(now),
          );
        }(),
    ];

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<Metric>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: Metric.steps, label: Text('Steps')),
                ButtonSegment(value: Metric.calories, label: Text('Calories')),
                ButtonSegment(value: Metric.minutes, label: Text('Minutes')),
              ],
              selected: {app.metric},
              onSelectionChanged: (s) => app.setMetric(s.first),
            ),
          ),
          const SizedBox(height: 16),
          WeekBarChart(
            items: items,
            goal: goal,
            color: color,
            selected: app.selected,
            onPick: app.selectDay,
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap a bar to see that day above. The dashed line is your daily goal.',
            style: TextStyle(color: kMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
