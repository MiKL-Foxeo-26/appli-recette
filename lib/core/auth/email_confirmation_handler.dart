import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Gère le retour depuis un lien de confirmation email.
///
/// Quand l'utilisateur clique sur le lien de confirmation, Supabase
/// redirige vers l'app avec un `#access_token=...` dans l'URL.
/// Cela crée une session temporaire qui n'est pas fiable sur Flutter web
/// (WASM/IndexedDB). On détecte ce cas, on déconnecte la session
/// temporaire, et on pose un flag pour que l'écran de login affiche
/// "Email confirmé, connectez-vous".
class EmailConfirmationHandler {
  static const _kEmailConfirmed = 'email_just_confirmed';

  /// À appeler après [Supabase.initialize()].
  ///
  /// Si l'URL contient un fragment `access_token` (confirmation email),
  /// on sign out la session temporaire et on pose le flag.
  static Future<void> handleIfNeeded() async {
    if (!kIsWeb) return;

    // Vérifier si l'URL contient un fragment de confirmation
    final uri = Uri.base;
    final fragment = uri.fragment;
    if (fragment.isEmpty || !fragment.contains('access_token')) return;

    // C'est un retour de confirmation email → sign out la session temp
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEmailConfirmed, true);
    await Supabase.instance.client.auth.signOut();
  }

  /// Vérifie et consomme le flag "email confirmé".
  ///
  /// Retourne `true` une seule fois après une confirmation email.
  static Future<bool> consumeConfirmationFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final confirmed = prefs.getBool(_kEmailConfirmed) ?? false;
    if (confirmed) {
      await prefs.remove(_kEmailConfirmed);
    }
    return confirmed;
  }
}
