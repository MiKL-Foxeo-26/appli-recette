import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/features/generation/data/datasources/menu_local_datasource.dart';
import 'package:appli_recette/features/generation/domain/models/meal_slot_result.dart';
import 'package:appli_recette/features/generation/domain/repositories/menu_repository.dart';

class MenuRepositoryImpl implements MenuRepository {
  MenuRepositoryImpl(this._datasource);

  final MenuLocalDatasource _datasource;

  @override
  Stream<List<WeeklyMenusData>> watchValidatedMenus() =>
      _datasource.watchValidatedMenus();

  @override
  Stream<WeeklyMenusData?> watchMenuForWeek(String weekKey) =>
      _datasource.watchMenuForWeek(weekKey);

  @override
  Future<List<MenuSlot>> getSlotsForMenu(String weeklyMenuId) =>
      _datasource.getSlotsForMenu(weeklyMenuId);

  @override
  Future<List<MenuSlot>> getAllSlotsFromValidatedMenus() =>
      _datasource.getAllSlotsFromValidatedMenus();

  @override
  Future<String> saveValidatedMenu({
    required String weekKey,
    required List<MealSlotResult?> slots,
  }) {
    // Convertir les MealSlotResult en MenuSlotData pour le datasource
    final slotDataList = <MenuSlotData>[];
    for (final slot in slots) {
      if (slot == null) continue; // créneaux vides → pas de ligne en DB
      if (slot.isSpecialEvent) continue; // événements spéciaux sans recette

      slotDataList.add(
        MenuSlotData(
          dayOfWeek: slot.dayIndex + 1, // dayIndex 0=lundi → dayOfWeek 1
          mealSlot: slot.mealType,
          recipeId: slot.recipeId,
        ),
      );
    }

    return _datasource.saveValidatedMenu(weekKey: weekKey, slots: slotDataList);
  }
}
