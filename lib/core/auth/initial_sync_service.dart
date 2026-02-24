import 'package:appli_recette/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Synchronisation initiale depuis Supabase vers drift local.
///
/// Utilisé lors du join d'un foyer existant (Story 7.2) — télécharge
/// toutes les entités du foyer et les upserte dans drift.
/// Les entrées importées sont marquées isSynced = true.
class InitialSyncService {
  InitialSyncService(this._db);

  final AppDatabase _db;

  SupabaseClient get _client => Supabase.instance.client;

  /// Télécharge toutes les données du foyer [householdId] depuis Supabase
  /// et les upserte dans drift.
  Future<void> syncFromSupabase(String householdId) async {
    await _syncMembers(householdId);
    await _syncRecipes(householdId);
  }

  // ── Members ───────────────────────────────────────────────────────────────

  Future<void> _syncMembers(String householdId) async {
    final rows = await _client
        .from('members')
        .select()
        .eq('household_id', householdId);

    final companions = (rows as List<dynamic>).map((row) {
      final m = row as Map<String, dynamic>;
      return MembersCompanion(
        id: Value(m['id'] as String),
        name: Value(m['name'] as String),
        age: Value(m['age'] as int?),
        householdId: Value(householdId),
        createdAt:
            Value(DateTime.parse(m['created_at'] as String).toLocal()),
        updatedAt:
            Value(DateTime.parse(m['updated_at'] as String).toLocal()),
        isSynced: const Value(true),
      );
    }).toList();

    if (companions.isNotEmpty) {
      await _db.batch((batch) {
        batch.insertAllOnConflictUpdate(_db.members, companions);
      });
    }
  }

  // ── Recipes ───────────────────────────────────────────────────────────────

  Future<void> _syncRecipes(String householdId) async {
    final rows = await _client
        .from('recipes')
        .select()
        .eq('household_id', householdId);

    final companions = (rows as List<dynamic>).map((row) {
      final r = row as Map<String, dynamic>;
      return RecipesCompanion(
        id: Value(r['id'] as String),
        name: Value(r['name'] as String),
        mealType: Value(r['meal_type'] as String),
        prepTimeMinutes:
            Value((r['prep_time_minutes'] as num?)?.toInt() ?? 0),
        cookTimeMinutes:
            Value((r['cook_time_minutes'] as num?)?.toInt() ?? 0),
        restTimeMinutes:
            Value((r['rest_time_minutes'] as num?)?.toInt() ?? 0),
        season: Value(r['season'] as String? ?? 'all'),
        isVegetarian: Value(r['is_vegetarian'] as bool? ?? false),
        servings: Value((r['servings'] as num?)?.toInt() ?? 4),
        notes: Value(r['notes'] as String?),
        variants: Value(r['variants'] as String?),
        sourceUrl: Value(r['source_url'] as String?),
        photoPath: Value(r['photo_path'] as String?),
        isFavorite: Value(r['is_favorite'] as bool? ?? false),
        createdAt:
            Value(DateTime.parse(r['created_at'] as String).toLocal()),
        updatedAt:
            Value(DateTime.parse(r['updated_at'] as String).toLocal()),
        householdId: Value(householdId),
        isSynced: const Value(true),
      );
    }).toList();

    if (companions.isNotEmpty) {
      await _db.batch((batch) {
        batch.insertAllOnConflictUpdate(_db.recipes, companions);
      });
    }
  }
}
