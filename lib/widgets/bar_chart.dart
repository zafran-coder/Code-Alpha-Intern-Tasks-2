import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/paint_utils.dart';

/// One bar (one day) in the weekly chart.
class BarItem {
  const BarItem({
    required this.date,
    required this.label,
    required this.sub,
    required this.value,
    required this.future,
  });

  final DateTime date;

  /// Weekday, e.g. "Mon".
  final String label;

  /// Day of month, e.g. "12".
  final String sub;
  final int value;

  /// Days after today are drawn as an empty slot and cannot be selected.
  final bool future;
}

const double _padL = 40;
const double _padR = 8;
const double _padT = 22;
const double _padB = 42;

class WeekBarChart extends StatelessWidget {
  const WeekBarChart({
    super.key,
    required this.items,
    required this.goal,
    required this.color,
    required this.selected,
    required this.onPick,
    this.height = 230,
  });

  final List<BarItem> items;
  final int goal;
  final Color color;
  final DateTime selected;
  final ValueChanged<DateTime> onPick;
  final double height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            final slot = (width - _padL - _padR) / items.length;
            final index = ((details.localPosition.dx - _padL) / slot).floor();
            if (index < 0 || index >= items.length) return;
            if (items[index].future) return;
            onPick(items[index].date);
          },
          child: CustomPaint(
            size: Size(width, height),
            painter: _BarChartPainter(
              items: items,
              goal: goal,
              color: color,
              selected: selected,
            ),
          ),
        );
      },
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.items,
    required this.goal,
    required this.color,
    required this.selected,
  });

  final List<BarItem> items;
  final int goal;
  final Color color;
  final DateTime selected;

  static const List<double> _nice = [
    1, 1.2, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10
  ];

  static double _niceMax(double v) {
    if (v <= 0) return 1;
    final pow10 = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
    final n = v / pow10;
    for (final step in _nice) {
      if (n <= step) return step * pow10;
    }
    return 10 * pow10;
  }

  static String _short(num n) {
    if (n >= 1000) {
      final k = n / 1000;
      return k == k.roundToDouble()
          ? '${k.round()}k'
          : '${k.toStringAsFixed(1)}k';
    }
    return '${n.round()}';
  }

  @override
  void paint(Canvas canvas, Size size) {
    final plotW = size.width - _padL - _padR;
    final plotH = size.height - _padT - _padB;
    final slot = plotW / items.length;
    final barW = math.min(slot * 0.58, 44.0);

    var top = math.max(goal, 1).toDouble();
    for (final it in items) {
      if (it.value > top) top = it.value.toDouble();
    }
    final maxV = _niceMax(top * 1.08);

    double yOf(num v) => _padT + plotH - (v / maxV) * plotH;

    const axisStyle = TextStyle(fontSize: 11, color: kMuted);

    // gridlines + y-axis labels
    final gridPaint = Paint()
      ..color = kTrack
      ..strokeWidth = 1;
    for (final f in const [0.0, 0.5, 1.0]) {
      final y = yOf(maxV * f);
      canvas.drawLine(Offset(_padL, y), Offset(size.width - _padR, y), gridPaint);
      drawText(canvas, _short(maxV * f), Offset(_padL - 6, y), axisStyle,
          anchorX: 1);
    }

    // bars + labels
    for (var i = 0; i < items.length; i++) {
      final it = items[i];
      final cx = _padL + slot * i + slot / 2;
      final isSel = sameDate(it.date, selected);

      if (it.future) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - barW / 2, yOf(0) - 4, barW, 4),
            const Radius.circular(2),
          ),
          Paint()..color = kTrack,
        );
      } else if (it.value > 0) {
        final h = (it.value / maxV) * plotH;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - barW / 2, yOf(it.value), barW, h),
            const Radius.circular(8),
          ),
          Paint()..color = color.withAlpha(isSel ? 255 : 130),
        );
        drawText(
          canvas,
          _short(it.value),
          Offset(cx, yOf(it.value) - 9),
          const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: kInk,
          ),
        );
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - barW / 2, yOf(0) - 4, barW, 4),
            const Radius.circular(2),
          ),
          Paint()..color = const Color(0xFFC9D3E1),
        );
      }

      final labelStyle = TextStyle(
        fontSize: 11,
        fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
        color: isSel ? kInk : kMuted,
      );
      drawText(canvas, it.label, Offset(cx, size.height - 26), labelStyle);
      drawText(canvas, it.sub, Offset(cx, size.height - 11), labelStyle);
    }

    // dashed goal line, drawn last so it sits on top
    if (goal > 0) {
      final gy = yOf(goal);
      final dash = Paint()
        ..color = kInk
        ..strokeWidth = 1.5;
      var x = _padL;
      while (x < size.width - _padR) {
        canvas.drawLine(
          Offset(x, gy),
          Offset(math.min(x + 5, size.width - _padR), gy),
          dash,
        );
        x += 10;
      }
      drawText(
        canvas,
        'Goal ${_short(goal)}',
        Offset(size.width - _padR, gy - 9),
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kInk),
        anchorX: 1,
      );
    }
  }

  static bool sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  bool shouldRepaint(covariant _BarChartPainter old) => true;
}
