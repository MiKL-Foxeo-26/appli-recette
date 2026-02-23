import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/core/database/database_provider.dart';
import 'package:appli_recette/features/generation/data/datasources/menu_local_datasource.dart';
import 'package:appli_recette/features/generation/data/repositories/menu_repository_impl.dart';
import 'package:appli_recette/features/generation/domain/models/meal_slot_result.dart';
import 'package:appli_recette/features/generation/domain/repositories/menu_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Infrastructure
// ─────────────────────────────────────────────────────────────────────────────

final menuLocalDatasourceProvider = Provider<MenuLocalDatasource>((ref) {
  final db = ref.watch(databaseProvider);
  return MenuLocalDatasource(db);
});

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  final datasource = ref.watch(menuLocalDatasourceProvider);
  return MenuRepositoryImpl(datasource);
});

// ─────────────────────────────────────────────────────────────────────────────
// Stream providers (lecture)
// ─────────────────────────────────────────────────────────────────────────────

/// Stream de tous les menus validés (historique).
final validatedMenusStreamProvider = StreamProvider<List<WeeklyMenu>>((ref) {
  return ref.watch(menuRepositoryProvider).watchValidatedMenus();
});

/// Stream du menu pour la semaine sélectionnée.
final menuForWeekProvider =
    StreamProvider.family<WeeklyMenu?, String>((ref, weekKey) {
  return ref.watch(menuRepositoryProvider).watchMenuForWeek(weekKey);
});

// ─────────────────────────────────────────────────────────────────────────────
// Menu History Notifier (Story 5.5)
// ─────────────────────────────────────────────────────────────────────────────

/// État de l'historique des menus validés.
class MenuHistoryNotifier extends AsyncNotifier<List<WeeklyMenu>> {
  @override
  Future<List<WeeklyMenu>> build() async {
    // Écouter le stream et attendre sa première émission correctement.
    // ref.watch() permet la reconstruction quand le stream émet une nouvelle valeur.
    return await ref.watch(validatedMenusStreamProvider.future);
  }

  /// Valide et sauvegarde le menu courant dans drift.
  ///
  /// Les créneaux null ne créent pas de ligne en base.
  /// Si un menu existe déjà pour [weekKey], il est remplacé (upsert).
  Future<void> save({
    required String weekKey,
    required List<MealSlotResult?> slots,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(menuRepositoryProvider).saveValidatedMenu(
            weekKey: weekKey,
            slots: slots,
          );
      // Rafraîchir depuis la source
      ref.invalidate(validatedMenusStreamProvider);
      final menus = await ref
          .read(menuRepositoryProvider)
          .watchValidatedMenus()
          .first;
      return menus;
    });
  }
}

final menuHistoryNotifierProvider =
    AsyncNotifierProvider<MenuHistoryNotifier, List<WeeklyMenu>>(
  MenuHistoryNotifier.new,
);

/// Provider pour les slots des menus précédents (anti-répétition).
final previousMenuSlotsProvider = FutureProvider<List<MenuSlot>>((ref) {
  return ref.watch(menuRepositoryProvider).getAllSlotsFromValidatedMenus();
});
