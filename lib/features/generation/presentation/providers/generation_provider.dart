import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/core/database/database_provider.dart';
import 'package:appli_recette/features/generation/domain/models/generation_filters.dart';
import 'package:appli_recette/features/generation/domain/models/generation_input.dart';
import 'package:appli_recette/features/generation/domain/models/meal_slot_result.dart';
import 'package:appli_recette/features/generation/domain/services/generation_service.dart';
import 'package:appli_recette/features/generation/presentation/providers/menu_provider.dart';
import 'package:appli_recette/features/household/data/datasources/meal_rating_datasource.dart';
import 'package:appli_recette/features/household/presentation/providers/household_provider.dart';
import 'package:appli_recette/features/planning/data/utils/week_utils.dart';
import 'package:appli_recette/features/planning/presentation/providers/planning_provider.dart';
import 'package:appli_recette/features/recipes/presentation/providers/recipes_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Datasource pour les ratings globaux (ajouté à la datasource existante)
// ─────────────────────────────────────────────────────────────────────────────

final _mealRatingDatasourceProvider = Provider<MealRatingDatasource>((ref) {
  final db = ref.watch(databaseProvider);
  return MealRatingDatasource(db);
});

/// Stream de toutes les notations (tous membres, toutes recettes).
final allRatingsStreamProvider = StreamProvider<List<MealRating>>((ref) {
  return ref.watch(_mealRatingDatasourceProvider).watchAll();
});

// ─────────────────────────────────────────────────────────────────────────────
// filtersProvider (Story 5.3)
// ─────────────────────────────────────────────────────────────────────────────

/// Notifier pour les filtres de génération.
class FiltersNotifier extends Notifier<GenerationFilters?> {
  @override
  GenerationFilters? build() => null; // Aucun filtre par défaut

  void update(GenerationFilters filters) => state = filters;
  void reset() => state = null;
}

final filtersProvider =
    NotifierProvider<FiltersNotifier, GenerationFilters?>(FiltersNotifier.new);

/// True si des filtres actifs sont en place.
final hasActiveFiltersProvider = Provider<bool>((ref) {
  final filters = ref.watch(filtersProvider);
  return filters != null && filters.hasActiveFilters;
});

// ─────────────────────────────────────────────────────────────────────────────
// État de la génération
// ─────────────────────────────────────────────────────────────────────────────

/// État complet du menu généré pour la semaine courante.
class GeneratedMenuState {
  const GeneratedMenuState({
    required this.slots,
    required this.weekKey,
    this.lockedSlotIndices = const {},
    this.isValidated = false,
  });

  /// 14 créneaux : index 0 = lundi-midi, 1 = lundi-soir, …, 13 = dimanche-soir.
  /// null = créneau non rempli.
  final List<MealSlotResult?> slots;

  /// Clé ISO 8601 de la semaine planifiée (ex: "2026-W09").
  final String weekKey;

  /// Indices des créneaux verrouillés (ignorés lors de la regénération).
  final Set<int> lockedSlotIndices;

  /// True si le menu a été validé et sauvegardé dans drift.
  final bool isValidated;

  /// Nombre de créneaux non remplis.
  int get emptySlotCount => slots.where((s) => s == null).length;

  /// True si au moins un créneau rempli n'est pas verrouillé.
  bool get hasUnlockedFilledSlots => slots.asMap().entries.any(
        (e) => e.value != null && !lockedSlotIndices.contains(e.key),
      );

