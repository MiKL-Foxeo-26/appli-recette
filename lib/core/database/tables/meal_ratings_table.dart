import 'package:drift/drift.dart';

import 'members_table.dart';
import 'recipes_table.dart';

/// Table des notations par membre et recette
class MealRatings extends Table {
  TextColumn get id => text()();
  TextColumn get memberId =>
      text().references(Members, #id, onDelete: KeyAction.cascade)();
  TextColumn get recipeId =>
      text().references(Recipes, #id, onDelete: KeyAction.cascade)();
  TextColumn get rating => text()(); // liked, neutral, disliked
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {memberId, recipeId},
      ];
}
