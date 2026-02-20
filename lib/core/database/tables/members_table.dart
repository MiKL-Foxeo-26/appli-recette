import 'package:drift/drift.dart';

/// Table des membres du foyer
class Members extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get age => integer().nullable()();
  TextColumn get householdId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
