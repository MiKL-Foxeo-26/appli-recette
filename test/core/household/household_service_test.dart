// Tests unitaires pour HouseholdService (Story 8.2).
//
// Périmètre :
// - Validation du format du code (joinHousehold)
// - getCurrentHouseholdId() via SharedPreferences
// - Exceptions toString()
//
// Les appels Supabase (createHousehold, joinHousehold réseau) ne sont pas
// testés ici car ils requièrent un client Supabase initialisé.
// Ces flows sont couverts manuellement en intégration.

import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/core/household/household_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

AppDatabase _createDb() => AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = _createDb();
  });

  tearDown(() async => db.close());

  // ── Validation du format du code ────────────────────────────────────────────

  group('joinHousehold() — validation format (AC-4 Story 8.2)', () {
    // Note : on passe un SupabaseClient null — l'exception de format est levée
    // avant tout appel réseau, donc aucun crash ne se produit.
    late HouseholdService service;

    setUp(() {
      // Service sans client Supabase — les tests de validation n'en ont pas besoin
      // car InvalidCodeFormatException est levée avant l'appel réseau.
      service = HouseholdService(db);
    });

    test('lève InvalidCodeFormatException si code trop court (4 chiffres)',
        () async {
      await expectLater(
        service.joinHousehold('1234'),
        throwsA(isA<InvalidCodeFormatException>()),
      );
    });

    test('lève InvalidCodeFormatException si code trop long (7 chiffres)',
        () async {
      await expectLater(
        service.joinHousehold('1234567'),
        throwsA(isA<InvalidCodeFormatException>()),
      );
    });

    test('lève InvalidCodeFormatException si code contient des lettres',
        () async {
      await expectLater(
        service.joinHousehold('abc123'),
        throwsA(isA<InvalidCodeFormatException>()),
      );
    });

    test('lève InvalidCodeFormatException si code est vide', () async {
      await expectLater(
        service.joinHousehold(''),
        throwsA(isA<InvalidCodeFormatException>()),
      );
    });

    test('lève InvalidCodeFormatException si code a des espaces', () async {
      await expectLater(
        service.joinHousehold('12 345'),
        throwsA(isA<InvalidCodeFormatException>()),
      );
    });

    test(
        'lève InvalidCodeFormatException si code contient des caractères spéciaux',
        () async {
      await expectLater(
        service.joinHousehold('123!56'),
        throwsA(isA<InvalidCodeFormatException>()),
      );
    });
  });

  // ── SharedPreferences — getCurrentHouseholdId ────────────────────────────────

  group('getCurrentHouseholdId() (AC-3, AC-8)', () {
    late HouseholdService service;

    setUp(() {
      service = HouseholdService(db);
    });

    test('retourne null si aucun household_id n\'est stocké', () async {
      final id = await service.getCurrentHouseholdId();
      expect(id, isNull);
    });

    test('retourne la valeur si household_id est stocké', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('household_id', 'abc-123-uuid');

      final id = await service.getCurrentHouseholdId();
      expect(id, 'abc-123-uuid');
    });

    test('retourne null si la clé household_id n\'existe pas', () async {
      SharedPreferences.setMockInitialValues({'autre_cle': 'valeur'});
      final id = await service.getCurrentHouseholdId();
      expect(id, isNull);
    });
  });

  // ── Exceptions — messages ─────────────────────────────────────────────────

  group('Exceptions — toString() (AC-5)', () {
    test('HouseholdNotFoundException retourne un message humain', () {
      expect(
        const HouseholdNotFoundException().toString(),
        contains('Code invalide'),
      );
    });

    test('InvalidCodeFormatException retourne un message humain', () {
      expect(
        const InvalidCodeFormatException().toString(),
        contains('6 chiffres'),
      );
    });
  });
}
