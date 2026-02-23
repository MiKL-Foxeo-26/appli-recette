import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/features/planning/data/datasources/presence_local_datasource.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _createTestDatabase() =>
    AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late PresenceLocalDatasource datasource;

  setUp(() async {
    db = _createTestDatabase();
    await db.customStatement('PRAGMA foreign_keys = ON');
    datasource = PresenceLocalDatasource(db);
  });

  tearDown(() async {
    await db.close();
  });

  /// Helper : insère un membre de test et retourne son ID.
  Future<String> insertMember(String name) async {
    const uuid = 'test-member-';
    final id = '$uuid${name.hashCode}';
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

  group('PresenceLocalDatasource', () {
    test(
        'initDefaultScheduleForMember() crée 14 entrées'
        ' (7 jours x 2 repas)', () async {
      final memberId = await insertMember('MiKL');

      await datasource.initDefaultScheduleForMember(memberId);

      final presences = await datasource.watchDefaultSchedule().first;
      expect(presences.length, 14);
    });

    test(
        'initDefaultScheduleForMember() — toutes les entrées'
        ' sont isPresent = true', () async {
      final memberId = await insertMember('Partenaire');

      await datasource.initDefaultScheduleForMember(memberId);

      final presences = await datasource.watchDefaultSchedule().first;
      expect(presences.every((p) => p.isPresent), isTrue);
    });

    test(
        'initDefaultScheduleForMember() — toutes les entrées'
        ' ont weekKey = null (planning type)', () async {
      final memberId = await insertMember('Léonard');

      await datasource.initDefaultScheduleForMember(memberId);

      final presences = await datasource.watchDefaultSchedule().first;
      expect(presences.every((p) => p.weekKey == null), isTrue);
    });

    test(
        'initDefaultScheduleForMember() — couvre les 7 jours'
        ' et les 2 repas', () async {
      final memberId = await insertMember('Alizée');

      await datasource.initDefaultScheduleForMember(memberId);

      final presences = await datasource.watchDefaultSchedule().first;
      final days = presences.map((p) => p.dayOfWeek).toSet();
      final slots = presences.map((p) => p.mealSlot).toSet();
      expect(days, {1, 2, 3, 4, 5, 6, 7});
      expect(slots, {'lunch', 'dinner'});
    });

    test('watchDefaultSchedule() retourne vide sans données', () async {
      final presences = await datasource.watchDefaultSchedule().first;
      expect(presences, isEmpty);
    });

    test('togglePresence() bascule isPresent de true à false', () async {
      final memberId = await insertMember('Toggle');

      await datasource.initDefaultScheduleForMember(memberId);

      // Vérifier que lundi midi est true
      var presences = await datasource.watchDefaultSchedule().first;
      final lundiMidi = presences.firstWhere(
        (p) =>
            p.memberId == memberId &&
            p.dayOfWeek == 1 &&
            p.mealSlot == 'lunch',
      );
      expect(lundiMidi.isPresent, isTrue);

      // Toggle
      await datasource.togglePresence(memberId, 1, 'lunch');

      // Vérifier que lundi midi est maintenant false
      presences = await datasource.watchDefaultSchedule().first;
      final lundiMidiApres = presences.firstWhere(
        (p) =>
            p.memberId == memberId &&
            p.dayOfWeek == 1 &&
            p.mealSlot == 'lunch',
      );
      expect(lundiMidiApres.isPresent, isFalse);
    });

    test('togglePresence() bascule isPresent de false à true', () async {
      final memberId = await insertMember('ReToggle');

      await datasource.initDefaultScheduleForMember(memberId);

      // Toggle 2x = retour à true
      await datasource.togglePresence(memberId, 3, 'dinner');
      await datasource.togglePresence(memberId, 3, 'dinner');

      final presences = await datasource.watchDefaultSchedule().first;
      final mercrediSoir = presences.firstWhere(
        (p) =>
            p.memberId == memberId &&
            p.dayOfWeek == 3 &&
            p.mealSlot == 'dinner',
      );
      expect(mercrediSoir.isPresent, isTrue);
    });

    test(
        'togglePresence() ne modifie pas les autres'
        ' créneaux', () async {
      final memberId = await insertMember('Isolé');

      await datasource.initDefaultScheduleForMember(memberId);

      // Toggle uniquement lundi midi
      await datasource.togglePresence(memberId, 1, 'lunch');

      final presences = await datasource.watchDefaultSchedule().first;
      // Tous les autres doivent rester true
      final autresCreneaux = presences.where(
        (p) => !(p.dayOfWeek == 1 && p.mealSlot == 'lunch'),
      );
      expect(autresCreneaux.every((p) => p.isPresent), isTrue);
    });

    test(
        'getMembersWithDefaultSchedule() retourne les IDs'
        ' des membres initialisés', () async {
      final id1 = await insertMember('Membre1');
      final id2 = await insertMember('Membre2');
      await insertMember('Membre3');

      await datasource.initDefaultScheduleForMember(id1);
      await datasource.initDefaultScheduleForMember(id2);

      final ids = await datasource.getMembersWithDefaultSchedule();
      expect(ids.toSet(), {id1, id2});
    });

    test(
        'deleteSchedulesForMember() supprime toutes les'
        ' entrées type du membre', () async {
      final memberId = await insertMember('ToDelete');

      await datasource.initDefaultScheduleForMember(memberId);
      var presences = await datasource.watchDefaultSchedule().first;
      expect(presences, isNotEmpty);

      await datasource.deleteSchedulesForMember(memberId);
      presences = await datasource.watchDefaultSchedule().first;
      expect(presences, isEmpty);
    });

    test(
        'deux membres — les présences sont bien séparées'
        ' par memberId', () async {
      final id1 = await insertMember('Alpha');
      final id2 = await insertMember('Beta');

      await datasource.initDefaultScheduleForMember(id1);
      await datasource.initDefaultScheduleForMember(id2);

      final presences = await datasource.watchDefaultSchedule().first;
      expect(presences.length, 28); // 14 x 2 membres

      final member1Count =
          presences.where((p) => p.memberId == id1).length;
      final member2Count =
          presences.where((p) => p.memberId == id2).length;
      expect(member1Count, 14);
      expect(member2Count, 14);
    });
  });

  // ---------------------------------------------------------------------------
  // Weekly overrides (Story 4.2)
  // ---------------------------------------------------------------------------

  group('PresenceLocalDatasource — Weekly Overrides', () {
    const weekKey = '2026-W09';

    test(
        'toggleWeeklyPresence() crée un override'
        ' quand aucun n\'existe', () async {
      final memberId = await insertMember('WeeklyNew');
      await datasource.initDefaultScheduleForMember(memberId);

      // Le planning type a lundi midi = true
      await datasource.toggleWeeklyPresence(
        weekKey,
        memberId,
        1,
        'lunch',
      );

      // L'override doit exister avec isPresent = false (inverse du type)
      final overrides =
          await datasource.watchWeeklySchedule(weekKey).first;
      expect(overrides.length, 1);
      expect(overrides.first.isPresent, isFalse);
      expect(overrides.first.weekKey, weekKey);
    });

    test(
        'toggleWeeklyPresence() bascule un override'
        ' existant', () async {
      final memberId = await insertMember('WeeklyToggle');
      await datasource.initDefaultScheduleForMember(memberId);

      // Créer un override (false)
      await datasource.toggleWeeklyPresence(
        weekKey,
        memberId,
        2,
        'dinner',
      );
      // Toggle l'override (retour à true)
      await datasource.toggleWeeklyPresence(
        weekKey,
        memberId,
        2,
        'dinner',
      );

      final overrides =
          await datasource.watchWeeklySchedule(weekKey).first;
      final entry = overrides.firstWhere(
        (p) =>
            p.memberId == memberId &&
            p.dayOfWeek == 2 &&
            p.mealSlot == 'dinner',
      );
      expect(entry.isPresent, isTrue);
    });

    test(
        'toggleWeeklyPresence() ne modifie pas'
        ' le planning type', () async {
      final memberId = await insertMember('TypeSafe');
      await datasource.initDefaultScheduleForMember(memberId);

      // Toggle weekly override
      await datasource.toggleWeeklyPresence(
        weekKey,
        memberId,
        1,
        'lunch',
      );

      // Le planning type doit rester inchangé (true)
      final defaults =
          await datasource.watchDefaultSchedule().first;
      final lundiMidi = defaults.firstWhere(
        (p) =>
            p.memberId == memberId &&
            p.dayOfWeek == 1 &&
            p.mealSlot == 'lunch',
      );
      expect(lundiMidi.isPresent, isTrue);
    });

    test('watchWeeklySchedule() retourne vide sans overrides',
        () async {
      final presences =
          await datasource.watchWeeklySchedule(weekKey).first;
      expect(presences, isEmpty);
    });

    test('deleteWeeklyOverrides() supprime tous les overrides',
        () async {
      final memberId = await insertMember('DeleteWeekly');
      await datasource.initDefaultScheduleForMember(memberId);

      await datasource.toggleWeeklyPresence(
        weekKey,
        memberId,
        1,
        'lunch',
      );
      await datasource.toggleWeeklyPresence(
        weekKey,
        memberId,
        3,
        'dinner',
      );

      // Vérifier qu'il y a 2 overrides
      var overrides =
          await datasource.watchWeeklySchedule(weekKey).first;
      expect(overrides.length, 2);

      // Supprimer
      await datasource.deleteWeeklyOverrides(weekKey);

      overrides =
          await datasource.watchWeeklySchedule(weekKey).first;
      expect(overrides, isEmpty);
    });

    test('hasWeeklyOverrides() détecte les overrides', () async {
      final memberId = await insertMember('HasOverrides');
      await datasource.initDefaultScheduleForMember(memberId);

      expect(
        await datasource.hasWeeklyOverrides(weekKey),
        isFalse,
      );

      await datasource.toggleWeeklyPresence(
        weekKey,
        memberId,
        5,
        'lunch',
      );

      expect(
        await datasource.hasWeeklyOverrides(weekKey),
        isTrue,
      );
    });

    test(
        'les overrides d\'une semaine n\'affectent pas'
        ' une autre semaine', () async {
      final memberId = await insertMember('CrossWeek');
      await datasource.initDefaultScheduleForMember(memberId);

      const otherWeek = '2026-W10';

      await datasource.toggleWeeklyPresence(
        weekKey,
        memberId,
        1,
        'lunch',
      );

      final otherOverrides =
          await datasource.watchWeeklySchedule(otherWeek).first;
      expect(otherOverrides, isEmpty);
    });
  });
}
