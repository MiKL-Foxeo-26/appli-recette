import 'dart:math';

import 'package:appli_recette/core/auth/initial_sync_service.dart';
import 'package:appli_recette/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

// ── Exceptions ────────────────────────────────────────────────────────────────

class HouseholdNotFoundException implements Exception {
  const HouseholdNotFoundException();
  @override
  String toString() => 'Code foyer introuvable';
}

class InvalidCodeFormatException implements Exception {
  const InvalidCodeFormatException();
  @override
  String toString() => 'Format de code invalide (6 chiffres requis)';
}

// ── Service ───────────────────────────────────────────────────────────────────

/// Service responsable de la création/jointure d'un foyer via Code Foyer 6 chiffres.
///
/// Utilise l'authentification anonyme Supabase — aucun email/mot de passe.
/// Le household_id est persisté localement dans SharedPreferences.
class HouseholdAuthService {
  HouseholdAuthService(this._db);

  final AppDatabase _db;

  static const _keyHouseholdId = 'household_id';

  SupabaseClient get _client => Supabase.instance.client;

  /// Crée un nouveau foyer.
  ///
  /// 1. S'authentifie anonymement.
  /// 2. Génère un code unique à 6 chiffres.
  /// 3. Insère dans `households` + `household_auth_devices`.
  /// 4. Stocke le household_id localement.
  /// 5. Met à jour les enregistrements locaux existants.
  ///
  /// Retourne le code à 6 chiffres à afficher à l'utilisateur.
  Future<String> createHousehold() async {
    await _client.auth.signInAnonymously();
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Échec de l\'authentification anonyme');
    }
    final userId = user.id;

    final code = await _generateUniqueCode();
    final householdId = const Uuid().v4();

    await _client.from('households').insert({
      'id': householdId,
      'code': code,
    });

    await _client.from('household_auth_devices').insert({
      'household_id': householdId,
      'auth_user_id': userId,
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHouseholdId, householdId);

    await linkLocalDataToHousehold(householdId);

    return code;
  }

  /// Rejoint un foyer existant via son code à 6 chiffres.
  ///
  /// Lève [InvalidCodeFormatException] si le format est incorrect.
  /// Lève [HouseholdNotFoundException] si le code est inconnu de Supabase.
  Future<void> joinHousehold(String code) async {
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      throw const InvalidCodeFormatException();
    }

    await _client.auth.signInAnonymously();
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Échec de l\'authentification anonyme');
    }
    final userId = user.id;

    final result = await _client
        .from('households')
        .select('id')
        .eq('code', code)
        .maybeSingle();
    if (result == null) throw const HouseholdNotFoundException();

    final householdId = result['id'] as String;

    await _client.from('household_auth_devices').insert({
      'household_id': householdId,
      'auth_user_id': userId,
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHouseholdId, householdId);

    await InitialSyncService(_db).syncFromSupabase(householdId);
  }

  /// Retourne le household_id stocké localement, ou null si non défini.
  Future<String?> getCurrentHouseholdId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyHouseholdId);
  }

  /// Retourne true si une session Supabase est active.
  Future<bool> isAuthenticated() async {
    return _client.auth.currentSession != null;
  }

  /// Restaure la session Supabase persistée au démarrage.
  ///
  /// Supabase Flutter persiste automatiquement le JWT — cette méthode
  /// s'assure que la session est bien disponible avant le premier accès réseau.
  Future<void> restoreSession() async {
    // Supabase Flutter restaure automatiquement la session depuis le stockage
    // local lors de l'initialisation. Aucune action explicite requise.
  }

  /// Met à jour tous les enregistrements locaux drift dont le householdId
  /// est null pour y affecter le foyer nouvellement créé.
  Future<void> linkLocalDataToHousehold(String householdId) async {
    await (_db.update(_db.recipes)
          ..where((r) => r.householdId.isNull()))
        .write(RecipesCompanion(householdId: Value(householdId)));

    await (_db.update(_db.members)
          ..where((m) => m.householdId.isNull()))
        .write(MembersCompanion(householdId: Value(householdId)));

    await (_db.update(_db.weeklyMenus)
          ..where((m) => m.householdId.isNull()))
        .write(WeeklyMenusCompanion(householdId: Value(householdId)));
  }

  // ── Private ────────────────────────────────────────────────────────────────

  Future<String> _generateUniqueCode() async {
    final random = Random.secure();
    for (var i = 0; i < 3; i++) {
      final code = (random.nextInt(900000) + 100000).toString();
      final existing = await _client
          .from('households')
          .select('id')
          .eq('code', code)
          .maybeSingle();
      if (existing == null) return code;
    }
    throw Exception('Impossible de générer un code unique après 3 essais');
  }
}
