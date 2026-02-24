import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/core/database/database_provider.dart';
import 'package:appli_recette/features/onboarding/domain/onboarding_service.dart';
import 'package:appli_recette/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:appli_recette/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

AppDatabase _buildDb() => AppDatabase.forTesting(NativeDatabase.memory());

Widget _buildApp({required AppDatabase db}) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
    ],
    child: const MaterialApp(home: OnboardingScreen()),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OnboardingScreen', () {
    testWidgets('affiche l\'étape 1/3 au lancement', (tester) async {
      final db = _buildDb();
      await tester.pumpWidget(_buildApp(db: db));
      await tester.pumpAndSettle();

      expect(find.text('Étape 1/3 — Foyer'), findsOneWidget);
      expect(find.text('Qui fait partie du foyer ?'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      await db.close();
    });

    testWidgets('bouton Suivant désactivé si aucun membre (étape 1)',
        (tester) async {
      final db = _buildDb();
      await tester.pumpWidget(_buildApp(db: db));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Suivant →'),
      );
      expect(button.onPressed, isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      await db.close();
    });

    testWidgets(
        'bouton Suivant activé après ajout d\'un membre (étape 1)',
        (tester) async {
      final db = _buildDb();
      await tester.pumpWidget(_buildApp(db: db));
      await tester.pumpAndSettle();

      // Remplir le prénom
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Prénom *'),
        'Léa',
      );

      // Taper Ajouter
      await tester.tap(find.widgetWithText(OutlinedButton, 'Ajouter au foyer'));
      await tester.pumpAndSettle();

      // Le bouton Suivant doit être activé
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Suivant →'),
      );
      expect(button.onPressed, isNotNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      await db.close();
    });

    testWidgets('indicateur de progression visible', (tester) async {
      final db = _buildDb();
      await tester.pumpWidget(_buildApp(db: db));
      await tester.pumpAndSettle();

      // Les 3 dots d'indicateur sont présents via AnimatedContainer
      expect(find.byType(AnimatedContainer), findsNWidgets(3));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      await db.close();
    });
  });

  group('OnboardingService', () {
    test('isComplete retourne false par défaut', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OnboardingService();
      final result = await service.isComplete();
      expect(result, isFalse);
    });

    test('setComplete → isComplete retourne true', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OnboardingService();
      await service.setComplete();
      final result = await service.isComplete();
      expect(result, isTrue);
    });

    test('reset → isComplete retourne false', () async {
      SharedPreferences.setMockInitialValues({'onboarding_complete': true});
      final service = OnboardingService();
      await service.reset();
      final result = await service.isComplete();
      expect(result, isFalse);
    });
  });
}
