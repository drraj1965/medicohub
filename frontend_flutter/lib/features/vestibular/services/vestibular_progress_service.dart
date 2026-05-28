import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/vestibular_exercise.dart';

class VestibularProgressService {
  static const String _storageKey = 'vestibular_session_results_v1';

  Future<void> saveSession(VestibularSessionResult session) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final sessions = await getAllSessions();
      sessions.add(session);
      final encoded = jsonEncode(
        sessions.map((item) => item.toJson()).toList(growable: false),
      );
      await preferences.setString(_storageKey, encoded);
    } catch (_) {
      // Local progress should never make the exercise flow crash.
    }
  }

  Future<List<VestibularSessionResult>> getSessionsForExercise(
    String exerciseId,
  ) async {
    try {
      final sessions = await getAllSessions();
      return sessions
          .where((item) => item.exerciseId == exerciseId)
          .toList(growable: false);
    } catch (_) {
      return <VestibularSessionResult>[];
    }
  }

  Future<List<VestibularSessionResult>> getAllSessions() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_storageKey);
      if (raw == null || raw.isEmpty) {
        return <VestibularSessionResult>[];
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <VestibularSessionResult>[];
      }
      return decoded
          .whereType<Map>()
          .map((item) => VestibularSessionResult.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(growable: true)
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    } catch (_) {
      return <VestibularSessionResult>[];
    }
  }

  Future<void> clearProgress() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_storageKey);
    } catch (_) {
      // Best effort only.
    }
  }
}
