import 'package:appli_recette/core/household/household_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Retourne les détails du foyer courant (`name`, `code`) depuis Supabase.
///
/// Requiert [currentHouseholdIdProvider] pour connaître l'ID foyer.
/// Retourne null si aucun foyer configuré ou si la requête échoue.
final householdDetailsProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final householdIdAsync = ref.watch(currentHouseholdIdProvider);
  final householdId = householdIdAsync.value;
  if (householdId == null) return null;

  final supabase = Supabase.instance.client;
  final result = await supabase
      .from('households')
      .select('name, code')
      .eq('id', householdId)
      .maybeSingle();

  return result;
});
