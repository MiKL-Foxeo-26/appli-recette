import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/core/theme/app_colors.dart';
import 'package:appli_recette/features/household/data/models/rating_value.dart';
import 'package:appli_recette/features/household/presentation/providers/household_provider.dart';
import 'package:appli_recette/features/household/presentation/widgets/member_rating_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom sheet de notation immédiate après la création d'une recette.
///
/// Affiche chaque membre du foyer avec des chips Aimé / Neutre / Pas aimé.
/// Les notations sont persistées en drift seulement au clic sur "Enregistrer".
/// Le bouton "Passer" ferme le sheet sans créer de meal_ratings.
class RatingAfterCreationSheet extends ConsumerStatefulWidget {
  const RatingAfterCreationSheet({
    required this.members,
    required this.recipeId,
    super.key,
  });

  final List<Member> members;
  final String recipeId;

  @override
  ConsumerState<RatingAfterCreationSheet> createState() =>
      _RatingAfterCreationSheetState();
}

class _RatingAfterCreationSheetState
    extends ConsumerState<RatingAfterCreationSheet> {
  /// État local : memberId → notation sélectionnée (null = non notée)
  final Map<String, RatingValue?> _ratings = {};

  bool _isSaving = false;

  Future<void> _saveRatings() async {
    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(householdNotifierProvider.notifier);
      for (final entry in _ratings.entries) {
        if (entry.value != null) {
          await notifier.upsertRating(
            memberId: entry.key,
            recipeId: widget.recipeId,
            rating: entry.value!,
          );
        }
      }
      if (mounted) Navigator.of(context).pop();
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de l'enregistrement : $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle visuel
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Titre
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Comment a-t-on aimé ?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Note dès maintenant pour un menu plus adapté',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Liste des membres (scrollable si > 3)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: widget.members.map((member) {
                    return MemberRatingRow(
                      member: member,
                      currentRating: _ratings[member.id],
                      onRatingChanged: (rating) {
                        setState(() => _ratings[member.id] = rating);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Séparateur
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Boutons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Passer
                  Expanded(
                    child: TextButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                      child: const Text('Passer'),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Enregistrer
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSaving ? null : _saveRatings,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Enregistrer'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
