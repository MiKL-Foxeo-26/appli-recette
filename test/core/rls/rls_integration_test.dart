/// Tests d'intégration RLS — Story 8.4 (AC 1, 3, 7)
///
/// ⚠️ Ces tests nécessitent un projet Supabase DEV réel avec deux comptes test.
/// Ils NE peuvent PAS être mockés car ils valident les policies SQL côté serveur.
///
/// Variables d'environnement requises :
///   SUPABASE_TEST_URL       — URL du projet Supabase de dev
///   SUPABASE_TEST_ANON_KEY  — Anon key du projet Supabase de dev
///   TEST_USER_A_EMAIL       — Email du user A (foyer A)
///   TEST_USER_A_PASSWORD    — Mot de passe du user A
///   TEST_USER_B_EMAIL       — Email du user B (foyer B)
///   TEST_USER_B_PASSWORD    — Mot de passe du user B
///
/// Lancer : flutter test --tags integration
@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ignore_for_file: avoid_print

void main() {
  late SupabaseClient clientA;
  late SupabaseClient clientB;

  final supabaseUrl =
      const String.fromEnvironment('SUPABASE_TEST_URL', defaultValue: '');
  final supabaseAnonKey =
      const String.fromEnvironment('SUPABASE_TEST_ANON_KEY', defaultValue: '');
  final userAEmail =
      const String.fromEnvironment('TEST_USER_A_EMAIL', defaultValue: '');
  final userAPassword =
      const String.fromEnvironment('TEST_USER_A_PASSWORD', defaultValue: '');
  final userBEmail =
      const String.fromEnvironment('TEST_USER_B_EMAIL', defaultValue: '');
  final userBPassword =
      const String.fromEnvironment('TEST_USER_B_PASSWORD', defaultValue: '');

  setUpAll(() async {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      print(
        'SKIP: Variables SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY non définies.',
      );
      return;
    }

    // Deux clients distincts → deux sessions indépendantes
    clientA = SupabaseClient(supabaseUrl, supabaseAnonKey);
    clientB = SupabaseClient(supabaseUrl, supabaseAnonKey);

    await clientA.auth.signInWithPassword(
      email: userAEmail,
      password: userAPassword,
    );
    await clientB.auth.signInWithPassword(
      email: userBEmail,
      password: userBPassword,
    );
  });

  tearDownAll(() async {
    if (supabaseUrl.isEmpty) return;
    await clientA.auth.signOut();
    await clientB.auth.signOut();
    clientA.dispose();
    clientB.dispose();
  });

  group('RLS — isolation par foyer (AC 1)', () {
    late String householdAId;
    late String householdBId;
    late String recipeAId;
    late String recipeBId;

    setUp(() async {
      if (supabaseUrl.isEmpty) return;

      // Créer foyer A
      final foA = await clientA.from('households').insert({
        'name': 'Foyer Test A',
        'created_by': clientA.auth.currentUser!.id,
      }).select().single();
      householdAId = foA['id'] as String;

      // User A rejoint son foyer
      await clientA.from('household_members').insert({
        'household_id': householdAId,
        'user_id': clientA.auth.currentUser!.id,
        'role': 'owner',
      });

      // Créer foyer B
      final foB = await clientB.from('households').insert({
        'name': 'Foyer Test B',
        'created_by': clientB.auth.currentUser!.id,
      }).select().single();
      householdBId = foB['id'] as String;

      // User B rejoint son foyer
      await clientB.from('household_members').insert({
        'household_id': householdBId,
        'user_id': clientB.auth.currentUser!.id,
        'role': 'owner',
      });

      // Créer recette A dans foyer A
      recipeAId = '${DateTime.now().millisecondsSinceEpoch}-a';
      await clientA.from('recipes').insert({
        'id': recipeAId,
        'name': 'Recette de A',
        'meal_type': 'lunch',
        'prep_time_minutes': 10,
        'household_id': householdAId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Créer recette B dans foyer B
      recipeBId = '${DateTime.now().millisecondsSinceEpoch}-b';
      await clientB.from('recipes').insert({
        'id': recipeBId,
        'name': 'Recette de B',
        'meal_type': 'dinner',
        'prep_time_minutes': 15,
        'household_id': householdBId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    });

    tearDown(() async {
      if (supabaseUrl.isEmpty) return;
      // Nettoyage — CASCADE supprimera household_members + recettes
      await clientA
          .from('households')
          .delete()
          .eq('id', householdAId);
      await clientB
          .from('households')
          .delete()
          .eq('id', householdBId);
    });

    test('User A ne voit PAS la recette du foyer B (AC 1)', () async {
      if (supabaseUrl.isEmpty) return;

      final resultA =
          await clientA.from('recipes').select().eq('id', recipeBId);
      expect(
        resultA,
        isEmpty,
        reason: 'User A ne doit pas voir la recette du foyer B',
      );
    });

    test('User B ne voit PAS la recette du foyer A (AC 1)', () async {
      if (supabaseUrl.isEmpty) return;

      final resultB =
          await clientB.from('recipes').select().eq('id', recipeAId);
      expect(
        resultB,
        isEmpty,
        reason: 'User B ne doit pas voir la recette du foyer A',
      );
    });

    test('User A voit SA propre recette (AC 7)', () async {
      if (supabaseUrl.isEmpty) return;

      final resultA =
          await clientA.from('recipes').select().eq('id', recipeAId);
      expect(resultA, hasLength(1));
      expect(resultA.first['name'], equals('Recette de A'));
    });

    test('User B voit SA propre recette (AC 7)', () async {
      if (supabaseUrl.isEmpty) return;

      final resultB =
          await clientB.from('recipes').select().eq('id', recipeBId);
      expect(resultB, hasLength(1));
      expect(resultB.first['name'], equals('Recette de B'));
    });

    test('SELECT * ne retourne que les recettes du foyer courant (AC 1)', () async {
      if (supabaseUrl.isEmpty) return;

      final allFromA = await clientA.from('recipes').select();
      final ids = (allFromA as List).map((r) => r['id'] as String).toList();

      expect(ids, contains(recipeAId));
      expect(ids, isNot(contains(recipeBId)));
    });
  });

  group('RLS — utilisateur non authentifié bloqué (AC 3)', () {
    test('SELECT recettes sans auth → 0 lignes (via anon key sans session)', () async {
      if (supabaseUrl.isEmpty) return;

      // Client sans auth
      final anonClient = SupabaseClient(supabaseUrl, supabaseAnonKey);
      final result = await anonClient.from('recipes').select();
      expect(result, isEmpty, reason: 'Aucune donnée sans auth');
      anonClient.dispose();
    });
  });
}
