import 'package:appli_recette/core/config/app_config.dart';
import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/core/database/database_provider.dart';
import 'package:appli_recette/core/router/app_router.dart';
import 'package:appli_recette/core/theme/app_theme.dart';
import 'package:appli_recette/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:appli_recette/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:appli_recette/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class App extends StatelessWidget {
  const App({
    required this.database,
    required this.config,
    super.key,
  });

  final AppDatabase database;
  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
      ],
      child: _AppContent(config: config),
    );
  }
}

/// Widget interne qui observe l'état de l'onboarding.
///
/// - [onboardingNotifierProvider] loading → splash screen
/// - data(false) → [OnboardingScreen] (première ouverture)
/// - data(true)  → [MaterialApp.router] (app principale)
class _AppContent extends ConsumerWidget {
  const _AppContent({required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingAsync = ref.watch(onboardingNotifierProvider);

    final mainApp = MaterialApp.router(
      title: 'Appli Recette',
      theme: AppTheme.light,
      routerConfig: appRouter,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: config.isDevelopment,
    );

    return onboardingAsync.when(
      loading: () => const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => mainApp, // En cas d'erreur, afficher l'app principale
      data: (isComplete) =>
          isComplete ? mainApp : const MaterialApp(home: OnboardingScreen()),
    );
  }
}
