import 'package:drift/drift.dart';

/// Table des recettes
class Recipes extends Table {
  // Identifiant UUID v4
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get mealType => text()(); // breakfast, lunch, dinner, snack, dessert
  IntColumn get prepTimeMinutes => integer().withDefault(const Constant(0))();
  IntColumn get cookTimeMinutes => integer().withDefault(const Constant(0))();
  IntColumn get restTimeMinutes => integer().withDefault(const Constant(0))();
  TextColumn get season =>
      text().withDefault(const Constant('all'))(); // spring,summer,autumn,winter,all
  BoolColumn get isVegetarian => boolean().withDefault(const Constant(false))();
  IntColumn get servings => integer().withDefault(const Constant(4))();
  TextColumn get notes => text().nullable()();
  TextColumn get variants => text().nullable()();
  TextColumn get sourceUrl => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  TextColumn get photoSupabasePath => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  // Pour la synchronisation Supabase
  TextColumn get householdId => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
