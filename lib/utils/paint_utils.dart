import 'package:flutter/material.dart';

/// Draws [text] on a canvas.
///
/// [anchorX] is 0 (text starts at [at].dx), 0.5 (centered) or 1 (text ends at
/// [at].dx). The text is vertically centered on [at].dy.
void drawText(
  Canvas canvas,
  String text,
  Offset at,
  TextStyle style, {
  double anchorX = 0.5,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(
    canvas,
    Offset(at.dx - painter.width * anchorX, at.dy - painter.height / 2),
  );
}
