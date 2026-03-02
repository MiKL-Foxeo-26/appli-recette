import 'package:appli_recette/core/database/database_provider.dart';
import 'package:appli_recette/core/household/household_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du service de gestion du foyer.
final householdServiceProvider = Provider<HouseholdService>((ref) {
  final db = ref.watch(databaseProvider);
  return HouseholdService(db);
});

/// Provider du household_id courant (lu depuis SharedPreferences).
///
/// Retourne null si aucun foyer n'est configuré.
final currentHouseholdIdProvider = FutureProvider<String?>((ref) async {
  final service = ref.watch(householdServiceProvider);
  return service.getCurrentHouseholdId();
});

/// Provider indiquant si un foyer est configuré.
///
/// Dérivé de [currentHouseholdIdProvider] — true si [household_id] non null.
final hasHouseholdProvider = Provider<bool>((ref) {
  return ref.watch(currentHouseholdIdProvider).value != null;
});
