import 'package:appli_recette/core/auth/household_auth_service.dart';
import 'package:appli_recette/core/database/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du service d'authentification Code Foyer.
final householdAuthServiceProvider = Provider<HouseholdAuthService>((ref) {
  final db = ref.watch(databaseProvider);
  return HouseholdAuthService(db);
});

/// Provider du household_id courant (lu depuis SharedPreferences).
/// Retourne null si aucun foyer n'est configuré.
final currentHouseholdIdProvider = FutureProvider<String?>((ref) async {
  final service = ref.watch(householdAuthServiceProvider);
  return service.getCurrentHouseholdId();
});

/// Provider indiquant si l'utilisateur est authentifié (session Supabase active).
final isAuthenticatedProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(householdAuthServiceProvider);
  return service.isAuthenticated();
});
