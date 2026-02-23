import 'package:appli_recette/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Card warning affichée quand la génération est incomplète.
///
/// Propose 3 options : Élargir les filtres, Compléter manuellement, Laisser vides.
/// N'est pas affichée si [emptySlotCount] == 0.
class IncompleteGenerationCard extends StatelessWidget {
  const IncompleteGenerationCard({
    super.key,
    required this.emptySlotCount,
    this.onExpandFilters,
    this.onCompleteManually,
    this.onLeaveEmpty,
  });

  /// Nombre de créneaux non remplis. Si 0, la card n'est pas affichée.
  final int emptySlotCount;

  final VoidCallback? onExpandFilters;
  final VoidCallback? onCompleteManually;
  final VoidCallback? onLeaveEmpty;

  @override
  Widget build(BuildContext context) {
    if (emptySlotCount == 0) return const SizedBox.shrink();

    final creneauText = emptySlotCount == 1
        ? '1 créneau n\'a pas pu être rempli'
        : '$emptySlotCount créneaux n\'ont pas pu être remplis';

    return Card(
      color: const Color(0xFFFFF3E0),
      elevation: 0,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête ──
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    creneauText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Pas assez de recettes compatibles avec tes préférences.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            ),
            const SizedBox(height: 12),
            // ── Options ──
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('Élargir les filtres'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  onPressed: onExpandFilters,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Compléter manuellement'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  onPressed: onCompleteManually,
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  onPressed: onLeaveEmpty,
                  child: const Text('Laisser les créneaux vides'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
