import 'package:drift/drift.dart';

import 'recipes_table.dart';
import 'weekly_menus_table.dart';

/// Table des créneaux repas dans un menu hebdomadaire
class MenuSlots extends Table {
  TextColumn get id => text()();
  TextColumn get weeklyMenuId =>
      text().references(WeeklyMenus, #id, onDelete: KeyAction.cascade)();
  TextColumn get recipeId =>
      text().references(Recipes, #id, onDelete: KeyAction.setNull).nullable()();
  IntColumn get dayOfWeek => integer()(); // 1=lundi, 7=dimanche
  TextColumn get mealSlot => text()(); // lunch, dinner
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
