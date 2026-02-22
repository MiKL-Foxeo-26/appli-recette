import 'dart:async';

import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/core/theme/app_colors.dart';
import 'package:appli_recette/core/utils/string_utils.dart' as str_utils;
import 'package:appli_recette/features/household/data/models/rating_value.dart';
import 'package:appli_recette/features/household/presentation/providers/household_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ligne de notation pour un membre, affichant 3 chips : Aimé / Neutre / Pas aimé.
///
/// **Mode direct-persist** (Story 3.2 — fiche recette) :
///   Fournir [recipeId]. Le tap enregistre immédiatement dans drift.
///
/// **Mode callback** (Story 3.3 — bottom sheet) :
///   Fournir [onRatingChanged]. Le tap notifie le parent qui gère l'état local.
class MemberRatingRow extends ConsumerWidget {
  const MemberRatingRow({
    required this.member,
    required this.currentRating,
    this.recipeId,
    this.onRatingChanged,
    super.key,
  }) : assert(
          recipeId != null || onRatingChanged != null,
          'Fournir recipeId (mode persist) ou onRatingChanged (mode callback)',
        );

  final Member member;
  final RatingValue? currentRating;

  /// Mode direct-persist : ID de la recette à noter.
  final String? recipeId;

  /// Mode callback : appelé quand l'utilisateur tape un chip.
  final ValueChanged<RatingValue?>? onRatingChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      label: 'Notation de ${member.name}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Avatar initiales
            CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 20,
              child: Text(
                str_utils.initials(member.name),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Prénom
            Expanded(
              child: Text(
                member.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
            const SizedBox(width: 8),

            // Chips de notation
            Wrap(
              spacing: 6,
              children: RatingValue.values.map((rating) {
                final isSelected = currentRating == rating;
                return _RatingChip(
                  rating: rating,
                  isSelected: isSelected,
                  onTap: () => _handleTap(ref, rating),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(WidgetRef ref, RatingValue tapped) {
    // Désélectionner si déjà sélectionné
    final newRating = currentRating == tapped ? null : tapped;

    if (onRatingChanged != null) {
      // Mode callback
      onRatingChanged!(newRating);
    } else if (recipeId != null) {
      // Mode direct-persist
      if (newRating != null) {
        unawaited(
          ref.read(householdNotifierProvider.notifier).upsertRating(
                memberId: member.id,
                recipeId: recipeId!,
                rating: newRating,
              ),
        );
      } else {
        // Désélection : supprimer la notation
        unawaited(
          ref.read(householdNotifierProvider.notifier).deleteRating(
                memberId: member.id,
                recipeId: recipeId!,
              ),
        );
      }
    }
  }

}

// ---------------------------------------------------------------------------
// Widget interne : chip de notation
// ---------------------------------------------------------------------------

class _RatingChip extends StatelessWidget {
  const _RatingChip({
    required this.rating,
    required this.isSelected,
    required this.onTap,
  });

  final RatingValue rating;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(rating);

    return Semantics(
      label: '${rating.label}${isSelected ? ', sélectionné' : ''}',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? colors.bg : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? colors.text.withAlpha(100) : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(rating.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                rating.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? colors.text : const Color(0xFF757575),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _ChipColors _colorsFor(RatingValue rating) => switch (rating) {
        RatingValue.liked => const _ChipColors(
            bg: Color(0xFFFFE0CC),
            text: Color(0xFFE8794A),
          ),
        RatingValue.neutral => const _ChipColors(
            bg: Color(0xFFF0F0F0),
            text: Color(0xFF757575),
          ),
        RatingValue.disliked => const _ChipColors(
            bg: Color(0xFFE8EAF6),
            text: Color(0xFF5C6BC0),
          ),
      };
}

class _ChipColors {
  const _ChipColors({required this.bg, required this.text});
  final Color bg;
  final Color text;
}
