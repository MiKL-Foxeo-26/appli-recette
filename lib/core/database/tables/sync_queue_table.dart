import 'package:drift/drift.dart';

/// Table de la queue de synchronisation offline-first
class SyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get operation => text()(); // insert, update, delete
  TextColumn get entityTable => text()();
  TextColumn get recordId => text()();
  TextColumn get payload => text()(); // JSON serialisé
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