  GeneratedMenuState copyWith({
    List<MealSlotResult?>? slots,
    String? weekKey,
    Set<int>? lockedSlotIndices,
    bool? isValidated,
  }) {
    return GeneratedMenuState(
      slots: slots ?? this.slots,
      weekKey: weekKey ?? this.weekKey,
      lockedSlotIndices: lockedSlotIndices ?? this.lockedSlotIndices,
      isValidated: isValidated ?? this.isValidated,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// generateMenuProvider — AsyncNotifierProvider principal (Stories 5.1-5.4)
// ─────────────────────────────────────────────────────────────────────────────

class GenerateMenuNotifier
    extends AsyncNotifier<GeneratedMenuState?> {
  @override
  Future<GeneratedMenuState?> build() async => null; // Pas de menu au démarrage

  /// Lance la génération pour la semaine courante.
  Future<void> generate(GenerationFilters? filters) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final weekKey = ref.read(selectedWeekKeyProvider);

      // Collecter les données depuis les providers existants
      final recipes = await ref.read(recipesStreamProvider.future);
      final members = await ref.read(membersStreamProvider.future);
      final presences =
          await ref.read(mergedPresencesStreamProvider(weekKey).future);
      final ratings = await ref.read(allRatingsStreamProvider.future);
      final previousSlots = await ref.read(previousMenuSlotsProvider.future);

      final input = GenerationInput(
        weekKey: weekKey,
        recipes: recipes,
        members: members,
        presences: presences,
        ratings: ratings,
        previousMenuSlots: previousSlots,
        filters: filters,
      );

      final currentState = state.valueOrNull;
      final lockedIndices = currentState?.lockedSlotIndices ?? {};

      final service = GenerationService();
      final slots = service.generateMenu(
        input,
        lockedSlotIndices: lockedIndices.isNotEmpty ? lockedIndices : null,
      );

      // Si regénération partielle, conserver les slots verrouillés
      final mergedSlots = List<MealSlotResult?>.from(slots);
      if (currentState != null && lockedIndices.isNotEmpty) {
        for (final lockedIdx in lockedIndices) {
          mergedSlots[lockedIdx] = currentState.slots[lockedIdx];
        }
      }

      return GeneratedMenuState(
        slots: mergedSlots,
        weekKey: weekKey,
        lockedSlotIndices: lockedIndices,
      );
    });
  }

  /// Bascule le verrouillage d'un créneau (toggle).
  void toggleLock(int slotIndex) {
    final current = state.valueOrNull;
    if (current == null) return;

    final newLocked = Set<int>.from(current.lockedSlotIndices);
    if (newLocked.contains(slotIndex)) {
      newLocked.remove(slotIndex);
    } else {
      newLocked.add(slotIndex);
    }
    state = AsyncValue.data(current.copyWith(lockedSlotIndices: newLocked));
  }

  /// Remplace le créneau [slotIndex] par la recette [recipeId].
  void replaceSlot(int slotIndex, String recipeId) {
    final current = state.valueOrNull;
    if (current == null) return;

    final dayIndex = slotIndex ~/ 2;
    final mealType = slotIndex.isEven ? 'lunch' : 'dinner';

    final newSlots = List<MealSlotResult?>.from(current.slots);
    newSlots[slotIndex] = MealSlotResult(
      recipeId: recipeId,
      dayIndex: dayIndex,
      mealType: mealType,
    );
    state = AsyncValue.data(current.copyWith(slots: newSlots));
  }

  /// Vide le créneau [slotIndex] (null) et le déverrouille.
  void clearSlot(int slotIndex) {
    final current = state.valueOrNull;
    if (current == null) return;

    final newSlots = List<MealSlotResult?>.from(current.slots);
    newSlots[slotIndex] = null;

    final newLocked = Set<int>.from(current.lockedSlotIndices)
      ..remove(slotIndex);
    state = AsyncValue.data(
      current.copyWith(slots: newSlots, lockedSlotIndices: newLocked),
    );
  }

  /// Marque le créneau [slotIndex] comme événement spécial (sans recette).
  void setSpecialEvent(int slotIndex) {
    final current = state.valueOrNull;
    if (current == null) return;

    final dayIndex = slotIndex ~/ 2;
    final mealType = slotIndex.isEven ? 'lunch' : 'dinner';

    final newSlots = List<MealSlotResult?>.from(current.slots);
    newSlots[slotIndex] = MealSlotResult(
      recipeId: 'special_event',
      dayIndex: dayIndex,
      mealType: mealType,
      isSpecialEvent: true,
    );
    state = AsyncValue.data(current.copyWith(slots: newSlots));
  }

  /// Marque le menu comme validé (appelé après save dans menuHistoryNotifier).
  void markValidated() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(isValidated: true));
  }

  /// Réinitialise la génération.
  void reset() => state = const AsyncValue.data(null);
}

final generateMenuProvider =
    AsyncNotifierProvider<GenerateMenuNotifier, GeneratedMenuState?>(
  GenerateMenuNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// Providers dérivés (Story 5.4)
// ─────────────────────────────────────────────────────────────────────────────

/// True si le menu affiché a au moins un créneau rempli non verrouillé.
final hasUnlockedSlotsProvider = Provider<bool>((ref) {
  final state = ref.watch(generateMenuProvider).valueOrNull;
  return state?.hasUnlockedFilledSlots ?? false;
});

/// Nombre de créneaux vides dans le menu généré.
final emptySlotCountProvider = Provider<int>((ref) {
  final state = ref.watch(generateMenuProvider).valueOrNull;
  return state?.emptySlotCount ?? 0;
});
