import 'package:flutter/material.dart';

/// Bottom sheet affiché lors du tap sur un créneau rempli.
///
/// Propose 4 options : Voir, Remplacer, Événement spécial, Supprimer.
class MealSlotBottomSheet extends StatelessWidget {
  const MealSlotBottomSheet({
    super.key,
    required this.recipeName,
    this.onViewRecipe,
    this.onReplace,
    this.onSpecialEvent,
    this.onDelete,
  });

  /// Nom de la recette du créneau (affiché en titre).
  final String recipeName;

  final VoidCallback? onViewRecipe;
  final VoidCallback? onReplace;
  final VoidCallback? onSpecialEvent;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── DragHandle ──
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // ── Titre ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              recipeName,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(height: 1),
          // ── Options ──
          ListTile(
            leading: const Icon(Icons.visibility_outlined),
            title: const Text('Voir la recette'),
            onTap: () {
              Navigator.of(context).pop();
              onViewRecipe?.call();
            },
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Remplacer'),
            onTap: () {
              Navigator.of(context).pop();
              onReplace?.call();
            },
          ),
          ListTile(
            leading: const Icon(Icons.event_outlined),
            title: const Text('Passer en événement spécial'),
            onTap: () {
              Navigator.of(context).pop();
              onSpecialEvent?.call();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Supprimer', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.of(context).pop();
              onDelete?.call();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
