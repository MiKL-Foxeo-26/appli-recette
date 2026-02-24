import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/features/generation/domain/models/meal_slot_result.dart';

/// Interface du repository pour la persistance des menus hebdomadaires.
abstract class MenuRepository {
  /// Stream de tous les menus validés, triés du plus récent au plus ancien.
  Stream<List<WeeklyMenusData>> watchValidatedMenus();

  /// Stream du menu pour une semaine donnée (null si inexistant).
  Stream<WeeklyMenusData?> watchMenuForWeek(String weekKey);

  /// Slots d'un menu spécifique.
  Future<List<MenuSlot>> getSlotsForMenu(String weeklyMenuId);

  /// Tous les slots des menus validés (pour anti-répétition dans GenerationService).
  Future<List<MenuSlot>> getAllSlotsFromValidatedMenus();

  /// Valide et sauvegarde un menu généré.
  ///
  /// Les [slots] null (créneaux vides) ne créent pas de MenuSlot en base.
  /// Si un menu validé existe déjà pour [weekKey], il est remplacé (upsert).
  Future<String> saveValidatedMenu({
    required String weekKey,
    required List<MealSlotResult?> slots,
  });
}
