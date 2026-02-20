import 'package:drift/drift.dart';

import 'recipes_table.dart';

/// Table des ingrédients structurés
class Ingredients extends Table {
  TextColumn get id => text()();
  TextColumn get recipeId =>
      text().references(Recipes, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  RealColumn get quantity => real().nullable()();
  TextColumn get unit => text().nullable()();
  TextColumn get supermarketSection => text().nullable()(); // rayon supermarché

  @override
  Set<Column<Object>> get primaryKey => {id};
}
