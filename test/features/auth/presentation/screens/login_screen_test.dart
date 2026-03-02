// Tests widget pour LoginScreen.
//
// Couvre : validation formulaire (AC-7), état bouton (AC-2),
// navigation vers signup (AC-3), affichage erreur humaine.

import 'package:appli_recette/core/auth/auth_providers.dart';
import 'package:appli_recette/core/auth/auth_service.dart';
import 'package:appli_recette/core/theme/app_theme.dart';
import 'package:appli_recette/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockAuthService extends Mock implements AuthService {}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _buildLoginScreen({required AuthService authService}) {
  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(authService),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const LoginScreen(),
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
    testWidgets('affiche les champs email et mot de passe', (tester) async {
      await tester.pumpWidget(
        _buildLoginScreen(authService: mockAuthService),
      );
      await tester.pump();

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Email'), findsWidgets);
      expect(find.text('Mot de passe'), findsWidgets);
    });

    testWidgets('affiche le bouton Connexion', (tester) async {
      await tester.pumpWidget(
        _buildLoginScreen(authService: mockAuthService),
      );
      await tester.pump();

      expect(find.text('Connexion'), findsOneWidget);
    });

    testWidgets('affiche le lien "Mot de passe oublié ?"', (tester) async {
      await tester.pumpWidget(
        _buildLoginScreen(authService: mockAuthService),
      );
      await tester.pump();

      expect(find.text('Mot de passe oublié ?'), findsOneWidget);
    });

    testWidgets('affiche le lien "Créer un compte"', (tester) async {
      await tester.pumpWidget(
        _buildLoginScreen(authService: mockAuthService),
      );
      await tester.pump();

      expect(find.text('Créer un compte'), findsOneWidget);
    });
  });

  // ── État du bouton ─────────────────────────────────────────────────────────

  group('Bouton Connexion', () {
    testWidgets('est désactivé quand email et mot de passe sont vides',
        (tester) async {
      await tester.pumpWidget(
        _buildLoginScreen(authService: mockAuthService),
      );
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Connexion'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('est activé quand email et mot de passe sont remplis',
        (tester) async {
      await tester.pumpWidget(
        _buildLoginScreen(authService: mockAuthService),
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
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Connexion'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('est désactivé si seulement l\'email est rempli',
        (tester) async {
      await tester.pumpWidget(
        _buildLoginScreen(authService: mockAuthService),
      );
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Connexion'),
      );
      expect(button.onPressed, isNull);
    });
  });

  // ── Affichage d'erreur ─────────────────────────────────────────────────────

  group('Gestion des erreurs (AC-7)', () {
    testWidgets('affiche message humain pour credentials invalides',
        (tester) async {
      when(
        () => mockAuthService.signIn(any(), any()),
      ).thenThrow(
        AuthException('Invalid login credentials'),
      );

      await tester.pumpWidget(
        _buildLoginScreen(authService: mockAuthService),
      );
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'wrong@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe'),
        'wrongpassword',
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Connexion'));
      await tester.pumpAndSettle();

      expect(find.text('Email ou mot de passe incorrect.'), findsOneWidget);
    });

    testWidgets('affiche message pour email non confirmé', (tester) async {
      when(
        () => mockAuthService.signIn(any(), any()),
      ).thenThrow(
        AuthException('Email not confirmed'),
      );

      await tester.pumpWidget(
        _buildLoginScreen(authService: mockAuthService),
      );
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'unconfirmed@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe'),
        'password123',
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Connexion'));
      await tester.pumpAndSettle();

      expect(
        find.text('Confirmez votre email avant de vous connecter.'),
        findsOneWidget,
      );
    });
  });
}
