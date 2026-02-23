import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/core/router/app_router.dart';
import 'package:appli_recette/core/theme/app_colors.dart';
import 'package:appli_recette/features/generation/domain/models/generation_filters.dart';
import 'package:appli_recette/features/generation/presentation/providers/generation_provider.dart';
import 'package:appli_recette/features/generation/presentation/providers/menu_provider.dart';
import 'package:appli_recette/features/generation/presentation/widgets/generation_filters_sheet.dart';
import 'package:appli_recette/features/generation/presentation/widgets/incomplete_generation_card.dart';
import 'package:appli_recette/features/generation/presentation/widgets/meal_slot_bottom_sheet.dart';
import 'package:appli_recette/features/generation/presentation/widgets/recipe_picker_sheet.dart';
import 'package:appli_recette/features/generation/presentation/widgets/week_grid.dart';
import 'package:appli_recette/features/planning/presentation/providers/planning_provider.dart';
import 'package:appli_recette/features/recipes/presentation/providers/recipes_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Écran d'accueil — affiche la grille semaine et le menu généré.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _cardDismissed = false;
  bool _highlightEmptySlots = false;

  @override
  Widget build(BuildContext context) {
    // Réinitialiser l'état local quand la semaine sélectionnée change
    ref.listen<String>(selectedWeekKeyProvider, (prev, next) {
      if (prev != next) {
        setState(() {
          _cardDismissed = false;
          _highlightEmptySlots = false;
        });
      }
    });

    final menuAsync = ref.watch(generateMenuProvider);
    final hasActiveFilters = ref.watch(hasActiveFiltersProvider);
    final hasUnlocked = ref.watch(hasUnlockedSlotsProvider);
    final recipesAsync = ref.watch(recipesStreamProvider);
    final weekKey = ref.watch(selectedWeekKeyProvider);

    final recipesMap = {
      for (final r in recipesAsync.value ?? []) r.id: r,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('Semaine $weekKey'),
        actions: [
          // ── Icône filtres ──
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.tune),
                tooltip: 'Filtres',
                onPressed: _openFiltersSheet,
              ),
              if (hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),

          // ── Bouton Générer ──
          menuAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (menuState) {
              if (menuState != null && hasUnlocked) {
                return TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Regénérer'),
                  onPressed: _generate,
                );
              }
              return TextButton(
                onPressed: _generate,
                child: const Text('Générer'),
              );
            },
          ),
        ],
      ),
      body: menuAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 8),
              Text(
                'Impossible de générer le menu.\nRéessaie dans un instant.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _generate,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (menuState) {
          if (menuState == null) {
            return _buildEmptyState(context);
          }
          return _buildMenuView(context, menuState, recipesMap, weekKey);
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // État vide
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Tape Générer pour planifier ta semaine',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Vue menu généré
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildMenuView(
    BuildContext context,
    GeneratedMenuState menuState,
    Map<String, Recipe> recipesMap,
    String weekKey,
  ) {
    final emptyCount = menuState.emptySlotCount;
    final showCard = !_cardDismissed && emptyCount > 0;

    return Column(
      children: [
        // ── Card génération incomplète (Story 5.6) ──
        if (showCard)
          IncompleteGenerationCard(
            emptySlotCount: emptyCount,
            onExpandFilters: _onExpandFilters,
            onCompleteManually: () {
              setState(() {
                _cardDismissed = true;
                _highlightEmptySlots = true;
              });
            },
            onLeaveEmpty: () => setState(() => _cardDismissed = true),
          ),

        // ── Grille semaine ──
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: WeekGrid(
              slots: menuState.slots,
              recipesMap: recipesMap,
              isPostGeneration: !menuState.isValidated,
              isReadOnly: menuState.isValidated,
              lockedSlotIndices: menuState.lockedSlotIndices,
              highlightEmptySlots: _highlightEmptySlots,
              onSlotTap: (slotIndex) =>
                  _onSlotTap(slotIndex, menuState, recipesMap),
              onToggleLock: (slotIndex) => ref
                  .read(generateMenuProvider.notifier)
                  .toggleLock(slotIndex),
              onRefreshSlot: (slotIndex) =>
                  _onRefreshSlot(slotIndex, recipesMap.values.toList()),
              onDeleteSlot: (slotIndex) => ref
                  .read(generateMenuProvider.notifier)
                  .clearSlot(slotIndex),
            ),
          ),
        ),

        // ── Bouton Valider ──
        if (!menuState.isValidated)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: () => _validateMenu(menuState, weekKey),
                child: const Text('Valider le menu'),
              ),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _generate() async {
    setState(() {
      _cardDismissed = false;
      _highlightEmptySlots = false;
    });
    final filters = ref.read(filtersProvider);
    await ref.read(generateMenuProvider.notifier).generate(filters);
  }

  void _openFiltersSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => GenerationFiltersSheet(
        initialFilters: ref.read(filtersProvider),
        onApply: (newFilters) {
          ref.read(filtersProvider.notifier).update(newFilters);
        },
      ),
    );
  }

  void _onExpandFilters() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => GenerationFiltersSheet(
        initialFilters: ref.read(filtersProvider),
        onApply: (newFilters) {
          // Mettre à jour le provider puis générer avec les nouveaux filtres
          // directement (sans re-lire le provider) pour éviter toute ambiguïté
          ref.read(filtersProvider.notifier).update(newFilters);
          setState(() {
            _cardDismissed = false;
            _highlightEmptySlots = false;
          });
          ref.read(generateMenuProvider.notifier).generate(newFilters);
        },
      ),
    );
  }

  void _onSlotTap(
    int slotIndex,
    GeneratedMenuState menuState,
    Map<String, Recipe> recipesMap,
  ) {
    final slot = menuState.slots[slotIndex];
    if (slot == null) return; // créneau vide → ouvrir picker (futur)

    final recipe = recipesMap[slot.recipeId];
    if (recipe == null && !slot.isSpecialEvent) return;

    showModalBottomSheet<void>(
      context: context,
      builder: (_) => MealSlotBottomSheet(
        recipeName: slot.isSpecialEvent ? 'Événement spécial' : recipe!.name,
        onViewRecipe: slot.isSpecialEvent
            ? null
            : () => context.push('/recipes/${slot.recipeId}'),
        onReplace: () => _onRefreshSlot(
          slotIndex,
          recipesMap.values.toList(),
        ),
        onSpecialEvent: () => ref
            .read(generateMenuProvider.notifier)
            .setSpecialEvent(slotIndex),
        onDelete: () =>
            ref.read(generateMenuProvider.notifier).clearSlot(slotIndex),
      ),
    );
  }

  void _onRefreshSlot(int slotIndex, List<dynamic> recipes) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => RecipePickerSheet(
        recipes: recipes.cast(),
        onPick: (recipeId) => ref
            .read(generateMenuProvider.notifier)
            .replaceSlot(slotIndex, recipeId),
      ),
    );
  }

  Future<void> _validateMenu(
    GeneratedMenuState menuState,
    String weekKey,
  ) async {
    await ref.read(menuHistoryNotifierProvider.notifier).save(
          weekKey: weekKey,
          slots: menuState.slots,
        );
    ref.read(generateMenuProvider.notifier).markValidated();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Menu sauvegardé ✓'),
        backgroundColor: Color(0xFF6BAE75),
        duration: Duration(seconds: 3),
      ),
    );
  }
}
