import 'package:appli_recette/core/theme/app_colors.dart';
import 'package:appli_recette/features/household/presentation/providers/household_provider.dart';
import 'package:appli_recette/features/planning/presentation/providers/planning_provider.dart';
import 'package:appli_recette/features/planning/presentation/widgets/presence_toggle_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Étape 2 de l'onboarding : configuration du planning type.
///
/// Affiche la [PresenceToggleGrid] avec les membres créés à l'étape 1.
/// Le bouton Suivant est actif dès l'ouverture (le planning est optionnel).
class Step2PlanningScreen extends ConsumerWidget {
  const Step2PlanningScreen({
    required this.onNext,
    required this.onPrevious,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onPrevious;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final members = ref.watch(membersStreamProvider).value ?? [];
    final presences =
        ref.watch(defaultPresencesStreamProvider).value ?? [];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Qui mange à la maison ?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure qui est présent pour chaque repas de la semaine. '
            'Tu pourras modifier ça à tout moment.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Grille de présence (planning type — weekKey == null)
          Expanded(
            child: members.isEmpty
                ? Center(
                    child: Text(
                      'Aucun membre trouvé.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: PresenceToggleGrid(
                      members: members,
                      presences: presences,
                      // weekKey == null → mode planning type
                    ),
                  ),
          ),

          const SizedBox(height: 16),

          // Boutons navigation
          Row(
            children: [
              TextButton.icon(
                onPressed: onPrevious,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour'),
              ),
              const Spacer(),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: onNext,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Suivant →'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
