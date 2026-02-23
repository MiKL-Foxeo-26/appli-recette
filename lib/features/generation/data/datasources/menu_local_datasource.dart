import 'package:appli_recette/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Source de données locale pour les menus hebdomadaires (drift / SQLite).
class MenuLocalDatasource {
  MenuLocalDatasource(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  // ─────────────────────────────────────────────────────────────────────────
  // Lecture
  // ─────────────────────────────────────────────────────────────────────────

  /// Stream de tous les menus validés, triés par weekKey DESC.
  Stream<List<WeeklyMenu>> watchValidatedMenus() {
    return (_db.select(_db.weeklyMenus)
          ..where((t) => t.isValidated.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.weekKey)]))
        .watch();
  }

  /// Stream d'un menu par weekKey (peut être null si inexistant).
  Stream<WeeklyMenu?> watchMenuForWeek(String weekKey) {
    return (_db.select(_db.weeklyMenus)
          ..where((t) => t.weekKey.equals(weekKey)))
        .watchSingleOrNull();
  }

  /// Récupère tous les slots d'un menu donné.
  Future<List<MenuSlot>> getSlotsForMenu(String weeklyMenuId) {
    return (_db.select(_db.menuSlots)
          ..where((t) => t.weeklyMenuId.equals(weeklyMenuId)))
        .get();
  }

  /// Stream des slots d'un menu donné.
  Stream<List<MenuSlot>> watchSlotsForMenu(String weeklyMenuId) {
    return (_db.select(_db.menuSlots)
          ..where((t) => t.weeklyMenuId.equals(weeklyMenuId)))
        .watch();
  }

  /// Récupère TOUS les slots de TOUS les menus validés (pour anti-répétition).
  ///
  /// Utilise un JOIN pour éviter les N+1 requêtes SQL.
  Future<List<MenuSlot>> getAllSlotsFromValidatedMenus() async {
    final query = _db.select(_db.menuSlots).join([
      innerJoin(
        _db.weeklyMenus,
        _db.weeklyMenus.id.equalsExp(_db.menuSlots.weeklyMenuId),
      ),
    ])..where(_db.weeklyMenus.isValidated.equals(true));

    final rows = await query.get();
    return rows.map((row) => row.readTable(_db.menuSlots)).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Écriture
  // ─────────────────────────────────────────────────────────────────────────

  /// Sauvegarde (upsert) un menu validé et ses slots.
  ///
  /// Si un menu existe déjà pour [weekKey], il est remplacé (anciens slots supprimés).
  Future<String> saveValidatedMenu({
    required String weekKey,
    required List<_MenuSlotData> slots,
  }) async {
    return _db.transaction(() async {
      // Supprimer le menu existant pour cette semaine (cascade slots via FK)
      await (_db.delete(_db.weeklyMenus)
            ..where((t) => t.weekKey.equals(weekKey)))
          .go();

      // Insérer le nouveau menu
      final menuId = _uuid.v4();
      final now = DateTime.now().toUtc();
      await _db.into(_db.weeklyMenus).insert(
            WeeklyMenusCompanion.insert(
              id: menuId,
              weekKey: weekKey,
              generatedAt: now,
              validatedAt: Value(now),
              isValidated: const Value(true),
            ),
          );

      // Insérer les slots non-null
      await _db.batch((batch) {
        for (final slot in slots) {
          batch.insert(
            _db.menuSlots,
            MenuSlotsCompanion.insert(
              id: _uuid.v4(),
              weeklyMenuId: menuId,
              recipeId: Value(slot.recipeId),
              dayOfWeek: slot.dayOfWeek,
              mealSlot: slot.mealSlot,
            ),
          );
        }
      });

      return menuId;
    });
  }

  /// Crée ou met à jour un menu généré (non encore validé) pour une semaine.
  Future<String> saveGeneratedMenu({
    required String weekKey,
    required List<_MenuSlotData> slots,
  }) async {
    return _db.transaction(() async {
      await (_db.delete(_db.weeklyMenus)
            ..where(
              (t) =>
                  t.weekKey.equals(weekKey) &
                  t.isValidated.equals(false),
            ))
          .go();

      final menuId = _uuid.v4();
      final now = DateTime.now().toUtc();
      await _db.into(_db.weeklyMenus).insert(
            WeeklyMenusCompanion.insert(
              id: menuId,
              weekKey: weekKey,
              generatedAt: now,
            ),
          );

      await _db.batch((batch) {
        for (final slot in slots) {
          batch.insert(
            _db.menuSlots,
            MenuSlotsCompanion.insert(
              id: _uuid.v4(),
              weeklyMenuId: menuId,
              recipeId: Value(slot.recipeId),
              dayOfWeek: slot.dayOfWeek,
              mealSlot: slot.mealSlot,
            ),
          );
        }
      });

      return menuId;
    });
  }
}

/// DTO interne pour les données d'un slot à sauvegarder.
class _MenuSlotData {
  const _MenuSlotData({
    required this.dayOfWeek,
    required this.mealSlot,
    this.recipeId,
  });

  final int dayOfWeek; // 1=lundi, 7=dimanche
  final String mealSlot; // "lunch" ou "dinner"
  final String? recipeId;
}

/// Exposer _MenuSlotData publiquement pour le repository.
typedef MenuSlotData = _MenuSlotData;
