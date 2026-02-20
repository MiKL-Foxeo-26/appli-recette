import 'package:drift/drift.dart';

/// Table des menus hebdomadaires validés
class WeeklyMenus extends Table {
  TextColumn get id => text()();
  TextColumn get weekKey => text()(); // ex: "2026-W08"
  DateTimeColumn get generatedAt => dateTime()();
  DateTimeColumn get validatedAt => dateTime().nullable()();
  BoolColumn get isValidated => boolean().withDefault(const Constant(false))();
  TextColumn get householdId => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
