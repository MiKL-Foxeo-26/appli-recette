import 'package:appli_recette/core/auth/auth_state_provider.dart';
import 'package:appli_recette/core/household/household_providers.dart';
import 'package:appli_recette/core/router/app_router.dart';
import 'package:appli_recette/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider du notifier de routing — rafraîchit GoRouter quand l'auth change.
final appRouterNotifierProvider = Provider<AppRouterNotifier>((ref) {
  return AppRouterNotifier(ref);
});

/// Notifier de routing — gère les redirects selon l'état d'authentification,
/// du foyer et de l'onboarding.
///
/// Chaîne de décision :
/// 0. Password recovery → /reset-password
/// 1. Pas authentifié → /login (sauf routes publiques)
/// 2. Authentifié + pas de foyer → /household-setup
/// 3. Authentifié + foyer + onboarding pas fait → /onboarding
/// 4. Authentifié + foyer + onboarding fait → / (accueil)
class AppRouterNotifier extends ChangeNotifier {
  AppRouterNotifier(this._ref) {
    _ref.listen<AsyncValue<AuthState>>(authStateProvider, (_, next) {
      if (next.value?.event == AuthChangeEvent.passwordRecovery) {
        _isPasswordRecovery = true;
      }
      notifyListeners();
    });
    _ref.listen<AsyncValue<String?>>(currentHouseholdIdProvider, (_, __) {
      notifyListeners();
    });
    _ref.listen<AsyncValue<bool>>(onboardingNotifierProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref _ref;
  bool _isPasswordRecovery = false;

  /// Routes publiques accessibles sans authentification.
  static const _publicRoutes = [
    AppRoutes.login,
    AppRoutes.signup,
    AppRoutes.forgotPassword,
    AppRoutes.verifyEmail,
  ];

  /// Redirect principal — appelé par GoRouter à chaque navigation.
  String? redirect(BuildContext context, GoRouterState state) {
    final authAsync = _ref.read(authStateProvider);
    final currentPath = state.matchedLocation;

    if (authAsync.isLoading) return null;

    // ─── Password Recovery ────────────────────────────────────────────
    if (_isPasswordRecovery) {
      if (currentPath == AppRoutes.resetPassword) return null;
      return AppRoutes.resetPassword;
    }

    final session = Supabase.instance.client.auth.currentSession;
    final isAuthenticated = session != null;
    final isOnPublicRoute = _publicRoutes.contains(currentPath);

    // ─── Pas authentifié ───────────────────────────────────────────────
    if (!isAuthenticated) {
      if (isOnPublicRoute) return null;
      return AppRoutes.login;
    }

    // ─── Authentifié ───────────────────────────────────────────────────

    // Attendre que le foyer et l'onboarding soient chargés avant tout routing.
    // Pendant ce temps, afficher un spinner plutôt que le home vide.
    final householdAsync = _ref.read(currentHouseholdIdProvider);
    final onboardingAsync = _ref.read(onboardingNotifierProvider);

    if (householdAsync.isLoading || onboardingAsync.isLoading) {
      if (currentPath == AppRoutes.loading) return null;
      return AppRoutes.loading;
    }

    if (isOnPublicRoute || currentPath == AppRoutes.loading) {
      return _resolveAuthenticatedRoute();
    }

    if (currentPath == AppRoutes.resetPassword) {
      return _resolveAuthenticatedRoute();
    }

    if (currentPath == AppRoutes.householdSetup) {
      final hasHousehold = householdAsync.value != null;
      if (hasHousehold) return _checkOnboarding();
      return null;
    }

    if (currentPath == AppRoutes.onboarding) {
      final isComplete = onboardingAsync.value ?? false;
      if (isComplete) return AppRoutes.home;
      return null;
    }

    final hasHousehold = householdAsync.value != null;
    if (!hasHousehold) return AppRoutes.householdSetup;

    final onboardingComplete = onboardingAsync.value ?? false;
    if (!onboardingComplete) return AppRoutes.onboarding;

    return null;
  }

  /// Réinitialise le flag password recovery après changement de MDP.
  void clearPasswordRecovery() {
    _isPasswordRecovery = false;
    notifyListeners();
  }

  String? _resolveAuthenticatedRoute() {
    final hasHousehold = _ref.read(currentHouseholdIdProvider).value != null;
    if (!hasHousehold) return AppRoutes.householdSetup;
    return _checkOnboarding();
  }

  String _checkOnboarding() {
    final onboardingAsync = _ref.read(onboardingNotifierProvider);
    final isComplete = onboardingAsync.value ?? false;
    if (!isComplete) return AppRoutes.onboarding;
    return AppRoutes.home;
  }
}
