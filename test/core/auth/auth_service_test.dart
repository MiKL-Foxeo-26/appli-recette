// Tests unitaires pour AuthService.
//
// Teste les méthodes qui n'appellent pas Supabase directement :
// - currentUser / currentUserId via client mocké
// - signIn / signUp / resetPassword / signOut via client mocké
//
// Les tests d'intégration avec Supabase réel sont hors scope (connexion réseau).

import 'package:appli_recette/core/auth/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockAuthResponse extends Mock implements AuthResponse {}

class MockUser extends Mock implements User {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late AuthService service;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockClient.auth).thenReturn(mockAuth);
    service = AuthService(client: mockClient);
  });

  // ── currentUser ────────────────────────────────────────────────────────────

  group('currentUser', () {
    test('retourne null quand non authentifié', () {
      when(() => mockAuth.currentUser).thenReturn(null);
      expect(service.currentUser, isNull);
    });

    test('retourne l\'utilisateur quand authentifié', () {
      final user = MockUser();
      when(() => mockAuth.currentUser).thenReturn(user);
      expect(service.currentUser, user);
    });
  });

  // ── currentUserId ──────────────────────────────────────────────────────────

  group('currentUserId', () {
    test('retourne null quand non authentifié', () {
      when(() => mockAuth.currentUser).thenReturn(null);
      expect(service.currentUserId, isNull);
    });

    test('retourne l\'UUID quand authentifié', () {
      final user = MockUser();
      when(() => mockAuth.currentUser).thenReturn(user);
      when(() => user.id).thenReturn('user-uuid-1234');
      expect(service.currentUserId, 'user-uuid-1234');
    });
  });

  // ── signIn ─────────────────────────────────────────────────────────────────

  group('signIn()', () {
    test('appelle signInWithPassword avec email et password corrects', () async {
      final response = MockAuthResponse();
      when(
        () => mockAuth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => response);

      final result = await service.signIn('test@example.com', 'password123');

      expect(result, response);
      verify(
        () => mockAuth.signInWithPassword(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).called(1);
    });
  });

  // ── signUp ─────────────────────────────────────────────────────────────────

  group('signUp()', () {
    test('appelle signUp avec email et password corrects', () async {
      final response = MockAuthResponse();
      when(
        () => mockAuth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => response);

      final result =
          await service.signUp('new@example.com', 'strongpass123');

      expect(result, response);
      verify(
        () => mockAuth.signUp(
          email: 'new@example.com',
          password: 'strongpass123',
        ),
      ).called(1);
    });
  });

  // ── resetPassword ──────────────────────────────────────────────────────────

  group('resetPassword()', () {
    test('appelle resetPasswordForEmail avec l\'email correct', () async {
      when(
        () => mockAuth.resetPasswordForEmail(any()),
      ).thenAnswer((_) async {});

      await service.resetPassword('reset@example.com');

      verify(() => mockAuth.resetPasswordForEmail('reset@example.com'))
          .called(1);
    });
  });

  // ── signOut ────────────────────────────────────────────────────────────────

  group('signOut()', () {
    test('appelle signOut sur le client Supabase', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      await service.signOut();

      verify(() => mockAuth.signOut()).called(1);
    });
  });
}
