import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/ingredients_table.dart';
import 'tables/meal_ratings_table.dart';
import 'tables/members_table.dart';
import 'tables/menu_slots_table.dart';
import 'tables/presence_schedules_table.dart';
import 'tables/recipes_table.dart';
import 'tables/recipe_steps_table.dart';
import 'tables/sync_queue_table.dart';
import 'tables/weekly_menus_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Recipes,
    Ingredients,
    RecipeSteps,
    Members,
    MealRatings,
    PresenceSchedules,
    WeeklyMenus,
    MenuSlots,
    SyncQueue,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.createTable(recipeSteps);
        }
        if (from < 3) {
          // Story 8.4 : ajouter householdId aux tables sans cette colonne
          await m.addColumn(ingredients, ingredients.householdId);
          await m.addColumn(mealRatings, mealRatings.householdId);
          await m.addColumn(presenceSchedules, presenceSchedules.householdId);
          await m.addColumn(menuSlots, menuSlots.householdId);
        }
      },
      beforeOpen: (details) async {
        // Active les foreign keys pour que les CASCADE deletes fonctionnent
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'appli_recette.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
