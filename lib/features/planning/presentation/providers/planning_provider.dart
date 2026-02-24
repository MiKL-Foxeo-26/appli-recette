import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/core/database/database_provider.dart';
import 'package:appli_recette/core/sync/sync_provider.dart';
import 'package:appli_recette/features/planning/data/datasources/presence_local_datasource.dart';
import 'package:appli_recette/features/planning/data/repositories/planning_repository_impl.dart';
import 'package:appli_recette/features/planning/data/utils/week_utils.dart';
import 'package:appli_recette/features/planning/domain/repositories/planning_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

final presenceLocalDatasourceProvider =
    Provider<PresenceLocalDatasource>((ref) {
  final db = ref.watch(databaseProvider);
  return PresenceLocalDatasource(db);
});

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final planningRepositoryProvider = Provider<PlanningRepository>((ref) {
  final datasource = ref.watch(presenceLocalDatasourceProvider);
  final syncQueue = ref.watch(syncQueueDatasourceProvider);
  return PlanningRepositoryImpl(datasource, syncQueue);
});

// ---------------------------------------------------------------------------
// Stream providers — Planning type (Story 4.1)
// ---------------------------------------------------------------------------

/// Stream des présences type (weekKey == null).
final defaultPresencesStreamProvider =
    StreamProvider<List<PresenceSchedule>>((ref) {
  return ref.watch(planningRepositoryProvider).watchDefaultPresences();
});

// ---------------------------------------------------------------------------
// Weekly providers (Story 4.2)
// ---------------------------------------------------------------------------

/// Notifier pour la semaine sélectionnée.
class SelectedWeekKeyNotifier extends Notifier<String> {
  @override
  String build() => currentWeekKey();

  void select(String weekKey) => state = weekKey;
}

final selectedWeekKeyProvider =
    NotifierProvider<SelectedWeekKeyNotifier, String>(
  SelectedWeekKeyNotifier.new,
);

/// Stream des présences fusionnées pour une semaine donnée.
/// Override prioritaire, fallback planning type.
final mergedPresencesStreamProvider =
    StreamProvider.family<List<PresenceSchedule>, String>((ref, weekKey) {
  return ref.watch(planningRepositoryProvider).watchMergedPresences(weekKey);
});

/// Stream des overrides seuls pour une semaine donnée.
final weeklyOverridesStreamProvider =
    StreamProvider.family<List<PresenceSchedule>, String>((ref, weekKey) {
  return ref
      .watch(planningRepositoryProvider)
      .watchWeeklyPresences(weekKey);
});

/// Indique si des overrides existent pour une semaine.
final weeklyOverridesExistProvider =
    FutureProvider.family<bool, String>((ref, weekKey) {
  return ref
      .watch(planningRepositoryProvider)
      .hasWeeklyOverrides(weekKey);
});

// ---------------------------------------------------------------------------
// Notifier (actions)
// ---------------------------------------------------------------------------

/// Notifier pour les actions sur le planning de présence.
class PlanningNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Bascule la présence d'un membre pour un créneau du planning type.
  Future<void> togglePresence({
    required String memberId,
    required int dayOfWeek,
    required String mealSlot,
  }) async {
    await ref.read(planningRepositoryProvider).togglePresence(
          memberId,
          dayOfWeek,
          mealSlot,
        );
  }

  /// Bascule un override de présence pour une semaine spécifique.
  Future<void> toggleWeeklyPresence({
    required String weekKey,
    required String memberId,
    required int dayOfWeek,
    required String mealSlot,
  }) async {
    await ref.read(planningRepositoryProvider).toggleWeeklyPresence(
          weekKey,
          memberId,
          dayOfWeek,
          mealSlot,
        );
    ref.invalidate(weeklyOverridesExistProvider(weekKey));
  }

  /// Supprime tous les overrides d'une semaine (retour au planning type).
  Future<void> resetWeekToDefault({required String weekKey}) async {
    await ref
        .read(planningRepositoryProvider)
        .resetWeekToDefault(weekKey);
    ref.invalidate(weeklyOverridesExistProvider(weekKey));
  }

  /// Initialise le planning type pour un nouveau membre.
  Future<void> initializeForNewMember(String memberId) async {
    await ref
        .read(planningRepositoryProvider)
        .initializeDefaultForMember(memberId);
  }

  /// Initialise les présences pour tous les membres sans planning type.
  Future<void> initializeMissingMembers(List<Member> members) async {
    final repo = ref.read(planningRepositoryProvider);
    final existingIds = await repo.getMembersWithDefaultSchedule();
    final existingSet = existingIds.toSet();

    for (final member in members) {
      if (!existingSet.contains(member.id)) {
        await repo.initializeDefaultForMember(member.id);
      }
    }
  }
}

final planningNotifierProvider =
    AsyncNotifierProvider<PlanningNotifier, void>(PlanningNotifier.new);
