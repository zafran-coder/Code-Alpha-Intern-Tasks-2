import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/paint_utils.dart';

/// Three concentric rings: steps (outer), workout minutes, calories (inner).
/// Fractions are 0..1+ (values above 1 are drawn as a full ring).
class AnimatedRings extends StatelessWidget {
  const AnimatedRings({
    super.key,
    required this.steps,
    required this.minutes,
    required this.calories,
    this.size = 180,
  });

  final double steps;
  final double minutes;
  final double calories;
  final double size;

  static const Duration _duration = Duration(milliseconds: 900);

  @override
  Widget build(BuildContext context) {
    final goalsMet =
        [steps, minutes, calories].where((f) => f >= 1).length;

    return Semantics(
      label: 'Daily goal rings. $goalsMet of 3 goals met.',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: steps),
        duration: _duration,
        curve: Curves.easeOutCubic,
        builder: (context, a, _) => TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: minutes),
          duration: _duration,
          curve: Curves.easeOutCubic,
          builder: (context, b, _) => TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: calories),
            duration: _duration,
            curve: Curves.easeOutCubic,
            builder: (context, c, _) => CustomPaint(
              size: Size.square(size),
              painter: _RingsPainter(
                fractions: [a, b, c],
                goalsMet: goalsMet,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({required this.fractions, required this.goalsMet});

  final List<double> fractions;
  final int goalsMet;

  static const List<Color> _colors = [kSteps, kMove, kKcal];
  static const List<double> _radii = [84, 62, 40];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final scale = size.width / 200;
    final stroke = 14.0 * scale;

    for (var i = 0; i < 3; i++) {
      final radius = _radii[i] * scale;

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = kTrack,
      );

      final f = fractions[i].clamp(0.0, 1.0).toDouble();
      if (f > 0.001) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -math.pi / 2,
          2 * math.pi * f,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeCap = StrokeCap.round
            ..color = _colors[i],
        );
      }
    }

    drawText(
      canvas,
      '$goalsMet/3',
      center.translate(0, -4 * scale),
      TextStyle(
        fontSize: 22 * scale,
        fontWeight: FontWeight.w800,
        color: kInk,
      ),
    );
    drawText(
      canvas,
      'goals met',
      center.translate(0, 14 * scale),
      TextStyle(fontSize: 9 * scale, color: kMuted),
    );
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) =>
      old.goalsMet != goalsMet ||
      old.fractions[0] != fractions[0] ||
      old.fractions[1] != fractions[1] ||
      old.fractions[2] != fractions[2];
}
