import 'package:appli_recette/core/database/app_database.dart';

/// Interface du Repository Planning.
/// La couche présentation dépend uniquement de cette interface.
abstract class PlanningRepository {
  /// Stream des présences type (weekKey == null).
  Stream<List<PresenceSchedule>> watchDefaultPresences();

  /// Bascule la présence d'un membre pour un créneau du planning type.
  Future<void> togglePresence(
    String memberId,
    int dayOfWeek,
    String mealSlot,
  );

  /// Initialise le planning type pour un nouveau membre (14 entrées, isPresent = true).
  Future<void> initializeDefaultForMember(String memberId);

  /// Retourne les IDs des membres ayant déjà un planning type.
  Future<List<String>> getMembersWithDefaultSchedule();

  // ---------------------------------------------------------------------------
  // Weekly overrides — Story 4.2
  // ---------------------------------------------------------------------------

  /// Stream des overrides pour une semaine donnée.
  Stream<List<PresenceSchedule>> watchWeeklyPresences(String weekKey);

  /// Stream des présences fusionnées : override prioritaire, fallback planning type.
  Stream<List<PresenceSchedule>> watchMergedPresences(String weekKey);

  /// Bascule un override de présence pour une semaine spécifique.
  Future<void> toggleWeeklyPresence(
    String weekKey,
    String memberId,
    int dayOfWeek,
    String mealSlot,
  );

  /// Supprime tous les overrides d'une semaine (retour au planning type).
  Future<void> resetWeekToDefault(String weekKey);

  /// Retourne true si des overrides existent pour la semaine.
  Future<bool> hasWeeklyOverrides(String weekKey);
}
