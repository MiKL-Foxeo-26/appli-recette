import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stream des événements d'authentification Supabase.
///
/// Émet un [AuthState] à chaque changement : connexion, déconnexion,
/// renouvellement de token, etc. Retourne un stream vide si Supabase
/// n'est pas initialisé (cas des tests unitaires).
final authStateProvider = StreamProvider<AuthState>((ref) {
  try {
    return Supabase.instance.client.auth.onAuthStateChange;
  } catch (_) {
    // Supabase non initialisé (tests unitaires) — stream vide
    return const Stream.empty();
  }
});
