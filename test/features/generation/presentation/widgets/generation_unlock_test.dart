import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/core/database/database_provider.dart';
import 'package:appli_recette/features/generation/presentation/screens/home_screen.dart';
import 'package:appli_recette/features/recipes/presentation/providers/recipes_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _buildDb() => AppDatabase.forTesting(NativeDatabase.memory());

/// Monte [HomeScreen] avec un override sur [recipeCountProvider].
/// [generateMenuProvider.build()] renvoie null sans accès DB → état vide stable.
Widget _buildHome({required AppDatabase db, int recipeCount = 0}) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      recipeCountProvider.overrideWith((ref) => recipeCount),
    ],
    child: const MaterialApp(home: HomeScreen()),
  );
}

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // Tests unitaires — logique providers
  // ─────────────────────────────────────────────────────────────────────────

  group('canGenerateProvider', () {
    test('est false quand 0 recettes', () {
      final container = ProviderContainer(
        overrides: [recipeCountProvider.overrideWith((ref) => 0)],
      );
      addTearDown(container.dispose);
      expect(container.read(canGenerateProvider), isFalse);
    });

    test('est false quand 2 recettes', () {
      final container = ProviderContainer(
        overrides: [recipeCountProvider.overrideWith((ref) => 2)],
      );
      addTearDown(container.dispose);
      expect(container.read(canGenerateProvider), isFalse);
    });

    test('est true quand exactement 3 recettes', () {
      final container = ProviderContainer(
        overrides: [recipeCountProvider.overrideWith((ref) => 3)],
      );
      addTearDown(container.dispose);
      expect(container.read(canGenerateProvider), isTrue);
    });

    test('est true quand plus de 3 recettes', () {
      final container = ProviderContainer(
        overrides: [recipeCountProvider.overrideWith((ref) => 10)],
      );
      addTearDown(container.dispose);
      expect(container.read(canGenerateProvider), isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Tests widget — banner de débloquage (via HomeScreen réel)
  // ─────────────────────────────────────────────────────────────────────────

  group('Banner de débloquage de la génération', () {
    testWidgets(
        'message initial et compteur 0/3 quand 0 recettes',
        (tester) async {
      final db = _buildDb();
      await tester.pumpWidget(_buildHome(db: db, recipeCount: 0));
      await tester.pumpAndSettle();

      expect(
        find.text('Commence par ajouter 3 recettes pour générer un menu'),
        findsOneWidget,
      );
      expect(find.text('0/3'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      await db.close();
    });

    testWidgets(
        'message "Plus qu\'1 recette" et compteur 2/3 quand 2 recettes',
        (tester) async {
      final db = _buildDb();
      await tester.pumpWidget(_buildHome(db: db, recipeCount: 2));
      await tester.pumpAndSettle();

      expect(
        find.text("Plus qu'1 recette avant de pouvoir générer !"),
        findsOneWidget,
      );
      expect(find.text('2/3'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      await db.close();
    });

    testWidgets('banner masqué quand 3 recettes', (tester) async {
      final db = _buildDb();
      await tester.pumpWidget(_buildHome(db: db, recipeCount: 3));
      await tester.pumpAndSettle();

      expect(
        find.text('Commence par ajouter 3 recettes pour générer un menu'),
        findsNothing,
      );
      expect(
        find.text("Plus qu'1 recette avant de pouvoir générer !"),
        findsNothing,
      );
      // Le compteur X/3 disparaît avec le banner
      expect(find.text('3/3'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      await db.close();
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Tests widget — état du bouton Générer (AC#1 Story 6.2)
  // ─────────────────────────────────────────────────────────────────────────

  group('Bouton Générer — état actif/désactivé', () {
    testWidgets('bouton Générer désactivé quand 0 recettes', (tester) async {
      final db = _buildDb();
      await tester.pumpWidget(_buildHome(db: db, recipeCount: 0));
      await tester.pumpAndSettle();

      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Générer'),
      );
      expect(button.onPressed, isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      await db.close();
    });

    testWidgets('bouton Générer désactivé quand 2 recettes', (tester) async {
      final db = _buildDb();
      await tester.pumpWidget(_buildHome(db: db, recipeCount: 2));
      await tester.pumpAndSettle();

      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Générer'),
      );
      expect(button.onPressed, isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      await db.close();
    });

    testWidgets('bouton Générer actif quand 3 recettes', (tester) async {
      final db = _buildDb();
      await tester.pumpWidget(_buildHome(db: db, recipeCount: 3));
      await tester.pumpAndSettle();

      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Générer'),
      );
      expect(button.onPressed, isNotNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      await db.close();
    });
  });
}
