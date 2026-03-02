// Tests widget pour HouseholdSetupScreen (Story 8.2).
//
// Couvre : affichage initial (AC-1), navigation vers modes (AC-2, AC-4),
// validation du champ code (AC-4, AC-5), état bouton "Rejoindre" (AC-4).

import 'package:appli_recette/core/household/household_providers.dart';
import 'package:appli_recette/core/household/household_service.dart';
import 'package:appli_recette/core/theme/app_theme.dart';
import 'package:appli_recette/features/onboarding/presentation/screens/household_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockHouseholdService extends Mock implements HouseholdService {}

// ── Helper ────────────────────────────────────────────────────────────────────

Widget _buildScreen({required HouseholdService service}) {
  return ProviderScope(
    overrides: [
      householdServiceProvider.overrideWithValue(service),
      currentHouseholdIdProvider.overrideWith((_) async => null),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const HouseholdSetupScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHouseholdService mockService;

  setUp(() {
    mockService = MockHouseholdService();
  });

  // ── Affichage initial — mode sélection ───────────────────────────────────────

  group('Affichage initial (AC-1)', () {
    testWidgets('affiche les deux options : Créer et Rejoindre', (tester) async {
      await tester.pumpWidget(_buildScreen(service: mockService));
      await tester.pump();

      expect(find.text('Créer un foyer'), findsOneWidget);
      expect(find.text('Rejoindre un foyer'), findsOneWidget);
    });

    testWidgets('affiche le titre "Configurer votre foyer"', (tester) async {
      await tester.pumpWidget(_buildScreen(service: mockService));
      await tester.pump();

      expect(find.text('Configurer votre foyer'), findsOneWidget);
    });

    testWidgets('n\'affiche pas de champ texte en mode sélection', (tester) async {
      await tester.pumpWidget(_buildScreen(service: mockService));
      await tester.pump();

      expect(find.byType(TextField), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
    });
  });

  // ── Mode Créer ────────────────────────────────────────────────────────────────

  group('Mode Créer un foyer (AC-2)', () {
    testWidgets('tap sur "Créer un foyer" affiche le champ nom', (tester) async {
      await tester.pumpWidget(_buildScreen(service: mockService));
      await tester.pump();

      await tester.tap(find.text('Créer un foyer'));
      await tester.pump();

      expect(find.text('Créer mon foyer'), findsOneWidget);
      expect(find.text('Retour'), findsOneWidget);
    });

    testWidgets('le bouton Retour ramène au mode sélection', (tester) async {
      await tester.pumpWidget(_buildScreen(service: mockService));
      await tester.pump();

      await tester.tap(find.text('Créer un foyer'));
      await tester.pump();

      await tester.tap(find.text('Retour'));
      await tester.pump();

      expect(find.text('Créer un foyer'), findsOneWidget);
      expect(find.text('Rejoindre un foyer'), findsOneWidget);
    });
  });

  // ── Mode Rejoindre ────────────────────────────────────────────────────────────

  group('Mode Rejoindre un foyer (AC-4, AC-5)', () {
    testWidgets('tap sur "Rejoindre un foyer" affiche le champ code',
        (tester) async {
      await tester.pumpWidget(_buildScreen(service: mockService));
      await tester.pump();

      await tester.tap(find.text('Rejoindre un foyer'));
      await tester.pump();

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Code foyer (6 chiffres)'), findsOneWidget);
    });

    testWidgets('bouton "Rejoindre" désactivé si code < 6 chiffres',
        (tester) async {
      await tester.pumpWidget(_buildScreen(service: mockService));
      await tester.pump();

      await tester.tap(find.text('Rejoindre un foyer'));
      await tester.pump();

      // Saisir seulement 3 chiffres
      await tester.enterText(find.byType(TextFormField), '123');
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Rejoindre le foyer'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('bouton "Rejoindre" activé si code = 6 chiffres', (tester) async {
      await tester.pumpWidget(_buildScreen(service: mockService));
      await tester.pump();

      await tester.tap(find.text('Rejoindre un foyer'));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Rejoindre le foyer'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('le bouton Retour ramène au mode sélection', (tester) async {
      await tester.pumpWidget(_buildScreen(service: mockService));
      await tester.pump();

      await tester.tap(find.text('Rejoindre un foyer'));
      await tester.pump();

      await tester.tap(find.text('Retour'));
      await tester.pump();

      expect(find.text('Créer un foyer'), findsOneWidget);
      expect(find.text('Rejoindre un foyer'), findsOneWidget);
    });

    testWidgets('erreur HouseholdNotFoundException affiche un Snackbar',
        (tester) async {
      when(() => mockService.joinHousehold('999999'))
          .thenThrow(const HouseholdNotFoundException());

      await tester.pumpWidget(_buildScreen(service: mockService));
      await tester.pump();

      await tester.tap(find.text('Rejoindre un foyer'));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField), '999999');
      await tester.pump();

      await tester.tap(
        find.widgetWithText(FilledButton, 'Rejoindre le foyer'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Code invalide'), findsOneWidget);
    });
  });
}
