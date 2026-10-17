import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/entry.dart';

/// Everything the app persists.
class StoredData {
  const StoredData({
    this.entries = const [],
    this.goals = const Goals(),
    this.weightKg = 70,
  });

  final List<Entry> entries;
  final Goals goals;
  final double weightKg;
}

/// Saves and loads app data on the device (shared_preferences, JSON).
///
/// To use SQLite or Firebase instead, keep these two method signatures and
/// change what happens inside them. The rest of the app does not care.
class Storage {
  static const String _key = 'stride.fitness.v1';

  Future<StoredData> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return const StoredData();

      final map = jsonDecode(raw) as Map<String, dynamic>;
      final list = (map['entries'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Entry.fromJson)
          .where((e) => e.id.isNotEmpty && e.date.length == 10)
          .toList();
      final goals = map['goals'] is Map<String, dynamic>
          ? Goals.fromJson(map['goals'] as Map<String, dynamic>)
          : const Goals();
      final w = (map['weight'] as num?)?.toDouble() ?? 70;

      return StoredData(
        entries: list,
        goals: goals,
        weightKg: w > 0 ? w : 70,
      );
    } catch (_) {
      return const StoredData();
    }
  }

  Future<bool> save(StoredData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = {
        'entries': data.entries.map((e) => e.toJson()).toList(),
        'goals': data.goals.toJson(),
        'weight': data.weightKg,
      };
      return prefs.setString(_key, jsonEncode(map));
    } catch (_) {
      return false;
    }
  }
}
