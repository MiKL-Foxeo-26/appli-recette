import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Case individuelle de la grille semaine.
///
/// Peut être vide (état null) ou remplie avec une recette.
/// En mode post-génération, affiche les icônes verrou/refresh/supprimer.
class MealSlotCard extends StatelessWidget {
  const MealSlotCard({
    super.key,
    this.recipe,
    this.isPostGeneration = false,
    this.isLocked = false,
    this.isHighlighted = false,
    this.isSpecialEvent = false,
    this.onTap,
    this.onToggleLock,
    this.onRefresh,
    this.onDelete,
  });

  /// La recette assignée à ce créneau. Null = créneau vide.
  final Recipe? recipe;

  /// True si le menu vient d'être généré (icônes action visibles).
  final bool isPostGeneration;

  /// True si ce créneau est verrouillé.
  final bool isLocked;

  /// True si ce créneau vide doit être mis en évidence (Story 5.6).
  final bool isHighlighted;

  /// True si ce créneau est un événement spécial (sans recette).
  final bool isSpecialEvent;

  final VoidCallback? onTap;
  final VoidCallback? onToggleLock;
  final VoidCallback? onRefresh;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    if (isSpecialEvent) return _buildSpecialEvent(context);
    if (recipe == null) return _buildEmptySlot(context);
    return _buildFilledSlot(context, recipe!);
  }

  // ─── État vide ────────────────────────────────────────────────────────────

  Widget _buildEmptySlot(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: isHighlighted
              ? Border.all(color: AppColors.primary, width: 2)
              : Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Icon(
            Icons.add,
            size: 20,
            color: isHighlighted ? AppColors.primary : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }

  // ─── Événement spécial ───────────────────────────────────────────────────

  Widget _buildSpecialEvent(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onToggleLock,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isLocked ? AppColors.primary : AppColors.secondary,
            width: isLocked ? 2 : 1,
          ),
        ),
        child: const Center(
          child: Text(
            '🎉\nÉvénement',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10),
          ),
        ),
      ),
    );
  }

  // ─── Créneau rempli ──────────────────────────────────────────────────────

  Widget _buildFilledSlot(BuildContext context, Recipe recipe) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onToggleLock,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        decoration: BoxDecoration(
          color: isLocked
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isLocked ? AppColors.primary : Colors.transparent,
            width: isLocked ? 2 : 0,
          ),
        ),
        child: Stack(
          children: [
            // Contenu principal
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nom de la recette
                  Text(
                    recipe.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                  ),
                  const SizedBox(height: 2),
                  // Badges contextuels
                  _buildBadges(recipe),
                ],
              ),
            ),

            // Icônes post-génération
            if (isPostGeneration) _buildActionOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildBadges(Recipe recipe) {
    final badges = <Widget>[];
    if (recipe.isFavorite) {
      badges.add(_badge('⭐', const Color(0xFFFFE0CC)));
    }
    if (recipe.isVegetarian) {
      badges.add(_badge('🌿', const Color(0xFFE8F5E9)));
    }
    final season = recipe.season;
    if (season != null && season != 'all') {
      final emoji = switch (season) {
        'spring' => '🌸',
        'summer' => '☀️',
        'autumn' => '🍂',
        'winter' => '❄️',
        _ => null,
      };
      if (emoji != null) badges.add(_badge(emoji, const Color(0xFFFFF8E1)));
    }
    if (badges.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 2, children: badges);
  }

  Widget _badge(String emoji, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 8)),
    );
  }

  Widget _buildActionOverlay() {
    return Positioned(
      bottom: 2,
      right: 2,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _actionIcon(
            isLocked ? Icons.lock : Icons.lock_open,
            onToggleLock,
          ),
          _actionIcon(Icons.refresh, onRefresh),
          _actionIcon(Icons.delete_outline, onDelete),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, VoidCallback? callback) {
    return GestureDetector(
      onTap: callback,
      child: Container(
        width: 20,
        height: 20,
        margin: const EdgeInsets.only(left: 1),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Icon(icon, size: 12, color: Colors.white),
      ),
    );
  }
}
