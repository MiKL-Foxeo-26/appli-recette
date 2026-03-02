// Tests widget pour SettingsScreen (Story 8.3).
//
// Couvre : affichage email (AC-7), affichage code foyer (AC-1),
// copie code → Snackbar (AC-5), dialog déconnexion (AC-8).

import 'package:appli_recette/core/auth/auth_providers.dart';
import 'package:appli_recette/core/auth/auth_service.dart';
import 'package:appli_recette/core/household/invitation_service.dart';
import 'package:appli_recette/core/household/household_providers.dart';
import 'package:appli_recette/core/theme/app_theme.dart';
import 'package:appli_recette/features/settings/presentation/providers/settings_provider.dart';
import 'package:appli_recette/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockAuthService extends Mock implements AuthService {}

class MockInvitationService extends Mock implements InvitationService {}

class MockUser extends Mock implements User {
  MockUser({required this.mockEmail});
  final String mockEmail;

  @override
  String? get email => mockEmail;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _buildScreen({
  required AuthService authService,
  required InvitationService invitationService,
  User? user,
  Map<String, dynamic>? householdDetails,
  String? householdId,
}) {
  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(authService),
      invitationServiceProvider.overrideWithValue(invitationService),
      currentUserProvider.overrideWithValue(user),
      currentHouseholdIdProvider.overrideWith((_) async => householdId),
      householdDetailsProvider.overrideWith((_) async => householdDetails),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const SettingsScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthService mockAuthService;
  late MockInvitationService mockInvitationService;
  late MockUser mockUser;

  setUp(() {
    mockAuthService = MockAuthService();
    mockInvitationService = MockInvitationService();
    mockUser = MockUser(mockEmail: 'test@example.com');
    registerFallbackValue('');
  });

  // ── Email utilisateur (AC-7) ─────────────────────────────────────────────────

  group('Affichage email (AC-7)', () {
    testWidgets('affiche l\'email de l\'utilisateur connecté', (tester) async {
      await tester.pumpWidget(_buildScreen(
        authService: mockAuthService,
        invitationService: mockInvitationService,
        user: mockUser,
        householdDetails: {'name': 'Mon Foyer', 'code': '123456'},
        householdId: 'house-1',
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('affiche — si utilisateur null', (tester) async {
      await tester.pumpWidget(_buildScreen(
        authService: mockAuthService,
        invitationService: mockInvitationService,
        user: null,
        householdDetails: null,
        householdId: null,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('—'), findsWidgets);
    });
  });

  // ── Code foyer (AC-1) ────────────────────────────────────────────────────────

  group('Affichage code foyer (AC-1)', () {
    testWidgets('affiche le code 6 chiffres du foyer', (tester) async {
      await tester.pumpWidget(_buildScreen(
        authService: mockAuthService,
        invitationService: mockInvitationService,
        user: mockUser,
        householdDetails: {'name': 'Famille Test', 'code': '654321'},
        householdId: 'house-1',
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('654321'), findsOneWidget);
    });

    testWidgets('affiche le nom du foyer', (tester) async {
      await tester.pumpWidget(_buildScreen(
        authService: mockAuthService,
        invitationService: mockInvitationService,
        user: mockUser,
        householdDetails: {'name': 'Famille Test', 'code': '654321'},
        householdId: 'house-1',
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Famille Test'), findsOneWidget);
    });
  });

  // ── Bouton copier (AC-5) ─────────────────────────────────────────────────────

  group('Copier le code (AC-5)', () {
    testWidgets('affiche le bouton Copier le code', (tester) async {
      await tester.pumpWidget(_buildScreen(
        authService: mockAuthService,
        invitationService: mockInvitationService,
        user: mockUser,
        householdDetails: {'name': 'Mon Foyer', 'code': '123456'},
        householdId: 'house-1',
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Copier le code'), findsOneWidget);
    });

    testWidgets('appui sur Copier affiche un Snackbar', (tester) async {
      await tester.pumpWidget(_buildScreen(
        authService: mockAuthService,
        invitationService: mockInvitationService,
        user: mockUser,
        householdDetails: {'name': 'Mon Foyer', 'code': '123456'},
        householdId: 'house-1',
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Copier le code'));
      await tester.pump();

      expect(find.text('Code copié !'), findsOneWidget);
    });
  });

  // ── Déconnexion (AC-8) ───────────────────────────────────────────────────────

  group('Déconnexion (AC-8)', () {
    testWidgets('affiche le bouton Se déconnecter (hors viewport OK)', (tester) async {
      await tester.pumpWidget(_buildScreen(
        authService: mockAuthService,
        invitationService: mockInvitationService,
        user: mockUser,
        householdDetails: {'name': 'Mon Foyer', 'code': '123456'},
        householdId: 'house-1',
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Vérifie l'existence même si hors viewport (ListView = lazy)
      final btn = find.text('Se déconnecter', skipOffstage: false);
      expect(btn, findsOneWidget);
    });

    testWidgets('tap déconnexion → dialog de confirmation', (tester) async {
      // Agrandir la fenêtre pour que le bouton soit dans le viewport
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildScreen(
        authService: mockAuthService,
        invitationService: mockInvitationService,
        user: mockUser,
        householdDetails: {'name': 'Mon Foyer', 'code': '123456'},
        householdId: 'house-1',
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Se déconnecter'));
      await tester.pumpAndSettle();

      // Le dialog s'affiche avec les deux boutons
      expect(find.text('Se déconnecter ?'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
    });

    testWidgets('tap Annuler → dialog fermé sans appel signOut', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildScreen(
        authService: mockAuthService,
        invitationService: mockInvitationService,
        user: mockUser,
        householdDetails: {'name': 'Mon Foyer', 'code': '123456'},
        householdId: 'house-1',
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Se déconnecter'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      verifyNever(() => mockAuthService.signOut());
      expect(find.text('Se déconnecter ?'), findsNothing);
    });
  });

  // ── Partage invitation (AC-2) ────────────────────────────────────────────────

  group('Partage invitation (AC-2)', () {
    testWidgets('affiche le bouton Partager le lien d\'invitation', (tester) async {
      await tester.pumpWidget(_buildScreen(
        authService: mockAuthService,
        invitationService: mockInvitationService,
        user: mockUser,
        householdDetails: {'name': 'Mon Foyer', 'code': '123456'},
        householdId: 'house-1',
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("Partager le lien d'invitation"), findsOneWidget);
    });
  });
}
