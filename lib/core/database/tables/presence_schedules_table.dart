import 'package:drift/drift.dart';

import 'members_table.dart';

/// Table du planning de présence type
class PresenceSchedules extends Table {
  TextColumn get id => text()();
  TextColumn get memberId =>
      text().references(Members, #id, onDelete: KeyAction.cascade)();
  IntColumn get dayOfWeek => integer()(); // 1=lundi, 7=dimanche
  TextColumn get mealSlot => text()(); // lunch, dinner
  BoolColumn get isPresent => boolean().withDefault(const Constant(true))();
  // Pour les overrides ponctuels
  TextColumn get weekKey => text().nullable()(); // ex: "2026-W08" — null = planning type

  @override
  Set<Column<Object>> get primaryKey => {id};
}
