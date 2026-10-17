import 'package:flutter/material.dart';

const Color kBg = Color(0xFFEBF0F6);
const Color kInk = Color(0xFF0F1B2D);
const Color kMuted = Color(0xFF586780);
const Color kLine = Color(0xFFD8E0EB);
const Color kTrack = Color(0xFFE3E9F2);
const Color kSteps = Color(0xFF2F4BFF);
const Color kMove = Color(0xFF0C9B92);
const Color kKcal = Color(0xFFE8532F);
const Color kDanger = Color(0xFFB3261E);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kSteps,
    brightness: Brightness.light,
  ).copyWith(primary: kInk, onPrimary: Colors.white);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kBg,
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Color(0xFFDDE5FF),
    ),
  );
}

/// Shared look for all text inputs.
InputDecoration fieldDecoration(String label, {String? hint, String? helper}) {
  const border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: kLine, width: 1.5),
  );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helper,
    helperMaxLines: 2,
    filled: true,
    fillColor: Colors.white,
    border: border,
    enabledBorder: border,
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: kSteps, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}
