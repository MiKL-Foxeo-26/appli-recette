import 'package:shared_preferences/shared_preferences.dart';

/// Service de gestion de l'état d'onboarding.
///
/// Persiste le flag [_kKey] dans SharedPreferences (stockage device-local).
/// N'a pas besoin de synchronisation Supabase — l'onboarding est par appareil.
class OnboardingService {
  static const _kKey = 'onboarding_complete';

  /// Retourne true si l'onboarding a déjà été complété sur cet appareil.
  Future<bool> isComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kKey) ?? false;
  }

  /// Marque l'onboarding comme complété.
  Future<void> setComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kKey, true);
  }

  /// Réinitialise le flag (utile pour les tests).
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKey);
  }
}
