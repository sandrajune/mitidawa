import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ScanHistoryEntry {
  final String? plantName;
  final double confidence;
  final String? message;
  final DateTime timestamp;
  final String? imagePath;
  final String? scientificName;

  const ScanHistoryEntry({
    required this.plantName,
    required this.confidence,
    required this.message,
    required this.timestamp,
    this.imagePath,
    this.scientificName,
  });

  Map<String, dynamic> toMap() {
    return {
      'plantName': plantName,
      'confidence': confidence,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'imagePath': imagePath,
      'scientificName': scientificName,
    };
  }

  factory ScanHistoryEntry.fromMap(Map<String, dynamic> map) {
    return ScanHistoryEntry(
      plantName: map['plantName'] as String?,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      message: map['message'] as String?,
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
      imagePath: map['imagePath'] as String?,
      scientificName: map['scientificName'] as String?,
    );
  }
}

class ScanHistoryService {
  static const String _historyKey = 'scan_history_v1';
  static const int _maxEntries = 100;

  Future<List<ScanHistoryEntry>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? <String>[];

    return raw
        .map((item) {
          try {
            return ScanHistoryEntry.fromMap(
              Map<String, dynamic>.from(jsonDecode(item) as Map),
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<ScanHistoryEntry>()
        .toList();
  }

  Future<void> addEntry(ScanHistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_historyKey) ?? <String>[];
    final encoded = jsonEncode(entry.toMap());

    final updated = <String>[encoded, ...current];
    if (updated.length > _maxEntries) {
      updated.removeRange(_maxEntries, updated.length);
    }

    await prefs.setStringList(_historyKey, updated);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
