import 'package:appli_recette/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Source de données locale pour le planning de présence (drift / SQLite).
class PresenceLocalDatasource {
  PresenceLocalDatasource(this._db);

  final AppDatabase _db;

  /// Stream des présences type (weekKey == null), triées par memberId puis dayOfWeek.
  Stream<List<PresenceSchedule>> watchDefaultSchedule() {
    return (_db.select(_db.presenceSchedules)
          ..where((t) => t.weekKey.isNull())
          ..orderBy([
            (t) => OrderingTerm.asc(t.memberId),
            (t) => OrderingTerm.asc(t.dayOfWeek),
            (t) => OrderingTerm.asc(t.mealSlot),
          ]))
        .watch();
  }

  /// Initialise le planning type pour un membre : 14 entrées (7 jours x 2 repas),
  /// toutes avec isPresent = true.
  Future<void> initDefaultScheduleForMember(String memberId) async {
    await _db.batch((batch) {
      for (var day = 1; day <= 7; day++) {
        for (final slot in ['lunch', 'dinner']) {
          batch.insert(
            _db.presenceSchedules,
            PresenceSchedulesCompanion.insert(
              id: const Uuid().v4(),
              memberId: memberId,
              dayOfWeek: day,
              mealSlot: slot,
            ),
          );
        }
      }
    });
  }

  /// Bascule la valeur isPresent d'une entrée existante dans le planning type.
  Future<void> togglePresence(
    String memberId,
    int dayOfWeek,
    String mealSlot,
  ) async {
    // Chercher l'entrée existante (planning type = weekKey null)
    final existing = await (_db.select(_db.presenceSchedules)
          ..where(
            (t) =>
                t.memberId.equals(memberId) &
                t.dayOfWeek.equals(dayOfWeek) &
                t.mealSlot.equals(mealSlot) &
                t.weekKey.isNull(),
          ))
        .getSingleOrNull();

    if (existing != null) {
      await (_db.update(_db.presenceSchedules)
            ..where((t) => t.id.equals(existing.id)))
          .write(
        PresenceSchedulesCompanion(
          isPresent: Value(!existing.isPresent),
        ),
      );
    }
  }

  /// Supprime toutes les entrées du planning type pour un membre.
  Future<void> deleteSchedulesForMember(String memberId) async {
    await (_db.delete(_db.presenceSchedules)
          ..where(
            (t) => t.memberId.equals(memberId) & t.weekKey.isNull(),
          ))
        .go();
  }

  /// Retourne les IDs des membres qui ont déjà un planning type initialisé.
  Future<List<String>> getMembersWithDefaultSchedule() async {
    final query = _db.selectOnly(_db.presenceSchedules, distinct: true)
      ..addColumns([_db.presenceSchedules.memberId])
      ..where(_db.presenceSchedules.weekKey.isNull());
    final rows = await query.get();
    return rows
        .map((row) => row.read(_db.presenceSchedules.memberId)!)
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Weekly overrides (weekKey != null) — Story 4.2
  // ---------------------------------------------------------------------------

  /// Stream des overrides pour une semaine donnée.
  Stream<List<PresenceSchedule>> watchWeeklySchedule(String weekKey) {
    return (_db.select(_db.presenceSchedules)
          ..where((t) => t.weekKey.equals(weekKey))
          ..orderBy([
            (t) => OrderingTerm.asc(t.memberId),
            (t) => OrderingTerm.asc(t.dayOfWeek),
            (t) => OrderingTerm.asc(t.mealSlot),
          ]))
        .watch();
  }

  /// Bascule (crée ou modifie) un override de présence pour une semaine.
  ///
  /// Si aucun override n'existe pour ce créneau, en crée un avec la valeur
  /// inverse du planning type. Si un override existe, bascule sa valeur.
  Future<void> toggleWeeklyPresence(
    String weekKey,
    String memberId,
    int dayOfWeek,
    String mealSlot,
  ) async {
    // Chercher un override existant
    final existing = await (_db.select(_db.presenceSchedules)
          ..where(
            (t) =>
                t.memberId.equals(memberId) &
                t.dayOfWeek.equals(dayOfWeek) &
                t.mealSlot.equals(mealSlot) &
                t.weekKey.equals(weekKey),
          ))
        .getSingleOrNull();

    if (existing != null) {
      // Override existe : basculer
      await (_db.update(_db.presenceSchedules)
            ..where((t) => t.id.equals(existing.id)))
          .write(
        PresenceSchedulesCompanion(isPresent: Value(!existing.isPresent)),
      );
    } else {
      // Pas d'override : lire le planning type pour obtenir la valeur actuelle
      final defaultEntry = await (_db.select(_db.presenceSchedules)
            ..where(
              (t) =>
                  t.memberId.equals(memberId) &
                  t.dayOfWeek.equals(dayOfWeek) &
                  t.mealSlot.equals(mealSlot) &
                  t.weekKey.isNull(),
            ))
          .getSingleOrNull();

      final currentValue = defaultEntry?.isPresent ?? true;

      // Créer l'override avec la valeur inversée
      await _db.into(_db.presenceSchedules).insert(
            PresenceSchedulesCompanion.insert(
              id: const Uuid().v4(),
              memberId: memberId,
              dayOfWeek: dayOfWeek,
              mealSlot: mealSlot,
              weekKey: Value(weekKey),
              isPresent: Value(!currentValue),
            ),
          );
    }
  }

  /// Supprime tous les overrides d'une semaine.
  Future<void> deleteWeeklyOverrides(String weekKey) async {
    await (_db.delete(_db.presenceSchedules)
          ..where((t) => t.weekKey.equals(weekKey)))
        .go();
  }

  /// Retourne true si des overrides existent pour la semaine.
  Future<bool> hasWeeklyOverrides(String weekKey) async {
    final count = await (_db.selectOnly(_db.presenceSchedules)
          ..addColumns([_db.presenceSchedules.id.count()])
          ..where(_db.presenceSchedules.weekKey.equals(weekKey)))
        .map((row) => row.read(_db.presenceSchedules.id.count())!)
        .getSingle();
    return count > 0;
  }
}
