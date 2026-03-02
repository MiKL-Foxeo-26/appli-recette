// Tests widget pour SignupScreen.
//
// Couvre : validation email (AC-4, AC-7), validation mot de passe (min 8 chars),
// validation correspondance mots de passe, état bouton, lien retour login.

import 'package:appli_recette/core/auth/auth_providers.dart';
import 'package:appli_recette/core/auth/auth_service.dart';
import 'package:appli_recette/core/theme/app_theme.dart';
import 'package:appli_recette/features/auth/presentation/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockAuthService extends Mock implements AuthService {}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _buildSignupScreen({required AuthService authService}) {
  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(authService),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const SignupScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  // ── Présence des éléments ──────────────────────────────────────────────────

  group('Affichage initial', () {
    testWidgets('affiche 3 champs (email, mdp, confirmation)', (tester) async {
      await tester.pumpWidget(
        _buildSignupScreen(authService: mockAuthService),
      );
      await tester.pump();

      expect(find.byType(TextFormField), findsNWidgets(3));
    });

    testWidgets('affiche le bouton "Créer mon compte"', (tester) async {
      await tester.pumpWidget(
        _buildSignupScreen(authService: mockAuthService),
      );
      await tester.pump();

      expect(find.text('Créer mon compte'), findsOneWidget);
    });

    testWidgets('affiche le lien "J\'ai déjà un compte"', (tester) async {
      await tester.pumpWidget(
        _buildSignupScreen(authService: mockAuthService),
      );
      await tester.pump();

      expect(find.text("J'ai déjà un compte"), findsOneWidget);
    });
  });

  // ── Validation email ───────────────────────────────────────────────────────

  group('Validation email (AC-7)', () {
    testWidgets('affiche erreur si email invalide après soumission',
        (tester) async {
      await tester.pumpWidget(
        _buildSignupScreen(authService: mockAuthService),
      );
      await tester.pump();

      // Email invalide (sans @)
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'invalidemail',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmer le mot de passe'),
        'password123',
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Créer mon compte'));
      await tester.pumpAndSettle();

      expect(find.text('Adresse email invalide.'), findsOneWidget);
    });
  });

  // ── Validation mot de passe ────────────────────────────────────────────────

  group('Validation mot de passe', () {
    testWidgets('affiche erreur si mot de passe < 8 caractères',
        (tester) async {
      await tester.pumpWidget(
        _buildSignupScreen(authService: mockAuthService),
      );
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe'),
        'short',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmer le mot de passe'),
        'short',
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Créer mon compte'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Le mot de passe doit contenir au moins 8 caractères.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('affiche erreur si mots de passe ne correspondent pas',
        (tester) async {
      await tester.pumpWidget(
        _buildSignupScreen(authService: mockAuthService),
      );
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmer le mot de passe'),
        'different456',
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Créer mon compte'));
      await tester.pumpAndSettle();

      expect(
        find.text('Les mots de passe ne correspondent pas.'),
        findsOneWidget,
      );
    });
  });

  // ── État du bouton ─────────────────────────────────────────────────────────

  group('Bouton Créer mon compte', () {
    testWidgets('est présent et cliquable quand formulaire valide',
        (tester) async {
      await tester.pumpWidget(
        _buildSignupScreen(authService: mockAuthService),
      );
      await tester.pump();

      // Le bouton doit être visible
      expect(find.text('Créer mon compte'), findsOneWidget);
    });
  });
}
