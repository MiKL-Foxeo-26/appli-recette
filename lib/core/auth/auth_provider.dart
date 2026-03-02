import 'package:appli_recette/core/auth/household_auth_service.dart';
import 'package:appli_recette/core/database/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du service d'authentification Code Foyer (legacy — Story 7.2).
///
/// Conservé uniquement pour [household_code_screen.dart] (onboarding legacy).
/// Ne pas utiliser pour la nouvelle auth — voir [authServiceProvider] et
/// [household_providers.dart] (Story 8.1/8.2).
final householdAuthServiceProvider = Provider<HouseholdAuthService>((ref) {
  final db = ref.watch(databaseProvider);
  return HouseholdAuthService(db);
});
