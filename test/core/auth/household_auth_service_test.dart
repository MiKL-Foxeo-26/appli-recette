// Tests unitaires pour HouseholdAuthService.
// Seules les méthodes sans appel Supabase sont testées ici :
// - Validation du format du code (joinHousehold avec format invalide)
// - getCurrentHouseholdId() via SharedPreferences mock
//
// Les tests nécessitant Supabase réel sont couverts par l'intégration (Story 7.3).

import 'package:appli_recette/core/auth/household_auth_service.dart';
import 'package:appli_recette/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

AppDatabase _createDb() => AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late HouseholdAuthService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = _createDb();
    service = HouseholdAuthService(db);
  });

  tearDown(() async => db.close());

  // ── Format validation ──────────────────────────────────────────────────────

  group('joinHousehold() — validation format (AC-4 Story 7.2)', () {
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

    // Note: un code valide (6 chiffres) tentera d'accéder à Supabase
    // et échouera dans les tests unitaires — c'est intentionnel.
    // La validation passe avant tout appel réseau.
  });

  // ── SharedPreferences ──────────────────────────────────────────────────────

  group('getCurrentHouseholdId()', () {
    test('retourne null si aucun household_id n\'est stocké', () async {
      final id = await service.getCurrentHouseholdId();
      expect(id, isNull);
    });

    test('retourne la valeur si household_id est stocké', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('household_id', 'test-household-uuid');

      final id = await service.getCurrentHouseholdId();
      expect(id, 'test-household-uuid');
    });
  });

  // ── restoreSession ─────────────────────────────────────────────────────────

  group('restoreSession()', () {
    test('ne lève pas d\'exception', () async {
      await expectLater(service.restoreSession(), completes);
    });
  });

  // ── Exception messages ─────────────────────────────────────────────────────

  group('Exceptions — toString()', () {
    test('HouseholdNotFoundException', () {
      expect(
        const HouseholdNotFoundException().toString(),
        'Code foyer introuvable',
      );
    });

    test('InvalidCodeFormatException', () {
      expect(
        const InvalidCodeFormatException().toString(),
        'Format de code invalide (6 chiffres requis)',
      );
    });
  });
}
