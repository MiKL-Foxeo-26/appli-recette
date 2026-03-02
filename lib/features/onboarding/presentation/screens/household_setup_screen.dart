import 'package:appli_recette/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Écran de création/jointure de foyer — Placeholder pour Story 8.2.
///
/// Cet écran sera implémenté complètement dans Story 8.2.
/// Pour l'instant, il indique à l'utilisateur que la fonctionnalité arrive.
class HouseholdSetupScreen extends StatelessWidget {
  const HouseholdSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.home_outlined,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Configuration du foyer',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Créez ou rejoignez un foyer pour synchroniser '
                  'vos recettes et menus.\n\n(Story 8.2 — À venir)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
