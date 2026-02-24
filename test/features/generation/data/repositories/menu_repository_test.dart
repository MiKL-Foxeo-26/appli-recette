import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/features/generation/data/datasources/menu_local_datasource.dart';
import 'package:appli_recette/features/generation/data/repositories/menu_repository_impl.dart';
import 'package:appli_recette/features/generation/domain/models/meal_slot_result.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _buildDb() => AppDatabase.forTesting(NativeDatabase.memory());

/// Insère une recette minimale dans la DB pour satisfaire la FK menu_slots.recipeId.
Future<void> _insertRecipe(AppDatabase db, String id) async {
  final now = DateTime.now();
  await db.into(db.recipes).insert(
        RecipesCompanion.insert(
          id: id,
          name: 'Recette $id',
          mealType: 'lunch',
          prepTimeMinutes: const Value(0),
          createdAt: now,
          updatedAt: now,
        ),
      );
}

void main() {
  late AppDatabase db;
  late MenuRepositoryImpl repo;

  setUp(() {
    db = _buildDb();
    repo = MenuRepositoryImpl(MenuLocalDatasource(db));
  });

  tearDown(() async {
    await db.close();
  });

  group('MenuRepository — saveValidatedMenu', () {
    test('crée les enregistrements WeeklyMenu et MenuSlot corrects', () async {
      await _insertRecipe(db, 'r1');
      await _insertRecipe(db, 'r2');
      await _insertRecipe(db, 'r3');

      final slots = [
        const MealSlotResult(recipeId: 'r1', dayIndex: 0, mealType: 'lunch'),
        const MealSlotResult(recipeId: 'r2', dayIndex: 0, mealType: 'dinner'),
        null, // créneau vide
        const MealSlotResult(recipeId: 'r3', dayIndex: 1, mealType: 'lunch'),
        ...List<MealSlotResult?>.filled(10, null),
      ];

      final menuId = await repo.saveValidatedMenu(
        weekKey: '2026-W09',
        slots: slots,
      );

      expect(menuId, isNotEmpty);

      // Vérifier les slots en DB
      final savedSlots = await repo.getSlotsForMenu(menuId);
      expect(savedSlots.length, 3); // r1, r2, r3 (pas le null)

      final recipeIds = savedSlots.map((s) => s.recipeId).toSet();
      expect(recipeIds, containsAll(['r1', 'r2', 'r3']));
    });

    test('upsert remplace les anciens slots pour la même semaine', () async {
      await _insertRecipe(db, 'r1');
      await _insertRecipe(db, 'r2');
      await _insertRecipe(db, 'r3');

      // Premier save
      final slots1 = [
        const MealSlotResult(recipeId: 'r1', dayIndex: 0, mealType: 'lunch'),
        ...List<MealSlotResult?>.filled(13, null),
      ];
      await repo.saveValidatedMenu(weekKey: '2026-W09', slots: slots1);

      // Deuxième save (même semaine)
      final slots2 = [
        const MealSlotResult(recipeId: 'r2', dayIndex: 0, mealType: 'lunch'),
        const MealSlotResult(recipeId: 'r3', dayIndex: 1, mealType: 'lunch'),
        ...List<MealSlotResult?>.filled(12, null),
      ];
      final menuId2 = await repo.saveValidatedMenu(
        weekKey: '2026-W09',
        slots: slots2,
      );

      // Vérifier : seuls les nouveaux slots existent
      final savedSlots = await repo.getSlotsForMenu(menuId2);
      expect(savedSlots.length, 2);
      final recipeIds = savedSlots.map((s) => s.recipeId).toSet();
      expect(recipeIds, containsAll(['r2', 'r3']));
      expect(recipeIds, isNot(contains('r1')));
    });

    test('les slots null ne créent pas d\'entrée dans menu_slots', () async {
      final slots = List<MealSlotResult?>.filled(14, null);
      final menuId = await repo.saveValidatedMenu(
        weekKey: '2026-W09',
        slots: slots,
      );

      final savedSlots = await repo.getSlotsForMenu(menuId);
      expect(savedSlots, isEmpty);
    });

    test('getMenuHistory retourne les menus triés par date DESC', () async {
      await repo.saveValidatedMenu(weekKey: '2026-W07', slots: []);
      await repo.saveValidatedMenu(weekKey: '2026-W09', slots: []);
      await repo.saveValidatedMenu(weekKey: '2026-W08', slots: []);

      final history = await repo.watchValidatedMenus().first;
      final weekKeys = history.map((m) => m.weekKey).toList();

      expect(weekKeys, equals(['2026-W09', '2026-W08', '2026-W07']));
    });

    test('getAllSlotsFromValidatedMenus retourne tous les slots de tous les menus', () async {
      await _insertRecipe(db, 'r1');
      await _insertRecipe(db, 'r2');
      await _insertRecipe(db, 'r3');

      await repo.saveValidatedMenu(
        weekKey: '2026-W07',
        slots: [
          const MealSlotResult(recipeId: 'r1', dayIndex: 0, mealType: 'lunch'),
        ],
      );
      await repo.saveValidatedMenu(
        weekKey: '2026-W08',
        slots: [
          const MealSlotResult(recipeId: 'r2', dayIndex: 0, mealType: 'lunch'),
          const MealSlotResult(recipeId: 'r3', dayIndex: 1, mealType: 'dinner'),
        ],
      );

      final allSlots = await repo.getAllSlotsFromValidatedMenus();
      expect(allSlots.length, 3);
    });

    test('les événements spéciaux ne créent pas de slot en DB', () async {
      await _insertRecipe(db, 'r1');

      final slots = [
        const MealSlotResult(
          recipeId: 'special_event',
          dayIndex: 0,
          mealType: 'lunch',
          isSpecialEvent: true,
        ),
        const MealSlotResult(recipeId: 'r1', dayIndex: 0, mealType: 'dinner'),
        ...List<MealSlotResult?>.filled(12, null),
      ];
      final menuId = await repo.saveValidatedMenu(
        weekKey: '2026-W09',
        slots: slots,
      );

      final savedSlots = await repo.getSlotsForMenu(menuId);
      expect(savedSlots.length, 1); // seulement r1
    });
  });
}
