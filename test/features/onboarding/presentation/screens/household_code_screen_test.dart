// Tests widget pour HouseholdCodeScreen.
// Vérifie la logique UI : activation/désactivation du bouton,
// affichage des deux modes, sans appel Supabase réel.

import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/core/database/database_provider.dart';
import 'package:appli_recette/features/onboarding/presentation/screens/household_code_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

AppDatabase _createDb() => AppDatabase.forTesting(NativeDatabase.memory());

Widget _makeApp({
  required HouseholdCodeMode mode,
  required AppDatabase db,
  VoidCallback? onDone,
}) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
    ],
    child: MaterialApp(
      home: HouseholdCodeScreen(
        mode: mode,
        onDone: onDone ?? () {},
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = _createDb();
  });

  tearDown(() async => db.close());

  // ── Create mode ────────────────────────────────────────────────────────────

  group('HouseholdCodeScreen — mode create', () {
    testWidgets('affiche le bouton Créer mon foyer', (tester) async {
      await tester.pumpWidget(_makeApp(mode: HouseholdCodeMode.create, db: db));
      await tester.pump();

      expect(find.text('Créer mon foyer'), findsOneWidget);
    });

    testWidgets('affiche le lien Passer', (tester) async {
      await tester.pumpWidget(_makeApp(mode: HouseholdCodeMode.create, db: db));
      await tester.pump();

      expect(
        find.textContaining('Passer'),
        findsOneWidget,
      );
    });

    testWidgets('bouton Passer appelle onDone', (tester) async {
      var doneCalled = false;
      await tester.pumpWidget(
        _makeApp(
          mode: HouseholdCodeMode.create,
          db: db,
          onDone: () => doneCalled = true,
        ),
      );
      await tester.pump();

      await tester.tap(find.textContaining('Passer'));
      await tester.pump();

      expect(doneCalled, isTrue);
    });
  });

  // ── Join mode ──────────────────────────────────────────────────────────────

  group('HouseholdCodeScreen — mode join', () {
    testWidgets('affiche le champ de saisie du code', (tester) async {
      await tester.pumpWidget(_makeApp(mode: HouseholdCodeMode.join, db: db));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('bouton Rejoindre désactivé si code vide', (tester) async {
      await tester.pumpWidget(_makeApp(mode: HouseholdCodeMode.join, db: db));
      await tester.pump();

      // Le bouton "Rejoindre" doit être désactivé (pas de code)
      final button = find.widgetWithText(FilledButton, 'Rejoindre');
      expect(button, findsOneWidget);
      final filledButton = tester.widget<FilledButton>(button);
      expect(filledButton.onPressed, isNull);
    });

    testWidgets('bouton Rejoindre désactivé si code < 6 chiffres',
        (tester) async {
      await tester.pumpWidget(_makeApp(mode: HouseholdCodeMode.join, db: db));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '123');
      await tester.pump();

      final button = find.widgetWithText(FilledButton, 'Rejoindre');
      final filledButton = tester.widget<FilledButton>(button);
      expect(filledButton.onPressed, isNull);
    });

    testWidgets('bouton Rejoindre activé quand 6 chiffres saisis',
        (tester) async {
      await tester.pumpWidget(_makeApp(mode: HouseholdCodeMode.join, db: db));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();

      final button = find.widgetWithText(FilledButton, 'Rejoindre');
      final filledButton = tester.widget<FilledButton>(button);
      // Activé : onPressed n'est plus null
      expect(filledButton.onPressed, isNotNull);
    });

    testWidgets('titre affiche "Rejoindre un foyer"', (tester) async {
      await tester.pumpWidget(_makeApp(mode: HouseholdCodeMode.join, db: db));
      await tester.pump();

      // Le texte apparaît dans l'AppBar ET dans le corps du formulaire
      expect(find.text('Rejoindre un foyer'), findsAtLeastNWidgets(1));
    });
  });
}
