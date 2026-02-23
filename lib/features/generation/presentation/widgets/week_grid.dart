import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/features/generation/domain/models/meal_slot_result.dart';
import 'package:appli_recette/features/generation/presentation/widgets/meal_slot_card.dart';
import 'package:flutter/material.dart';

/// Grille semaine 7 colonnes (lundi→dimanche) × 2 lignes (midi/soir).
///
/// Affiche les 14 créneaux du menu généré.
class WeekGrid extends StatelessWidget {
  const WeekGrid({
    super.key,
    required this.slots,
    required this.recipesMap,
    this.isPostGeneration = false,
    this.isReadOnly = false,
    this.lockedSlotIndices = const {},
    this.highlightEmptySlots = false,
    this.onSlotTap,
    this.onToggleLock,
    this.onRefreshSlot,
    this.onDeleteSlot,
  });

  /// Les 14 créneaux (index 0=lundi-midi, 1=lundi-soir, …, 13=dimanche-soir).
  final List<MealSlotResult?> slots;

  /// Map recipeId → Recipe pour résoudre les recettes depuis les IDs.
  final Map<String, Recipe> recipesMap;

  /// True si le menu vient d'être généré (affiche icônes action).
  final bool isPostGeneration;

  /// True si le menu est en mode lecture (après validation).
  final bool isReadOnly;

  /// Indices des créneaux verrouillés.
  final Set<int> lockedSlotIndices;

  /// True si les créneaux vides doivent être mis en évidence (Story 5.6).
  final bool highlightEmptySlots;

  final void Function(int slotIndex)? onSlotTap;
  final void Function(int slotIndex)? onToggleLock;
  final void Function(int slotIndex)? onRefreshSlot;
  final void Function(int slotIndex)? onDeleteSlot;

  static const _days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
  static const _meals = ['Midi', 'Soir'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Headers des jours ──
            Row(
              children: [
                const SizedBox(width: 40), // espace label repas
                ..._days.map(
                  (day) => SizedBox(
                    width: 52,
                    child: Center(
                      child: Text(
                        day,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // ── Lignes (midi / soir) ──
            ..._meals.asMap().entries.map((mealEntry) {
              final mealOffset = mealEntry.key; // 0=midi, 1=soir
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    // Label repas
                    SizedBox(
                      width: 40,
                      child: Text(
                        _meals[mealOffset],
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ),
                    // Cellules des 7 jours
                    ...List.generate(7, (dayIndex) {
                      final slotIndex = dayIndex * 2 + mealOffset;
                      final slot = slots.length > slotIndex
                          ? slots[slotIndex]
                          : null;
                      final recipe = slot != null && !slot.isSpecialEvent
                          ? recipesMap[slot.recipeId]
                          : null;
                      final isLocked = lockedSlotIndices.contains(slotIndex);
                      final isSpecialEvent = slot?.isSpecialEvent ?? false;

                      return Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: SizedBox(
                          width: 52,
                          child: MealSlotCard(
                            recipe: recipe,
                            isPostGeneration: isPostGeneration && !isReadOnly,
                            isLocked: isLocked,
                            isHighlighted:
                                highlightEmptySlots && slot == null,
                            isSpecialEvent: isSpecialEvent,
                            onTap: () => onSlotTap?.call(slotIndex),
                            onToggleLock: isReadOnly
                                ? null
                                : () => onToggleLock?.call(slotIndex),
                            onRefresh: isReadOnly
                                ? null
                                : () => onRefreshSlot?.call(slotIndex),
                            onDelete: isReadOnly
                                ? null
                                : () => onDeleteSlot?.call(slotIndex),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
