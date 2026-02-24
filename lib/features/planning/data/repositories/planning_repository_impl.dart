import 'dart:convert';

import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/core/sync/sync_queue_datasource.dart';
import 'package:appli_recette/features/planning/data/datasources/presence_local_datasource.dart';
import 'package:appli_recette/features/planning/domain/repositories/planning_repository.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Implémentation concrète du PlanningRepository.
/// Délègue au datasource local (drift) et enfile dans la sync_queue.
class PlanningRepositoryImpl implements PlanningRepository {
  PlanningRepositoryImpl(this._datasource, this._syncQueue);

  final PresenceLocalDatasource _datasource;
  final SyncQueueDatasource _syncQueue;

  static const _keyHouseholdId = 'household_id';

  Future<String?> _getHouseholdId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyHouseholdId);
  }

  @override
  Stream<List<PresenceSchedule>> watchDefaultPresences() =>
      _datasource.watchDefaultSchedule();

  @override
  Future<void> togglePresence(
    String memberId,
    int dayOfWeek,
    String mealSlot,
  ) async {
    // Lire l'état avant le toggle pour calculer la nouvelle valeur
    final before = await _datasource.findPresence(
      memberId: memberId,
      dayOfWeek: dayOfWeek,
      mealSlot: mealSlot,
    );

    await _datasource.togglePresence(memberId, dayOfWeek, mealSlot);

    if (before != null) {
      final now = DateTime.now();
      final householdId = await _getHouseholdId();
      await _syncQueue.enqueue(
        SyncQueueCompanion.insert(
          id: const Uuid().v4(),
          operation: 'update',
          entityTable: 'presence_schedules',
          recordId: before.id,
          payload: jsonEncode({
            'id': before.id,
            'member_id': memberId,
            'day_of_week': dayOfWeek,
            'meal_slot': mealSlot,
            'is_present': !before.isPresent,
            if (householdId != null) 'household_id': householdId,
          }),
          createdAt: now,
        ),
      );
    }
  }

  @override
  Future<void> initializeDefaultForMember(String memberId) async {
    final ids = await _datasource.initDefaultScheduleForMember(memberId);
    final now = DateTime.now();
    final householdId = await _getHouseholdId();

    var dayIdx = 0;
    for (var day = 1; day <= 7; day++) {
      for (final slot in ['lunch', 'dinner']) {
        final id = ids[dayIdx++];
        await _syncQueue.enqueue(
          SyncQueueCompanion.insert(
            id: const Uuid().v4(),
            operation: 'insert',
            entityTable: 'presence_schedules',
            recordId: id,
            payload: jsonEncode({
              'id': id,
              'member_id': memberId,
              'day_of_week': day,
              'meal_slot': slot,
              'is_present': true,
              if (householdId != null) 'household_id': householdId,
            }),
            createdAt: now,
          ),
        );
      }
    }
  }

  @override
  Future<List<String>> getMembersWithDefaultSchedule() =>
      _datasource.getMembersWithDefaultSchedule();

  // ---------------------------------------------------------------------------
  // Weekly overrides — Story 4.2
  // ---------------------------------------------------------------------------

  @override
  Stream<List<PresenceSchedule>> watchWeeklyPresences(String weekKey) =>
      _datasource.watchWeeklySchedule(weekKey);

  @override
  Stream<List<PresenceSchedule>> watchMergedPresences(String weekKey) {
    return Rx.combineLatest2<List<PresenceSchedule>, List<PresenceSchedule>,
        List<PresenceSchedule>>(
      _datasource.watchDefaultSchedule(),
      _datasource.watchWeeklySchedule(weekKey),
      (defaults, overrides) {
        final overrideMap = <String, PresenceSchedule>{};
        for (final o in overrides) {
          overrideMap['${o.memberId}|${o.dayOfWeek}|${o.mealSlot}'] = o;
        }
        return defaults.map((d) {
          final key = '${d.memberId}|${d.dayOfWeek}|${d.mealSlot}';
          return overrideMap[key] ?? d;
        }).toList();
      },
    );
  }

  @override
  Future<void> toggleWeeklyPresence(
    String weekKey,
    String memberId,
    int dayOfWeek,
    String mealSlot,
  ) async {
    final before = await _datasource.findPresence(
      memberId: memberId,
      dayOfWeek: dayOfWeek,
      mealSlot: mealSlot,
      weekKey: weekKey,
    );

    await _datasource.toggleWeeklyPresence(weekKey, memberId, dayOfWeek, mealSlot);

    final now = DateTime.now();
    final householdId = await _getHouseholdId();

    if (before != null) {
      // Override existait → update
      await _syncQueue.enqueue(
        SyncQueueCompanion.insert(
          id: const Uuid().v4(),
          operation: 'update',
          entityTable: 'presence_schedules',
          recordId: before.id,
          payload: jsonEncode({
            'id': before.id,
            'member_id': memberId,
            'day_of_week': dayOfWeek,
            'meal_slot': mealSlot,
            'is_present': !before.isPresent,
            'week_key': weekKey,
            if (householdId != null) 'household_id': householdId,
          }),
          createdAt: now,
        ),
      );
    } else {
      // Nouvel override → insert (le datasource a créé un nouveau record, on le récupère)
      final created = await _datasource.findPresence(
        memberId: memberId,
        dayOfWeek: dayOfWeek,
        mealSlot: mealSlot,
        weekKey: weekKey,
      );
      if (created != null) {
        await _syncQueue.enqueue(
          SyncQueueCompanion.insert(
            id: const Uuid().v4(),
            operation: 'insert',
            entityTable: 'presence_schedules',
            recordId: created.id,
            payload: jsonEncode({
              'id': created.id,
              'member_id': memberId,
              'day_of_week': dayOfWeek,
              'meal_slot': mealSlot,
              'is_present': created.isPresent,
              'week_key': weekKey,
              if (householdId != null) 'household_id': householdId,
            }),
            createdAt: now,
          ),
        );
      }
    }
  }

  @override
  Future<void> resetWeekToDefault(String weekKey) async {
    // Récupérer tous les overrides avant suppression pour enqueue les deletes
    final overrides = await _datasource.getWeeklyPresences(weekKey);
    await _datasource.deleteWeeklyOverrides(weekKey);

    final now = DateTime.now();
    for (final override in overrides) {
      await _syncQueue.enqueue(
        SyncQueueCompanion.insert(
          id: const Uuid().v4(),
          operation: 'delete',
          entityTable: 'presence_schedules',
          recordId: override.id,
          payload: jsonEncode({'id': override.id}),
          createdAt: now,
        ),
      );
    }
  }

  @override
  Future<bool> hasWeeklyOverrides(String weekKey) =>
      _datasource.hasWeeklyOverrides(weekKey);
}
