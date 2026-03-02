import 'package:appli_recette/core/auth/auth_service.dart';
import 'package:appli_recette/core/auth/auth_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider du service d'authentification email/mot de passe.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Utilisateur Supabase courant (null = non authentifié).
///
/// Dérivé de [authStateProvider] pour garantir la réactivité aux changements.
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value?.session?.user;
});

/// Indicateur d'authentification.
///
/// `true` si l'utilisateur est connecté et a une session valide.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
