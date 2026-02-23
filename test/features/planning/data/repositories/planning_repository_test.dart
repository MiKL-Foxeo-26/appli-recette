import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/features/planning/data/datasources/presence_local_datasource.dart';
import 'package:appli_recette/features/planning/data/repositories/planning_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _createTestDatabase() =>
    AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late PlanningRepositoryImpl repo;

  setUp(() async {
    db = _createTestDatabase();
    await db.customStatement('PRAGMA foreign_keys = ON');
    final datasource = PresenceLocalDatasource(db);
    repo = PlanningRepositoryImpl(datasource);
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> insertMember(String name) async {
    final id = 'member-${name.hashCode}';
    final now = DateTime.now();
    await db.into(db.members).insert(
          MembersCompanion.insert(
            id: id,
            name: name,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  group('PlanningRepositoryImpl — Planning type', () {
    test(
        'initializeDefaultForMember() + watchDefaultPresences()'
        ' — 14 entrées', () async {
      final memberId = await insertMember('Test');

      await repo.initializeDefaultForMember(memberId);

      final presences = await repo.watchDefaultPresences().first;
      expect(presences.length, 14);
      expect(presences.every((p) => p.isPresent), isTrue);
    });

    test('togglePresence() bascule un créneau via le repository',
        () async {
      final memberId = await insertMember('Toggle');

      await repo.initializeDefaultForMember(memberId);
      await repo.togglePresence(memberId, 2, 'dinner');

      final presences = await repo.watchDefaultPresences().first;
      final mardiSoir = presences.firstWhere(
        (p) =>
            p.memberId == memberId &&
            p.dayOfWeek == 2 &&
            p.mealSlot == 'dinner',
      );
      expect(mardiSoir.isPresent, isFalse);
    });

    test(
        'getMembersWithDefaultSchedule() retourne uniquement'
        ' les membres initialisés', () async {
      final id1 = await insertMember('Init1');
      await insertMember('NoInit');

      await repo.initializeDefaultForMember(id1);

      final ids = await repo.getMembersWithDefaultSchedule();
      expect(ids, contains(id1));
      expect(ids.length, 1);
    });

    test(
        'watchDefaultPresences() est réactif'
        ' — émet après toggle', () async {
      final memberId = await insertMember('Reactive');

      await repo.initializeDefaultForMember(memberId);

      final firstEmission =
          await repo.watchDefaultPresences().first;
      expect(
        firstEmission.every((p) => p.isPresent),
        isTrue,
      );

      await repo.togglePresence(memberId, 5, 'lunch');

      final secondEmission =
          await repo.watchDefaultPresences().first;
      final vendrediMidi = secondEmission.firstWhere(
        (p) =>
            p.memberId == memberId &&
            p.dayOfWeek == 5 &&
            p.mealSlot == 'lunch',
      );
      expect(vendrediMidi.isPresent, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Weekly overrides (Story 4.2)
  // ---------------------------------------------------------------------------

  group('PlanningRepositoryImpl — Weekly Overrides', () {
    const weekKey = '2026-W09';

    test(
        'watchMergedPresences() retourne les présences type'
        ' quand aucun override', () async {
      final memberId = await insertMember('MergeDefault');
      await repo.initializeDefaultForMember(memberId);

      final merged =
          await repo.watchMergedPresences(weekKey).first;
      expect(merged.length, 14);
      expect(merged.every((p) => p.isPresent), isTrue);
      // Toutes sont des entrées type (weekKey == null)
      expect(merged.every((p) => p.weekKey == null), isTrue);
    });

    test(
        'watchMergedPresences() retourne l\'override quand'
        ' il existe', () async {
      final memberId = await insertMember('MergeOverride');
      await repo.initializeDefaultForMember(memberId);

      // Créer un override (inverse de true = false)
      await repo.toggleWeeklyPresence(
        weekKey,
        memberId,
        1,
        'lunch',
      );

      final merged =
          await repo.watchMergedPresences(weekKey).first;
      final lundiMidi = merged.firstWhere(
        (p) =>
            p.memberId == memberId &&
            p.dayOfWeek == 1 &&
            p.mealSlot == 'lunch',
      );
      // L'override doit remplacer la valeur type
      expect(lundiMidi.isPresent, isFalse);
      expect(lundiMidi.weekKey, weekKey);

      // Les autres doivent rester type (true)
      final autres = merged.where(
        (p) => !(p.dayOfWeek == 1 && p.mealSlot == 'lunch'),
      );
      expect(autres.every((p) => p.isPresent), isTrue);
    });

    test(
        'toggleWeeklyPresence() ne modifie pas'
        ' le planning type', () async {
      final memberId = await insertMember('TypeIsolation');
      await repo.initializeDefaultForMember(memberId);

      await repo.toggleWeeklyPresence(
        weekKey,
        memberId,
        3,
        'dinner',
      );

      // Le planning type doit être intact
      final defaults = await repo.watchDefaultPresences().first;
      final mercrediSoir = defaults.firstWhere(
        (p) =>
            p.memberId == memberId &&
            p.dayOfWeek == 3 &&
            p.mealSlot == 'dinner',
      );
      expect(mercrediSoir.isPresent, isTrue);
    });

    test(
        'resetWeekToDefault() supprime les overrides'
        ' et revient au type', () async {
      final memberId = await insertMember('Reset');
      await repo.initializeDefaultForMember(memberId);

      // Créer des overrides
      await repo.toggleWeeklyPresence(
        weekKey,
        memberId,
        1,
        'lunch',
      );
      await repo.toggleWeeklyPresence(
        weekKey,
        memberId,
        2,
        'dinner',
      );

      // Vérifier overrides présents
      expect(await repo.hasWeeklyOverrides(weekKey), isTrue);

      // Reset
      await repo.resetWeekToDefault(weekKey);

      // Plus d'overrides
      expect(await repo.hasWeeklyOverrides(weekKey), isFalse);

      // Merged revient au type
      final merged =
          await repo.watchMergedPresences(weekKey).first;
      expect(merged.every((p) => p.isPresent), isTrue);
      expect(merged.every((p) => p.weekKey == null), isTrue);
    });

    test('hasWeeklyOverrides() fonctionne correctement',
        () async {
      final memberId = await insertMember('HasCheck');
      await repo.initializeDefaultForMember(memberId);

      expect(await repo.hasWeeklyOverrides(weekKey), isFalse);

      await repo.toggleWeeklyPresence(
        weekKey,
        memberId,
        4,
        'lunch',
      );
      expect(await repo.hasWeeklyOverrides(weekKey), isTrue);

      await repo.resetWeekToDefault(weekKey);
      expect(await repo.hasWeeklyOverrides(weekKey), isFalse);
    });

    test('watchWeeklyPresences() retourne les overrides seuls',
        () async {
      final memberId = await insertMember('WeeklyOnly');
      await repo.initializeDefaultForMember(memberId);

      await repo.toggleWeeklyPresence(
        weekKey,
        memberId,
        6,
        'dinner',
      );

      final overrides =
          await repo.watchWeeklyPresences(weekKey).first;
      expect(overrides.length, 1);
      expect(overrides.first.weekKey, weekKey);
    });
  });
}
