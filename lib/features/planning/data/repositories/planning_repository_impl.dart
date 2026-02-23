import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/features/planning/data/datasources/presence_local_datasource.dart';
import 'package:appli_recette/features/planning/domain/repositories/planning_repository.dart';
import 'package:rxdart/rxdart.dart';

/// Implémentation concrète du PlanningRepository.
/// Délègue au datasource local (drift).
class PlanningRepositoryImpl implements PlanningRepository {
  PlanningRepositoryImpl(this._datasource);

  final PresenceLocalDatasource _datasource;

  @override
  Stream<List<PresenceSchedule>> watchDefaultPresences() =>
      _datasource.watchDefaultSchedule();

  @override
  Future<void> togglePresence(
    String memberId,
    int dayOfWeek,
    String mealSlot,
  ) =>
      _datasource.togglePresence(memberId, dayOfWeek, mealSlot);

  @override
  Future<void> initializeDefaultForMember(String memberId) =>
      _datasource.initDefaultScheduleForMember(memberId);

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
        // Indexer les overrides par clé (memberId, dayOfWeek, mealSlot)
        final overrideMap = <String, PresenceSchedule>{};
        for (final o in overrides) {
          overrideMap['${o.memberId}|${o.dayOfWeek}|${o.mealSlot}'] = o;
        }

        // Fusionner : override prioritaire, sinon default
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
  ) =>
      _datasource.toggleWeeklyPresence(weekKey, memberId, dayOfWeek, mealSlot);

  @override
  Future<void> resetWeekToDefault(String weekKey) =>
      _datasource.deleteWeeklyOverrides(weekKey);

  @override
  Future<bool> hasWeeklyOverrides(String weekKey) =>
      _datasource.hasWeeklyOverrides(weekKey);
}
