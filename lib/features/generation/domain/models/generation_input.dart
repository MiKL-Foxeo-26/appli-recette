import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/features/generation/domain/models/generation_filters.dart';

/// Données d'entrée complètes pour [GenerationService].
///
/// Le service est une classe Dart pure — toutes les données lui sont
/// passées en paramètre ; il n'accède jamais directement aux repositories
/// ou à drift.
class GenerationInput {
  const GenerationInput({
    required this.weekKey,
    required this.recipes,
    required this.members,
    required this.presences,
    required this.ratings,
    required this.previousMenuSlots,
    this.filters,
  });

  /// Clé ISO 8601 de la semaine à planifier (ex: "2026-W09").
  final String weekKey;

  /// Toutes les recettes disponibles dans la collection.
  final List<Recipe> recipes;

  /// Tous les membres du foyer.
  final List<Member> members;

  /// Présences fusionnées (planning type + overrides) pour la [weekKey].
  /// Chaque [PresenceSchedule] indique qui est présent pour quel créneau.
  final List<PresenceSchedule> presences;

  /// Toutes les notations de repas de tous les membres.
  final List<MealRating> ratings;

  /// Slots des menus validés précédents — utilisés pour l'anti-répétition.
  final List<MenuSlot> previousMenuSlots;

  /// Filtres optionnels (temps max, végétarien, saison).
  final GenerationFilters? filters;
}
