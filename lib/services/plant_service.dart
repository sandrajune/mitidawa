import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/plant.dart';

class PlantService {
  final SupabaseClient _supabase;

  String? _lastFetchError;
  String? get lastFetchError => _lastFetchError;

  PlantService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  Future<List<Plant>> _fetchFromTable(String tableName) async {
    final response = await _supabase.from(tableName).select('*');

    return (response as List)
        .map((row) => Plant.fromMap(
              row['plant_id'].toString(),
              Map<String, dynamic>.from(row),
            ))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<List<Plant>> fetchPlants() async {
    _lastFetchError = null;

    const candidateTables = [
      'plants',
      'Plants',
      'plant_catalogue',
      'plant_catalog',
    ];

    final errors = <String>[];

    for (final table in candidateTables) {
      try {
        final plants = await _fetchFromTable(table);
        if (plants.isNotEmpty) {
          _lastFetchError = null;
          return plants;
        }
      } catch (e) {
        errors.add('$table: $e');
      }
    }

    if (errors.isNotEmpty) {
      _lastFetchError =
          'Could not load plants from Supabase. This is usually a table name mismatch or RLS permission issue. '
          'Checked tables: ${candidateTables.join(', ')}. '
          'Details: ${errors.join(' | ')}';
    } else {
      _lastFetchError =
          'No plant records were found. Please confirm your Supabase table has data.';
    }

    return [];
  }

  Future<List<String>> fetchConditions() async {
    final plants = await fetchPlants();
    final conditions = <String>{};

    for (final plant in plants) {
      for (final condition in plant.helpsWith) {
        if (condition.trim().isNotEmpty) {
          conditions.add(condition.trim());
        }
      }
    }

    if (conditions.isEmpty) {
      return const [
        'Headache',
        'Cough',
        'Skin Rash',
        'Low Energy',
        'Stomach Pain',
        'Fever',
      ];
    }

    final sorted = conditions.toList()..sort();
    return sorted;
  }

  Future<List<Plant>> fetchPlantsForCondition(String condition) async {
    final plants = await fetchPlants();
    final query = condition.trim().toLowerCase();

    return plants.where((plant) {
      return plant.helpsWith.any((c) => c.toLowerCase() == query);
    }).toList();
  }
}
